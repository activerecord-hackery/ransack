require 'ransack/context'
require 'polyamorous'

module Ransack
  module Adapters
    module Mongoid
      class Context < ::Ransack::Context

        def initialize(object, options = {})
          super
          # @arel_visitor = @engine.connection.visitor
        end

        def relation_for(object)
          object.all
        end

        def type_for(attr)
          return nil unless attr && attr.valid?
          name    = attr.arel_attribute.name.to_s.split('.').last
          # table   = attr.arel_attribute.relation.table_name

          # schema_cache = @engine.connection.schema_cache
          # raise "No table named #{table} exists" unless schema_cache.table_exists?(table)
          # schema_cache.columns_hash(table)[name].type

          # when :date
          # when :datetime, :timestamp, :time
          # when :boolean
          # when :integer
          # when :float
          # when :decimal
          # else # :string

          name = '_id' if name == 'id'

          t = object.klass.fields[name].try(:type) || @bind_pairs[attr.name].first.fields[name].type

          t.to_s.demodulize.underscore.to_sym
        end

        def evaluate(search, opts = {})
          viz = Visitor.new
          relation = @object.where(viz.accept(search.base))
          if search.sorts.any?
            ary_sorting = viz.accept(search.sorts)
            sorting = {}
            ary_sorting.each do |s|
              sorting.merge! Hash[s.map { |k, d| [k.to_s == 'id' ? '_id' : k, d] }]
            end
            relation = relation.order_by(sorting)
            # relation = relation.except(:order)
            # .reorder(viz.accept(search.sorts))
          end
          # -- mongoid has different distinct method
          # opts[:distinct] ? relation.distinct : relation
          relation
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
          # parent.table
          Ransack::Adapters::Mongoid::Table.new(parent)
        end

        def klassify(obj)
          if Class === obj && obj.ancestors.include?(::Mongoid::Document)
            obj
          elsif obj.respond_to? :klass
            obj.klass
          elsif obj.respond_to? :base_klass
            obj.base_klass
          else
            raise ArgumentError, "Don't know how to klassify #{obj}"
          end
        end

        def lock_association(association)
          warn "lock_association is not implemented for Ransack mongoid adapter" if $DEBUG
        end

        def remove_association(association)
          warn "remove_association is not implemented for Ransack mongoid adapter" if $DEBUG
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
                parent, attr_name = get_parent_and_attribute_name(
                  remainder.join('_'), found_assoc.klass
                  )
                attr_name = "#{segments.join('_')}.#{attr_name}"
              end
            end
          end

          [parent, attr_name]
        end

        def get_association(str, parent = @base)
          klass = klassify parent
          ransackable_association?(str, klass) &&
            klass.reflect_on_all_associations_all.detect { |a| a.name.to_s == str }
        end

        def join_dependency(relation)
          if relation.respond_to?(:join_dependency) # Polyamorous enables this
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
              Constants::STRING_JOIN
            when Hash, Symbol, Array
              Constants::ASSOCIATION_JOIN
            when JoinDependency, JoinDependency::JoinAssociation
              Constants::STASHED_JOIN
            when Arel::Nodes::Join
              Constants::JOIN_NODE
            else
              raise 'unknown class: %s' % join.class.name
            end
          end

          association_joins = buckets[Constants::ASSOCIATION_JOIN] || []

          stashed_association_joins = buckets[Constants::STASHED_JOIN] || []

          join_nodes = buckets[Constants::JOIN_NODE] || []

          string_joins = (buckets[Constants::STRING_JOIN] || [])
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

          join_dependency # ActiveRecord::Associations::JoinDependency
        end

        # ActiveRecord method
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
