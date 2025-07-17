ActiveSupport.on_load(:active_record) do
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

  if ::ActiveRecord.version >= ::Gem::Version.new("7.2") && ::ActiveRecord.version < ::Gem::Version.new("7.2.2.1")
    require "polyamorous/activerecord/join_association_7_2"
  end

  ActiveRecord::Reflection::AbstractReflection.send(:prepend, Polyamorous::ReflectionExtensions)

  Polyamorous::JoinDependency.send(:prepend, Polyamorous::JoinDependencyExtensions)
  Polyamorous::JoinDependency.singleton_class.send(:prepend, Polyamorous::JoinDependencyExtensions::ClassMethods)
  Polyamorous::JoinAssociation.send(:prepend, Polyamorous::JoinAssociationExtensions)
end
