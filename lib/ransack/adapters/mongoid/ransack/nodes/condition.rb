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

        if predicates.size > 1 && combinator == 'and'
          Arel::Nodes::Grouping.new(Arel::Nodes::And.new(predicates))
        else
          predicates.inject(&:or)
        end
      end

    end # Condition
  end
end
