require 'ransack/context'
require 'polyamorous'
require 'ransack/adapters/active_record/3.0/compat'

module Ransack

  module Adapters
    module ActiveRecord
      class Context < ::Ransack::Context

        # Because the AR::Associations namespace is insane
        if defined? ::ActiveRecord::Associations::ClassMethods::JoinDependency
          JoinDependency = ::ActiveRecord::Associations::ClassMethods::JoinDependency
        end

        # Redefine a few things for ActiveRecord 3.0.

        def initialize(object, options = {})
          super
          @arel_visitor = Arel::Visitors.visitor_for @engine
        end

        def relation_for(object)
          object.scoped
        end

        def evaluate(search, opts = {})
          viz = Visitor.new
          relation = @object.where(viz.accept(search.base))
          if search.sorts.any?
            relation = relation.except(:order)
            .reorder(viz.accept(search.sorts))
          end
          if opts[:distinct]
            relation.select(Constants::DISTINCT + @klass.quoted_table_name +
              Constants::DOT_ASTERIX)
          else
            relation
          end
        end

        def attribute_method?(str, klass = @klass)
          exists = false

          if ransackable_attribute?(str, klass)
            exists = true
          elsif (segments = str.split(/_/)).size > 1
            remainder = []
            found_assoc = nil
            while !found_assoc && remainder.unshift(segments.pop) &&
              segments.size > 0 do
              assoc, poly_class = unpolymorphize_association(
                segments.join(Constants::UNDERSCORE)
                )
              if found_assoc = get_association(assoc, klass)
                exists = attribute_method?(
                  remainder.join(Constants::UNDERSCORE),
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

        def type_for(attr)
          return nil unless attr && attr.valid?
          klassify(attr.parent)
          .columns_hash[attr.arel_attribute.name.to_s]
          .type
        end

        # All dependent JoinAssociation items used in the search query
        #
        def join_associations
          @join_dependency.join_associations
        end

        def join_sources
          raise NotImplementedError,
          "ActiveRecord 3.0 does not use join_sources or support joining relations with Arel::Join nodes. Use join_associations."
        end

        def alias_tracker
          raise NotImplementedError,
          "ActiveRecord 3.0 does not have an alias tracker"
        end

        private

        def get_parent_and_attribute_name(str, parent = @base)
          attr_name = nil

          if ransackable_attribute?(str, klassify(parent))
            attr_name = str
          elsif (segments = str.split(/_/)).size > 1
            remainder = []
            found_assoc = nil
            while remainder.unshift(segments.pop) && segments.size > 0 &&
              !found_assoc do
              assoc, klass = unpolymorphize_association(
                segments.join(Constants::UNDERSCORE)
                )
              if found_assoc = get_association(assoc, parent)
                join = build_or_find_association(
                  found_assoc.name, parent, klass
                  )
                parent, attr_name = get_parent_and_attribute_name(
                  remainder.join(Constants::UNDERSCORE), join
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
          if relation.respond_to?(:join_dependency) # Polyamorous enables this
            relation.join_dependency
          else
            build_join_dependency(relation)
          end
        end

        def build_join_dependency(relation)
          buckets = relation.joins_values.group_by do |join|
            case join
            when String
              Constants::STRING_JOIN
            when Hash, Symbol, Array
              Constants::ASSOCIATION_JOIN
            when ::ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation
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

          string_joins = (buckets[Constants::STRING_JOIN] || []).map(&:strip).uniq

          join_list = relation.send :custom_join_sql, (string_joins + join_nodes)

          join_dependency = JoinDependency.new(
            relation.klass,
            association_joins,
            join_list
          )

          join_nodes.each do |join|
            join_dependency.table_aliases[join.left.name.downcase] = 1
          end

          join_dependency.graft(*stashed_association_joins)
        end

        def build_or_find_association(name, parent = @base, klass = nil)
          found_association = @join_dependency.join_associations
          .detect do |assoc|
            assoc.reflection.name == name &&
            assoc.parent == parent &&
            (!klass || assoc.reflection.klass == klass)
          end
          unless found_association
            @join_dependency.send(
              :build, Polyamorous::Join.new(name, @join_type, klass), parent
              )
            found_association = @join_dependency.join_associations.last

            default_conditions = found_association.active_record.scoped.arel.constraints
            if default_conditions.any?
              and_default_conditions = "AND #{default_conditions.reduce(&:and).to_sql}"
            end

            # Leverage the stashed association functionality in AR
            @object = @object.joins(found_association).joins(and_default_conditions)
          end

          found_association
        end

      end
    end
  end
end
