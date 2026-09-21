module Ransack
  module ActiveRecord
    # Anything that can be placed in the association tree handed to
    # JoinDependency. Active Record's own tree is built from symbols and
    # hashes; a TreeNode adds itself to that tree however it likes, which is
    # how a Join carries its join type and polymorphic class through.
    module TreeNode
      def add_to_tree(hash)
        raise NotImplementedError
      end
    end
  end
end
