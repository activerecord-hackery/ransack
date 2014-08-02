module Ransack
  class Visitor
    def visit_and(object)
      nodes = object.values.map { |o| accept(o) }.compact
      return nil unless nodes.size > 0

      if nodes.size > 1
        nodes.inject(&:and)
      else
        nodes.first
      end
    end

    def quoted?(object)
      case object
      when Arel::Nodes::SqlLiteral, Bignum, Fixnum
        false
      else
        true
      end
    end

  end
end
