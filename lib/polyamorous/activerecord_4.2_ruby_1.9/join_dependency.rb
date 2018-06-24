# active_record_4.2_ruby_1.9/join_dependency.rb
require 'polyamorous/activerecord_4.2_ruby_2/join_dependency'

module Polyamorous
  module JoinDependencyExtensions
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        class << self
          alias_method :walk_tree_without_polymorphism, :walk_tree
          alias_method :walk_tree, :walk_tree_with_polymorphism
        end

        alias_method :build_without_polymorphism, :build
        alias_method :build, :build_with_polymorphism

        alias_method :join_constraints_without_polymorphism, :join_constraints
        alias_method :join_constraints, :join_constraints_with_polymorphism
      end
    end

    # Replaces ActiveRecord::Associations::JoinDependency#build
    #
    def build_with_polymorphism(associations, base_klass)
      associations.map do |name, right|
        if name.is_a? Join
          reflection = find_reflection base_klass, name.name
          reflection.check_validity!
          klass = if reflection.polymorphic?
            name.klass || base_klass
          else
            reflection.klass
          end
          JoinAssociation.new(reflection, build(right, klass), name.klass, name.type)
        else
          reflection = find_reflection base_klass, name
          reflection.check_validity!
          if reflection.polymorphic?
            raise ActiveRecord::EagerLoadPolymorphicError.new(reflection)
          end
          JoinAssociation.new reflection, build(right, reflection.klass)
        end
      end
    end

    # Replaces ActiveRecord::Associations::JoinDependency#join_constraints
    # to call #make_polyamorous_inner_joins instead of #make_inner_joins
    #
    def join_constraints_with_polymorphism(outer_joins)
      joins = join_root.children.flat_map { |child|
        make_polyamorous_inner_joins join_root, child
      }
      joins.concat outer_joins.flat_map { |oj|
        if join_root.match? oj.join_root
          walk(join_root, oj.join_root)
        else
          oj.join_root.children.flat_map { |child|
            make_outer_joins(oj.join_root, child)
          }
        end
      }
    end

    module ClassMethods
      # Replaces ActiveRecord::Associations::JoinDependency#self.walk_tree
      #
      def walk_tree_with_polymorphism(associations, hash)
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
          walk_tree_without_polymorphism(associations, hash)
        end
      end
    end
  end
end
