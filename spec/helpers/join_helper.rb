module JoinHelper
  def new_join_association(reflection, children, klass)
    Ransack::ActiveRecord::JoinAssociation.new reflection, children, klass
  end

  def new_join_dependency(klass, associations = {})
    Ransack::ActiveRecord::JoinDependency.new klass, klass.arel_table, associations, Arel::Nodes::InnerJoin
  end

  def new_join(name, type = Arel::Nodes::InnerJoin, klass = nil)
    Ransack::ActiveRecord::Join.new name, type, klass
  end
end
