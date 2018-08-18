if defined?(::ActiveRecord)
  module Polyamorous
    InnerJoin = Arel::Nodes::InnerJoin
    OuterJoin = Arel::Nodes::OuterJoin

    JoinDependency  = ::ActiveRecord::Associations::JoinDependency
    JoinAssociation = ::ActiveRecord::Associations::JoinDependency::JoinAssociation
    JoinBase = ::ActiveRecord::Associations::JoinDependency::JoinBase
  end

  require 'polyamorous/tree_node'
  require 'polyamorous/join'
  require 'polyamorous/swapping_reflection_class'

  ar_version = ::ActiveRecord::VERSION::STRING[0,3]
  ar_version = ::ActiveRecord::VERSION::STRING[0,5] if ar_version >= '5.2'

  %w(join_association join_dependency).each do |file|
    require "polyamorous/activerecord_#{ar_version}_ruby_2/#{file}"
  end

  Polyamorous::JoinDependency.send(:prepend, Polyamorous::JoinDependencyExtensions)
  Polyamorous::JoinDependency.singleton_class.send(:prepend, Polyamorous::JoinDependencyExtensions::ClassMethods)
  Polyamorous::JoinAssociation.send(:prepend, Polyamorous::JoinAssociationExtensions)

  Polyamorous::JoinBase.class_eval do
    if method_defined?(:active_record)
      alias_method :base_klass, :active_record
    end
  end
end
