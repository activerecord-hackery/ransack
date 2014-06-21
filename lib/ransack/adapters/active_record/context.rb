require 'ransack/context'
require 'ransack/adapters/active_record/compat'
require 'polyamorous'

module Ransack
  module Adapters
    module ActiveRecord
      class Context < ::Ransack::Context

        # Because the AR::Associations namespace is insane
        JoinDependency = ::ActiveRecord::Associations::JoinDependency
        JoinPart = JoinDependency::JoinPart

        def initialize(object, options = {})
          super
          @arel_visitor = @engine.connection.visitor
        end

        def relation_for(object)
          object.all
        end

        def type_for(attr)
          return nil unless attr && attr.valid?
          name    = attr.arel_attribute.name.to_s
          table   = attr.arel_attribute.relation.table_name

          schema_cache = @engine.connection.schema_cache
          raise "No table named #{table} exists" unless schema_cache.table_exists?(table)
          schema_cache.columns_hash(table)[name].type
        end

        def evaluate(search, opts = {})
          viz = Visitor.new
          relation = @object.where(viz.accept(search.base))
          if search.sorts.any?
            relation = relation.except(:order)
            .reorder(viz.accept(search.sorts))
          end
          opts[:distinct] ? relation.distinct : relation
        end

        def attribute_method?(str, klass = @klass)
          exists = false
          if ransackable_attribute?(str, klass)
            exists = true
          elsif (segments = str.split(/_/)).size > 1
            remainder = []
            found_assoc = nil
            while !found_assoc && remainder.unshift(
              segments.pop) && segments.size > 0 do
              assoc, poly_class = unpolymorphize_association(
                segments.join('_')
                )
              if found_assoc = get_association(assoc, klass)
                exists = attribute_method?(remainder.join('_'),
                  poly_class || found_assoc.klass
                )
              end
            end
          end
          exists
        end

        def table_for(parent)
          parent.table
        end

        def klassify(obj)
          if Class === obj && ::ActiveRecord::Base > obj
            obj
          elsif obj.respond_to? :klass
            obj.klass
          elsif obj.respond_to? :base_klass
            obj.base_klass
          else
            raise ArgumentError, "Don't know how to klassify #{obj}"
          end
        end

      private

        def get_parent_and_attribute_name(str, parent = @base)
          attr_name = nil

          if ransackable_attribute?(str, klassify(parent))
            attr_name = str
          elsif (segments = str.split(/_/)).size > 1
            remainder = []
            found_assoc = nil
            while remainder.unshift(
              segments.pop) && segments.size > 0 && !found_assoc do
              assoc, klass = unpolymorphize_association(segments.join('_'))
              if found_assoc = get_association(assoc, parent)
                join = build_or_find_association(found_assoc.name, parent, klass)
                parent, attr_name = get_parent_and_attribute_name(
                  remainder.join('_'), join
                  )
              end
            end
          end

          [parent, attr_name]
        end

        def get_association(str, parent = @base)
          klass = klassify parent
          ransackable_association?(str, klass) &&
            klass.reflect_on_all_associations.detect { |a| a.name.to_s == str }
        end

        def join_dependency(relation)
          if relation.respond_to?(:join_dependency) # Squeel will enable this
            relation.join_dependency
          else
            build_join_dependency(relation)
          end
        end

        # Checkout active_record/relation/query_methods.rb +build_joins+ for
        # reference. Lots of duplicated code maybe we can avoid it
        def build_join_dependency(relation)
          buckets = relation.joins_values.group_by do |join|
            case join
            when String
              'string_join'
            when Hash, Symbol, Array
              'association_join'
            when JoinDependency, JoinDependency::JoinAssociation
              'stashed_join'
            when Arel::Nodes::Join
              'join_node'
            else
              raise 'unknown class: %s' % join.class.name
            end
          end

          association_joins         = buckets['association_join'] || []

          stashed_association_joins = buckets['stashed_join'] || []

          join_nodes                = buckets['join_node'] || []

          string_joins              = (buckets['string_join'] || [])
                                      .map { |x| x.strip }
                                      .uniq

          join_list = relation.send :custom_join_ast,
            relation.table.from(relation.table), string_joins

          join_dependency = JoinDependency.new(
            relation.klass, association_joins, join_list
          )

          join_nodes.each do |join|
            join_dependency.alias_tracker.aliases[join.left.name.downcase] = 1
          end

          if ::ActiveRecord::VERSION::STRING >= '4.1'
            join_dependency
          else
            join_dependency.graft(*stashed_association_joins)
          end
        end

        if ::ActiveRecord::VERSION::STRING >= '4.1'

          def build_or_find_association(name, parent = @base, klass = nil)
            found_association = @join_dependency.join_root.children
            .detect do |assoc|
              assoc.reflection.name == name &&
              (@associations_pot.nil? || @associations_pot[assoc] == parent) &&
              (!klass || assoc.reflection.klass == klass)
            end

            unless found_association
              jd = JoinDependency.new(
                parent.base_klass,
                Polyamorous::Join.new(name, @join_type, klass),
                []
              )
              found_association = jd.join_root.children.last
              associations found_association, parent

              # TODO maybe we dont need to push associations here, we could loop
              # through the @associations_pot instead
              @join_dependency.join_root.children.push found_association

              # Builds the arel nodes properly for this association
              @join_dependency.send(
                :construct_tables!, jd.join_root, found_association
                )

              # Leverage the stashed association functionality in AR
              @object = @object.joins(jd)
            end
            found_association
          end

          def associations(assoc, parent)
            @associations_pot ||= {}
            @associations_pot[assoc] = parent
          end

        else

          def build_or_find_association(name, parent = @base, klass = nil)
            found_association = @join_dependency.join_associations
            .detect do |assoc|
              assoc.reflection.name == name &&
              assoc.parent == parent &&
              (!klass || assoc.reflection.klass == klass)
            end
            unless found_association
              @join_dependency.send(
                :build,
                Polyamorous::Join.new(name, @join_type, klass),
                parent
               )
              found_association = @join_dependency.join_associations.last
              # Leverage the stashed association functionality in AR
              @object = @object.joins(found_association)
            end
            found_association
          end

        end

      end
    end
  end
end
