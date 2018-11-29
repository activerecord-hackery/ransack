# active_record_5.2.1_ruby_2/join_dependency.rb

module Polyamorous
  module JoinDependencyExtensions
    # Replaces ActiveRecord::Associations::JoinDependency#build
    #
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
