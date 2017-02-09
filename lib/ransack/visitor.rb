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
      if object.combinator == Constants::OR
        visit_or(object)
      else
        visit_and(object)
      end
    end

    def visit_and(object)
      raise "not implemented"
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
      # The first half of this conditional is the original implementation in
      # Ransack, as of version 1.6.6.
      #
      # The second half of the conditional kicks in when the column name
      # provided isn't found/valid. In those cases, we look for a scope on the
      # model that will apply a custom sort. If found, we return the scope's
      # name.
      if object.valid?
        object.attr.send(object.dir)
      else
        scope_name = :"sort_by_#{object.name}_#{object.dir}"
        scope_name if object.context.object.respond_to?(scope_name)
      end
    end

    def quoted?(object)
      raise "not implemented"
    end

    def visit(object)
      send(DISPATCH[object.class], object)
    end

    DISPATCH = Hash.new do |hash, klass|
      hash[klass] = "visit_#{
        klass.name.gsub(Constants::TWO_COLONS, Constants::UNDERSCORE)
        }"
    end

  end
end
