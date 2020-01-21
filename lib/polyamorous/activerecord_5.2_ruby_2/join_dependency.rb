module Polyamorous
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
            raise ActiveRecord::EagerLoadPolymorphicError.new(reflection)
          end
          JoinAssociation.new(reflection, build(right, reflection.klass))
        end
      end
    end

    def join_constraints(joins_to_add, join_type, alias_tracker)
      @alias_tracker = alias_tracker

      construct_tables!(join_root)
      joins = make_join_constraints(join_root, join_type)

      joins.concat joins_to_add.flat_map { |oj|
        construct_tables!(oj.join_root)
        if join_root.match?(oj.join_root) && join_root.table.name == oj.join_root.table.name
          walk join_root, oj.join_root
        else
          make_join_constraints(oj.join_root, join_type)
        end
      }
    end

    private
      def make_constraints(parent, child, join_type = Arel::Nodes::OuterJoin)
        foreign_table = parent.table
        foreign_klass = parent.base_klass
        join_type = child.join_type || join_type if join_type == Arel::Nodes::InnerJoin
        joins = child.join_constraints(foreign_table, foreign_klass, join_type, alias_tracker)
        joins.concat child.children.flat_map { |c| make_constraints(child, c, join_type) }
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
