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
          when 'and'
            Arel::Nodes::Grouping.new(Arel::Nodes::And.new(predicates))
          when 'or'
            predicates.inject(&:or)
          end
        else
          predicates.first
        end
      end

    end # Condition
  end
end
