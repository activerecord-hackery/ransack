module Ransack
  class Visitor

    def accept(object)
      visit(object)
    end

    def can_accept?(object)
      respond_to? DISPATCH[object.class]
    end

    def visit_Array(object)
      object.map { |o| accept(o) }.compact
    end

    def visit_Ransack_Nodes_Condition(object)
      object.arel_predicate if object.valid?
    end

    def visit_Ransack_Nodes_Grouping(object)
      object.combinator == 'or' ? visit_or(object) : visit_and(object)
    end

    def visit_and(object)
      nodes = object.values.map { |o| accept(o) }.compact
      return nil unless nodes.size > 0

      if nodes.size > 1
        Arel::Nodes::Grouping.new(Arel::Nodes::And.new(nodes))
      else
        nodes.first
      end
    end

    def visit_or(object)
      nodes = object.values.map { |o| accept(o) }.compact
      return nil unless nodes.size > 0

      if nodes.size > 1
        nodes.inject(&:or)
      else
        nodes.first
      end
    end

    def visit_Ransack_Nodes_Sort(object)
      return unless object.valid?
      if object.attr.is_a? Arel::Attributes::Attribute
        object.attr.send(object.dir)
      else
        ordered object
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

    def visit(object)
      send(DISPATCH[object.class], object)
    end

    DISPATCH = Hash.new do |hash, klass|
      hash[klass] = "visit_#{klass.name.gsub('::', '_')}"
    end

    private

      def ordered(object)
        case object.dir
        when 'asc'.freeze
          Arel::Nodes::Ascending.new(object.attr)
        when 'desc'.freeze
          Arel::Nodes::Descending.new(object.attr)
        end
      end
  end
end
