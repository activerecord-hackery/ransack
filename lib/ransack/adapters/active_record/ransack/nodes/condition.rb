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
          predicates.first.right[0] = predicates.first.right[0].val if defined?(Arel::Nodes::Casted) && predicates.first.class == Arel::Nodes::In && predicates.first.right.is_a?(Array) && predicates.first.right[0].class == Arel::Nodes::Casted
          predicates.first
        end
      end

    end # Condition
  end
end
