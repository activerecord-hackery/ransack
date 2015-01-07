module Ransack
  module Nodes
    class Condition

      def arel_predicate
        predicates = attributes.map do |attr|
          attr.attr.send(
            arel_predicate_for_attribute(attr),
            formatted_values_for_attribute(attr)
          )
        end

        if predicates.size > 1
          case combinator
          when Constants::AND
            Arel::Nodes::Grouping.new(Arel::Nodes::And.new(predicates))
          when Constants::OR
            predicates.inject(&:or)
          end
        else
          return_predicate(predicates.first)
        end
      end

      private

        # FIXME: Improve this edge case patch for Arel >= 6.0 (Rails >= 4.2)
        #        that adds several conditionals to handle changing Arel API.
        #        Related to Ransack issue #472 and pull requests #486-488.
        #
        def return_predicate(predicate)
          if casted_array_with_in_predicate?(predicate)
            predicate.right[0] = predicate.right[0].val
            .map { |v| v.is_a?(String) ? Arel::Nodes.build_quoted(v) : v }
          end
          predicate
        end
        #
        def casted_array_with_in_predicate?(predicate)
          return unless defined?(Arel::Nodes::Casted)
          predicate.class == Arel::Nodes::In &&
          predicate.right.is_a?(Array) &&
          predicate.right[0].class == Arel::Nodes::Casted
        end

    end
  end
end
