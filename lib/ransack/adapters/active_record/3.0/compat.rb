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