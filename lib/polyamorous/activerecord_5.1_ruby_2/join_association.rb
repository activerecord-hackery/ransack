# active_record_5.1_ruby_2/join_association.rb

module Polyamorous
  module JoinAssociationExtensions
    include SwappingReflectionClass
    def self.prepended(base)
      base.class_eval { attr_reader :join_type }
    end

    def initialize(reflection, children, polymorphic_class = nil,
                   join_type = Arel::Nodes::InnerJoin)
      @join_type = join_type
      if polymorphic_class && ::ActiveRecord::Base > polymorphic_class
        swapping_reflection_klass(reflection, polymorphic_class) do |reflection|
          super(reflection, children)
          self.reflection.options[:polymorphic] = true
        end
      else
        super(reflection, children)
      end
    end

    # Reference: https://github.com/rails/rails/commit/9b15db5
    # NOTE: Not sure we still need it?
    #
    def ==(other)
      base_klass == other.base_klass
    end

    def build_constraint(klass, table, key, foreign_table, foreign_key)
      if reflection.polymorphic?
        super(klass, table, key, foreign_table, foreign_key)
          .and(foreign_table[reflection.foreign_type].eq(reflection.klass.name))
      else
        super(klass, table, key, foreign_table, foreign_key)
      end
    end
  end
end
