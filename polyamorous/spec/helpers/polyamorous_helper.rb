module PolyamorousHelper
  if ActiveRecord::VERSION::STRING >= "4.1"
    def new_join_association(reflection, children, klass)
      Polyamorous::JoinAssociation.new reflection, children, klass
    end
  else
    def new_join_association(reflection, join_dependency, parent, klass)
      Polyamorous::JoinAssociation.new reflection, join_dependency, parent, klass
    end
  end

  if ActiveRecord::VERSION::STRING >= "5.2"
    def new_join_dependency(klass, associations = {})
      alias_tracker = ::ActiveRecord::Associations::AliasTracker.create(klass.connection, klass.table_name, [])
      Polyamorous::JoinDependency.new klass, klass.arel_table, associations, alias_tracker
    end
  else
    def new_join_dependency(klass, associations = {})
      Polyamorous::JoinDependency.new klass, associations, []
    end
  end

  def new_join(name, type = Polyamorous::InnerJoin, klass = nil)
    Polyamorous::Join.new name, type, klass
  end
end
