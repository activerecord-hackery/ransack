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

  ar_version = ::ActiveRecord::VERSION::STRING[0,3]
  ar_version = ::ActiveRecord::VERSION::STRING[0,5] if ar_version >= "5.2"
  ar_version = "5.2.1" if ::ActiveRecord::VERSION::STRING >= "5.2.1"

  %w(join_association join_dependency).each do |file|
    require "polyamorous/activerecord_#{ar_version}_ruby_2/#{file}"
  end

  Polyamorous::JoinDependency.send(:prepend, Polyamorous::JoinDependencyExtensions)
  Polyamorous::JoinDependency.singleton_class.send(:prepend, Polyamorous::JoinDependencyExtensions::ClassMethods)
  Polyamorous::JoinAssociation.send(:prepend, Polyamorous::JoinAssociationExtensions)
end
