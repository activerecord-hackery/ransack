# active_record_3_and_4.0_ruby_1.9/join_association.rb
module Polyamorous
  module JoinAssociationExtensions
    include SwappingReflectionClass
    def self.included(base)
      base.class_eval do
        alias_method_chain :initialize, :polymorphism
        alias_method :equality_without_polymorphism, :==
        alias_method :==, :equality_with_polymorphism
        if base.method_defined?(:active_record)
          alias_method :base_klass, :active_record
        end

        if ActiveRecord::VERSION::STRING =~ /^3\.0\./
          alias_method_chain :association_join, :polymorphism
        else
          alias_method_chain :build_constraint, :polymorphism
        end
      end
    end

    def initialize_with_polymorphism(
      reflection, join_dependency, parent = nil, polymorphic_class = nil
    )
      if polymorphic_class && ::ActiveRecord::Base > polymorphic_class
        swapping_reflection_klass(reflection, polymorphic_class) do |reflection|
          initialize_without_polymorphism(reflection, join_dependency, parent)
          self.reflection.options[:polymorphic] = true
        end
      else
        initialize_without_polymorphism(reflection, join_dependency, parent)
      end
    end

    def equality_with_polymorphism(other)
      equality_without_polymorphism(other) && base_klass == other.base_klass
    end

    def build_constraint_with_polymorphism(
      reflection, table, key, foreign_table, foreign_key
    )
      if reflection.options[:polymorphic]
        build_constraint_without_polymorphism(
          reflection, table, key, foreign_table, foreign_key
        )
        .and(foreign_table[reflection.foreign_type].eq(reflection.klass.name))
      else
        build_constraint_without_polymorphism(
          reflection, table, key, foreign_table, foreign_key
        )
      end
    end

    def association_join_with_polymorphism
      return @join if @Join
      @join = association_join_without_polymorphism
      if reflection.macro == :belongs_to && reflection.options[:polymorphic]
        aliased_table = Arel::Table.new(
          table_name,
          as: @aliased_table_name,
          engine: arel_engine,
          columns: klass.columns
        )
        parent_table = Arel::Table.new(
          parent.table_name,
          as: parent.aliased_table_name,
          engine: arel_engine,
          columns: parent.base_klass.columns
        )
        @join << parent_table[reflection.options[:foreign_type]]
                 .eq(reflection.klass.name)
      end
      @join
    end
  end
end
