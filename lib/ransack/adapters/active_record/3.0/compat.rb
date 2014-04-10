# UGLY, UGLY MONKEY PATCHES FOR BACKWARDS COMPAT!!! AVERT YOUR EYES!!
if Arel::Nodes::And < Arel::Nodes::Binary
  class Ransack::Visitor
    def visit_Ransack_Nodes_And(object)
      nodes = object.values.map {|o| accept(o)}.compact
      return nil unless nodes.size > 0

      if nodes.size > 1
        nodes.inject(&:and)
      else
        nodes.first
      end
    end
  end
end

class ::ActiveRecord::Associations::ClassMethods::JoinDependency::JoinBase
  def table
    Arel::Table.new(table_name, :as      => aliased_table_name,
                                :engine  => active_record.arel_engine,
                                :columns => active_record.columns)
  end
end

module Arel

  class Table
    alias :table_name :name

    def [] name
      ::Arel::Attribute.new self, name.to_sym
    end
  end

  module Nodes
    class Node
      def not
        Nodes::Not.new self
      end
    end

    remove_const :And
    class And < Arel::Nodes::Node
      attr_reader :children

      def initialize children, right = nil
        unless Array === children
          children = [children, right]
        end
        @children = children
      end

      def left
        children.first
      end

      def right
        children[1]
      end
    end

    class NamedFunction < Arel::Nodes::Function
      attr_accessor :name, :distinct

      include Arel::Predications

      def initialize name, expr, aliaz = nil
        super(expr, aliaz)
        @name = name
        @distinct = false
      end
    end

    class InfixOperation < Binary
      include Arel::Expressions
      include Arel::Predications

      attr_reader :operator

      def initialize operator, left, right
        super(left, right)
        @operator = operator
      end
    end

    class Multiplication < InfixOperation
      def initialize left, right
        super(:*, left, right)
      end
    end

    class Division < InfixOperation
      def initialize left, right
        super(:/, left, right)
      end
    end

    class Addition < InfixOperation
      def initialize left, right
        super(:+, left, right)
      end
    end

    class Subtraction < InfixOperation
      def initialize left, right
        super(:-, left, right)
      end
    end
  end

  module Visitors
    class ToSql
      def column_for attr
        name    = attr.name.to_s
        table   = attr.relation.table_name

        column_cache[table][name]
      end

      def column_cache
        @column_cache ||= Hash.new do |hash, key|
          hash[key] = Hash[
            @engine.connection.columns(key, "#{key} Columns").map do |c|
              [c.name, c]
            end
          ]
        end
      end

      def visit_Arel_Nodes_InfixOperation o
        "#{visit o.left} #{o.operator} #{visit o.right}"
      end

      def visit_Arel_Nodes_NamedFunction o
        "#{o.name}(#{o.distinct ? 'DISTINCT ' : ''}#{o.expressions.map { |x|
          visit x
        }.join(', ')})#{o.alias ? " AS #{visit o.alias}" : ''}"
      end

      def visit_Arel_Nodes_And o
        o.children.map { |x| visit x }.join ' AND '
      end

      def visit_Arel_Nodes_Not o
        "NOT (#{visit o.expr})"
      end

      def visit_Arel_Nodes_Values o
        "VALUES (#{o.expressions.zip(o.columns).map { |value, attr|
          if Nodes::SqlLiteral === value
            visit_Arel_Nodes_SqlLiteral value
          else
            quote(value, attr && column_for(attr))
          end
        }.join ', '})"
      end
    end
  end

  module Predications
    def as other
      Nodes::As.new self, Nodes::SqlLiteral.new(other)
    end
  end

end