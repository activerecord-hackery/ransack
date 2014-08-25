module Arel

  module Nodes
    %w{
      IDoesNotMatch
      IMatches
    }.each do |name|
      const_set name, Class.new(Binary)
    end
  end

  module Predications
    def i_matches other
      Nodes::IMatches.new self, other
    end

    def i_does_not_match other
      Nodes::IDoesNotMatch.new self, other
    end
  end

  module Visitors

    class ToSql < Arel::Visitors::Visitor
      def visit_Arel_Nodes_IDoesNotMatch o
        "UPPER(#{visit o.left}) NOT LIKE UPPER(#{visit o.right})"
      end

      def visit_Arel_Nodes_IMatches o
        "UPPER(#{visit o.left}) LIKE UPPER(#{visit o.right})"
      end
    end

    class Dot < Arel::Visitors::Visitor
      alias :visit_Arel_Nodes_IMatches            :binary
      alias :visit_Arel_Nodes_IDoesNotMatch       :binary
    end

    class DepthFirst < Visitor

      unless method_defined?(:visit_Arel_Nodes_InfixOperation)
        alias :visit_Arel_Nodes_InfixOperation :binary
        alias :visit_Arel_Nodes_IMatches            :binary
        alias :visit_Arel_Nodes_IDoesNotMatch       :binary
      end

    end

  end
end