module Polyamorous
  module ReflectionExtensions
    def build_join_constraint(table, foreign_table)
      if polymorphic?
        super(table, foreign_table)
        .and(foreign_table[foreign_type].eq(klass.name))
      else
        super(table, foreign_table)
      end
    end
  end
end
