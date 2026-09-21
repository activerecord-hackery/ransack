require 'ransack/active_record/base'
require 'ransack/active_record/dialect'
require 'ransack/active_record/context'

ActiveSupport.on_load(:active_record) do
  module Ransack
    # Everything Ransack needs from Active Record lives under this module: the
    # class methods mixed into every model (Base), the Context that turns a
    # search into a relation, and the extensions to Active Record's join
    # machinery that let Ransack build outer joins and polymorphic joins the
    # public query interface cannot express.
    module ActiveRecord
      JoinDependency  = ::ActiveRecord::Associations::JoinDependency
      JoinAssociation = ::ActiveRecord::Associations::JoinDependency::JoinAssociation
    end
  end

  require 'ransack/active_record/tree_node'
  require 'ransack/active_record/join'
  require 'ransack/active_record/join_association'
  require 'ransack/active_record/join_dependency'
  require 'ransack/active_record/reflection'

  ::ActiveRecord::Reflection::AbstractReflection.prepend Ransack::ActiveRecord::ReflectionExtensions
  Ransack::ActiveRecord::JoinDependency.prepend Ransack::ActiveRecord::JoinDependencyExtensions
  Ransack::ActiveRecord::JoinDependency.singleton_class.prepend Ransack::ActiveRecord::JoinDependencyExtensions::ClassMethods
  Ransack::ActiveRecord::JoinAssociation.prepend Ransack::ActiveRecord::JoinAssociationExtensions

  extend Ransack::ActiveRecord::Base
end

module Ransack
  # Ransack 5 and earlier kept the Active Record integration under
  # Ransack::Adapters::ActiveRecord, a leftover from when Mongoid was also
  # supported. Initializers that reopen it — usually to change the default
  # `ransackable_attributes` — keep working for one more major release, with a
  # deprecation warning pointing at the new name.
  module Adapters
    def self.const_missing(name)
      return super unless name == :ActiveRecord

      Ransack.deprecator.warn(
        'Ransack::Adapters::ActiveRecord is deprecated and will be removed ' \
        'in Ransack 7.0. Use Ransack::ActiveRecord instead.'
      )
      const_set(:ActiveRecord, Ransack::ActiveRecord)
    end
  end
end
