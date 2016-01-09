module Ransack
  module Nodes
    class Condition

      def arel_predicate
        attributes.map { |attribute|
          association = attribute.parent
          if negative? && attribute.associated_collection?
            query = context.build_correlated_subquery(association)
            query.where(format_predicate(attribute).not)
            context.remove_association(association)
            Arel::Nodes::NotIn.new(context.primary_key, Arel.sql(query.to_sql))
          else
            format_predicate(attribute)
          end
        }.reduce(combinator_method)
      end

      private

        def combinator_method
          combinator === Constants::OR ? :or : :and
        end

        def format_predicate(attribute)
          arel_pred = arel_predicate_for_attribute(attribute)
          arel_values = formatted_values_for_attribute(attribute)
          predicate = attribute.attr.public_send(arel_pred, arel_values)
          if casted_array_with_in_predicate?(predicate)
            predicate.right[0] = format_values_for(predicate.right[0])
          end
          predicate
        end

        def casted_array_with_in_predicate?(predicate)
          return unless defined?(Arel::Nodes::Casted)
          predicate.class == Arel::Nodes::In &&
          predicate.right[0].respond_to?(:val) &&
          predicate.right[0].val.is_a?(Array)
        end

        def format_values_for(predicate)
          predicate.val.map do |value|
            value.is_a?(String) ? Arel::Nodes.build_quoted(value) : value
          end
        end

    end
  end
end
