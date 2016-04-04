module Ransack
  module Adapters

    # TODO: Refactor to remove conditionals

    def self.current_adapters
      @current_adapters ||= {
        :active_record => defined?(::ActiveRecord::Base),
        :mongoid => defined?(::Mongoid) && !defined?(::ActiveRecord::Base)
      }
    end

    def self.require_constants
      if current_adapters[:mongoid]
        require 'ransack/adapters/mongoid/ransack/constants'
      end

      if current_adapters[:active_record]
        require 'ransack/adapters/active_record/ransack/constants'
      end
    end

    def self.require_adapter
      if current_adapters[:active_record]
        require 'ransack/adapters/active_record/ransack/translate'
        require 'ransack/adapters/active_record'
      end

      if current_adapters[:mongoid]
        require 'ransack/adapters/mongoid/ransack/translate'
        require 'ransack/adapters/mongoid'
      end
    end

    def self.require_context
      if current_adapters[:active_record]
        require 'ransack/adapters/active_record/ransack/visitor'
      end

      if current_adapters[:mongoid]
        require 'ransack/adapters/mongoid/ransack/visitor'
      end
    end

    def self.require_nodes
      if current_adapters[:active_record]
        require 'ransack/adapters/active_record/ransack/nodes/condition'
      end

      if current_adapters[:mongoid]
        require 'ransack/adapters/mongoid/ransack/nodes/condition'
      end
    end

    def self.require_search
      if current_adapters[:active_record]
        require 'ransack/adapters/active_record/ransack/context'
      end

      if current_adapters[:mongoid]
        require 'ransack/adapters/mongoid/ransack/context'
      end
    end
  end
end
