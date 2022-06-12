module Ransack
  module Adapters

    def self.object_mapper
      @object_mapper ||= ActiveRecordAdapter.new
    end

    class ActiveRecordAdapter
      def require_adapter
        require 'ransack/adapters/active_record/ransack/translate'
        require 'ransack/adapters/active_record'
      end

      def require_context
        require 'ransack/adapters/active_record/ransack/visitor'
      end

      def require_nodes
        require 'ransack/adapters/active_record/ransack/nodes/condition'
      end

      def require_search
        require 'ransack/adapters/active_record/ransack/context'
      end
    end
  end
end
