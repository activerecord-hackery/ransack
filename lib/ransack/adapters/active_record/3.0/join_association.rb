require 'active_record'

module Ransack
  module Adapters
    module ActiveRecord
      class JoinAssociation < ::ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation

        def initialize(reflection, join_dependency, parent = nil, polymorphic_class = nil)
          if polymorphic_class && ::ActiveRecord::Base > polymorphic_class
            swapping_reflection_klass(reflection, polymorphic_class) do |reflection|
              super(reflection, join_dependency, parent)
            end
          else
            super(reflection, join_dependency, parent)
          end
        end

        def swapping_reflection_klass(reflection, klass)
          reflection = reflection.clone
          original_polymorphic = reflection.options.delete(:polymorphic)
          reflection.instance_variable_set(:@klass, klass)
          yield reflection
        ensure
          reflection.options[:polymorphic] = original_polymorphic
        end

        def ==(other)
          super && active_record == other.active_record
        end

        def build_constraint(reflection, table, key, foreign_table, foreign_key)
          if reflection.options[:polymorphic]
            super.and(
              foreign_table[reflection.foreign_type].eq(reflection.klass.name)
            )
          else
            super
          end
        end

      end
    end
  end
end