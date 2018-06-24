# active_record_4.2_ruby_1.9/join_association.rb
module Polyamorous
  module JoinAssociationExtensions
    include SwappingReflectionClass
    def self.included(base)
      base.class_eval do
        attr_reader :join_type
        alias_method_chain :initialize, :polymorphism
        alias_method_chain :build_constraint, :polymorphism
      end
    end

    def initialize_with_polymorphism(reflection, children,
      polymorphic_class = nil, join_type = Arel::Nodes::InnerJoin)
      @join_type = join_type
      if polymorphic_class && ::ActiveRecord::Base > polymorphic_class
        swapping_reflection_klass(reflection, polymorphic_class) do |reflection|
          initialize_without_polymorphism(reflection, children)
          self.reflection.options[:polymorphic] = true
        end
      else
        initialize_without_polymorphism(reflection, children)
      end
    end

    # Reference https://github.com/rails/rails/commit/9b15db51b78028bfecdb85595624de4b838adbd1
    def ==(other)
      base_klass == other.base_klass
    end

    def build_constraint_with_polymorphism(
      klass, table, key, foreign_table, foreign_key
    )
      if reflection.polymorphic?
        build_constraint_without_polymorphism(
          klass, table, key, foreign_table, foreign_key
        )
        .and(foreign_table[reflection.foreign_type].eq(reflection.klass.name))
      else
        build_constraint_without_polymorphism(
          klass, table, key, foreign_table, foreign_key
        )
      end
    end
  end
end
