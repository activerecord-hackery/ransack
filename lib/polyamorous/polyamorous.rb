if defined?(::ActiveRecord)
  module Polyamorous
    InnerJoin = Arel::Nodes::InnerJoin
    OuterJoin = Arel::Nodes::OuterJoin

    JoinDependency  = ::ActiveRecord::Associations::JoinDependency
    JoinAssociation = ::ActiveRecord::Associations::JoinDependency::JoinAssociation
  end

  require 'polyamorous/tree_node'
  require 'polyamorous/join'
  require 'polyamorous/swapping_reflection_class'

  require 'polyamorous/activerecord/join_association'
  require 'polyamorous/activerecord/join_dependency'
  require 'polyamorous/activerecord/reflection'

  ActiveRecord::Reflection::AbstractReflection.send(:prepend, Polyamorous::ReflectionExtensions)

  Polyamorous::JoinDependency.send(:prepend, Polyamorous::JoinDependencyExtensions)
  Polyamorous::JoinDependency.singleton_class.send(:prepend, Polyamorous::JoinDependencyExtensions::ClassMethods)
  Polyamorous::JoinAssociation.send(:prepend, Polyamorous::JoinAssociationExtensions)
end
