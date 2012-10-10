module Arel

  module Visitors

    class DepthFirst < Visitor

      unless method_defined?(:visit_Arel_Nodes_InfixOperation)
        alias :visit_Arel_Nodes_InfixOperation :binary
      end

    end

  end
end