module Ransack
  module Nodes
    class Condition

      def arel_predicate
        if attributes.size > 1
          combinator_for_predicates
        else
          format_predicate
        end
      end

      private

        def arel_predicates
          attributes.map do |a|
            a.attr.send(
              arel_predicate_for_attribute(a), formatted_values_for_attribute(a)
            )
          end
        end

        def combinator_for_predicates
          if combinator === Constants::AND
            Arel::Nodes::Grouping.new(arel_predicates.inject(&:and))
          elsif combinator === Constants::OR
            arel_predicates.inject(&:or)
          end
        end

        def format_predicate
          predicate = arel_predicates.first
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
