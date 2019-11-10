module Arel
  module Visitors
    class ToSql < Reduce
      private
      def visit_Arel_Nodes_IMatches o, collector
        collector << "LOWER("
        collector = visit(o.left, collector)
        collector << ") LIKE LOWER(#{quote(o.right)})"
      end

      def visit_Arel_Nodes_DoseNotIMatch o, collector
        collector << "LOWER("
        collector = visit(o.left, collector)
        collector << ") NOT LIKE LOWER(#{quote(o.right)})"
      end
    end
  end

  module Nodes
    class IMatches < Binary; end
    class DoseNotIMatch < Binary; end
  end

  module Predications
    def i_matches other
      Nodes::IMatches.new self, other
    end

    def i_matches_any others
      grouping_any :i_matches, others
    end

    def i_matches_all others
      grouping_all :i_matches, others
    end

    def not_i_match other
      Nodes::DoseNotIMatch.new self, other
    end

    def not_i_match_any others
      grouping_any :not_i_match, others
    end

    def not_i_match_all others
      grouping_all :not_i_match, others
    end
  end
end
