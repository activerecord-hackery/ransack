module Ransack
  module ActiveRecord
    # Prepended to ActiveRecord::Reflection::AbstractReflection.
    #
    # When a polymorphic belongs_to is joined to one concrete class, the join
    # must also constrain the type column, or rows pointing at a different
    # class with a colliding id would match.
    module ReflectionExtensions
      def join_scope(table, foreign_table, foreign_klass)
        if respond_to?(:polymorphic?) && polymorphic?
          super.where!(foreign_table[foreign_type].eq(klass.name))
        else
          super
        end
      end
    end
  end
end
