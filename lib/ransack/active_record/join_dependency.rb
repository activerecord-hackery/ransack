module Ransack
  module ActiveRecord
    # Prepended to ActiveRecord::Associations::JoinDependency.
    #
    # Teaches the join tree about Join nodes (join type, polymorphic class),
    # and exposes the table aliasing Ransack needs to add one association at a
    # time to a relation that may already carry joins of its own.
    module JoinDependencyExtensions
      # Replaces ActiveRecord::Associations::JoinDependency#build
      def build(associations, base_klass)
        associations.map do |name, right|
          if name.is_a? Join
            reflection = find_reflection base_klass, name.name
            reflection.check_validity!
            reflection.check_eager_loadable!

            klass = if reflection.polymorphic?
              name.klass || base_klass
            else
              reflection.klass
            end
            JoinAssociation.new(reflection, build(right, klass), name.klass, name.type)
          else
            reflection = find_reflection base_klass, name
            reflection.check_validity!
            reflection.check_eager_loadable!

            if reflection.polymorphic?
              raise ::ActiveRecord::EagerLoadPolymorphicError.new(reflection)
            end
            JoinAssociation.new(reflection, build(right, reflection.klass))
          end
        end
      end

      def join_constraints(joins_to_add, alias_tracker, references)
        @alias_tracker = alias_tracker
        @joined_tables = {}
        @references = {}

        references.each do |table_name|
          @references[table_name.to_sym] = table_name if table_name.is_a?(String)
        end

        joins = make_join_constraints(join_root, join_type)

        joins.concat joins_to_add.flat_map { |oj|
          if join_root.match?(oj.join_root) && join_root.table.name == oj.join_root.table.name
            walk join_root, oj.join_root, oj.join_type
          else
            make_join_constraints(oj.join_root, oj.join_type)
          end
        }
      end

      def construct_tables_for_association!(join_root, association, join_type = self.join_type)
        tables = table_aliases_for(join_root, association, join_type)
        association.table = tables.first
        tables
      end

      private

      # The tables for a node's reflection chain, assigned the way Active
      # Record's JoinDependency#make_constraints assigns them, so that the
      # aliases Ransack binds conditions to are the ones the query will have.
      # Once a chain tail has been joined before, Active Record stops
      # aliasing and reuses that join; the remaining positions here are
      # filled from the same record for the correlated-subquery builder.
      def table_aliases_for(parent, node, join_type)
        @joined_tables ||= {}
        chain = node.reflection.chain
        terminated_at = nil

        chain.each_with_index.map { |reflection, index|
          remaining = chain[index..]
          table, terminated = @joined_tables[remaining]
          root = reflection == node.reflection

          if terminated_at
            table || reflection.klass.arel_table
          elsif table && (!root || !terminated)
            @joined_tables[remaining] = [table, root] if root
            terminated_at = index
            table
          else
            table_name = @references && @references[reflection.name.to_sym]&.to_s
            table = alias_tracker.aliased_table_for(reflection.klass.arel_table, table_name) do
              name = reflection.alias_candidate(parent.table_name)
              root ? name : "#{name}_join"
            end
            @joined_tables[remaining] ||= [table, root] if join_type == Arel::Nodes::OuterJoin
            table
          end
        }
      end

      module ClassMethods
        # Prepended before ActiveRecord::Associations::JoinDependency#walk_tree
        #
        def walk_tree(associations, hash)
          case associations
          when TreeNode
            associations.add_to_tree(hash)
          when Hash
            associations.each do |k, v|
              cache =
                if TreeNode === k
                  k.add_to_tree(hash)
                else
                  hash[k] ||= {}
                end
              walk_tree(v, cache)
            end
          else
            super(associations, hash)
          end
        end
      end

    end
  end
end
