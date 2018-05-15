module Ransack
  class Visitor
    def visit_and(object)
      nodes = object.values.map { |o| accept(o) }.compact
      nodes.inject(&:and)
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
