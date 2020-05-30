module Polyamorous
  module ReflectionExtensions
    if ActiveRecord.version > ::Gem::Version.new('5.2.3')
      def join_scope(table, foreign_table, foreign_klass)
        if respond_to?(:polymorphic?) && polymorphic?
          super.where!(foreign_table[foreign_type].eq(klass.name))
        else
          super
        end
      end
    else
      def build_join_constraint(table, foreign_table)
        if polymorphic?
          super.and(foreign_table[foreign_type].eq(klass.name))
        else
          super
        end
      end
    end
  end
end
