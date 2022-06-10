module Ransack
  module Nodes
    class Condition

      def arel_predicate
        predicate = attributes.map { |attribute|
          association = attribute.parent
          if negative? && attribute.associated_collection?
            query = context.build_correlated_subquery(association)
            context.remove_association(association)
            if self.predicate_name == 'not_null' && self.value
              query.where(format_predicate(attribute))
              Arel::Nodes::In.new(context.primary_key, Arel.sql(query.to_sql))
            else
              query.where(format_predicate(attribute).not)
              Arel::Nodes::NotIn.new(context.primary_key, Arel.sql(query.to_sql))
            end
          else
            format_predicate(attribute)
          end
        }.reduce(combinator_method)

        if replace_right_node?(predicate)
          # Replace right node object to plain integer value in order to avoid
          # ActiveModel::RangeError from Arel::Node::Casted.
          # The error can be ignored here because RDBMSs accept large numbers
          # in condition clauses.
          plain_value = predicate.right.value
          predicate.right = plain_value
        end

        predicate
      end

      private

        def combinator_method
          combinator === Constants::OR ? :or : :and
        end

        def format_predicate(attribute)
          arel_pred = arel_predicate_for_attribute(attribute)
          arel_values = formatted_values_for_attribute(attribute)
          predicate = attr_value_for_attribute(attribute).public_send(arel_pred, arel_values)

          if in_predicate?(predicate)
            predicate.right = predicate.right.map do |pr|
              casted_array?(pr) ? format_values_for(pr) : pr
            end
          end

          predicate
        end

        def in_predicate?(predicate)
          return unless defined?(Arel::Nodes::Casted)
          predicate.class == Arel::Nodes::In || predicate.class == Arel::Nodes::NotIn
        end

        def casted_array?(predicate)
          predicate.value.is_a?(Array) && predicate.is_a?(Arel::Nodes::Casted)
        end

        def format_values_for(predicate)
          predicate.value.map do |val|
            val.is_a?(String) ? Arel::Nodes.build_quoted(val) : val
          end
        end

        def replace_right_node?(predicate)
          return false unless predicate.is_a?(Arel::Nodes::Binary)

          arel_node = predicate.right
          return false unless arel_node.is_a?(Arel::Nodes::Casted)

          relation, name = arel_node.attribute.values
          attribute_type = relation.type_for_attribute(name).type
          attribute_type == :integer && arel_node.value.is_a?(Integer)
        end

    end
  end
end
