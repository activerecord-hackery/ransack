require 'active_record'

module Ransack
  module Adapters
    module ActiveRecord

      class JoinAssociation < ::ActiveRecord::Associations::JoinDependency::JoinAssociation

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

        # This is a temporary hack. Jon's going to refactor this in AR to
        # make overrides simpler
        def join_to(relation)
          tables        = @tables.dup
          foreign_table = parent_table

          # The chain starts with the target table, but we want to end with it here (makes
          # more sense in this context), so we reverse
          chain.reverse.each_with_index do |reflection, i|
            table = tables.shift

            case reflection.source_macro
            when :belongs_to
              key         = reflection.association_primary_key
              foreign_key = reflection.foreign_key
            when :has_and_belongs_to_many
              # Join the join table first...
              relation.from(join(
                table,
                table[reflection.foreign_key].
                  eq(foreign_table[reflection.active_record_primary_key])
              ))

              foreign_table, table = table, tables.shift

              key         = reflection.association_primary_key
              foreign_key = reflection.association_foreign_key
            else
              key         = reflection.foreign_key
              foreign_key = reflection.active_record_primary_key
            end

            constraint = table[key].eq(foreign_table[foreign_key])

            if reflection.options[:polymorphic]
              constraint = constraint.and(
                foreign_table[reflection.foreign_type].eq(reflection.klass.name)
              )
            end

            if reflection.klass.finder_needs_type_condition?
              constraint = table.create_and([
                constraint,
                reflection.klass.send(:type_condition, table)
              ])
            end

            relation.from(join(table, constraint))

            unless conditions[i].empty?
              relation.where(sanitize(conditions[i], table))
            end

            # The current table in this iteration becomes the foreign table in the next
            foreign_table = table
          end

          relation
        end

      end

    end
  end
end