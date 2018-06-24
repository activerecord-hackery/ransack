if defined?(::ActiveRecord)
  module Polyamorous
    if defined?(Arel::InnerJoin)
      InnerJoin = Arel::InnerJoin
      OuterJoin = Arel::OuterJoin
    else
      InnerJoin = Arel::Nodes::InnerJoin
      OuterJoin = Arel::Nodes::OuterJoin
    end

    if defined?(::ActiveRecord::Associations::JoinDependency)
      JoinDependency  = ::ActiveRecord::Associations::JoinDependency
      JoinAssociation = ::ActiveRecord::Associations::JoinDependency::JoinAssociation
      JoinBase = ::ActiveRecord::Associations::JoinDependency::JoinBase
    else
      JoinDependency  = ::ActiveRecord::Associations::ClassMethods::JoinDependency
      JoinAssociation = ::ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation
      JoinBase = ::ActiveRecord::Associations::ClassMethods::JoinDependency::JoinBase
    end
  end

  require 'polyamorous/tree_node'
  require 'polyamorous/join'
  require 'polyamorous/swapping_reflection_class'

  ar_version = ::ActiveRecord::VERSION::STRING[0,3]
  ar_version = '3_and_4.0' if ar_version < '4.1'
  ar_version = ::ActiveRecord::VERSION::STRING[0,5] if ar_version == '5.2'

  method, ruby_version =
    if RUBY_VERSION >= '2.0' && ar_version >= '4.1'
      # Ruby 2; we can use `prepend` to patch Active Record cleanly.
      [:prepend, '2']
    else
      # Ruby 1.9; we must use `alias_method` to patch Active Record.
      [:include, '1.9']
    end

  %w(join_association join_dependency).each do |file|
    require "polyamorous/activerecord_#{ar_version}_ruby_#{ruby_version}/#{file}"
  end

  Polyamorous::JoinDependency.send(method, Polyamorous::JoinDependencyExtensions)
  if method == :prepend
    Polyamorous::JoinDependency.singleton_class
    .send(:prepend, Polyamorous::JoinDependencyExtensions::ClassMethods)
  end
  Polyamorous::JoinAssociation.send(method, Polyamorous::JoinAssociationExtensions)

  Polyamorous::JoinBase.class_eval do
    if method_defined?(:active_record)
      alias_method :base_klass, :active_record
    end
  end
end
