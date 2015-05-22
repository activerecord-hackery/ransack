module Ransack
  module Adapters

    def self.current_adapters
      @current_adapters ||= {
        :active_record => defined?(::ActiveRecord::Base),
        :mongoid => defined?(::Mongoid) && !defined?(::ActiveRecord::Base)
      }
    end
    def self.require_constants
      require 'ransack/adapters/mongoid/ransack/constants' if current_adapters[:mongoid]
      require 'ransack/adapters/active_record/ransack/constants' if current_adapters[:active_record]
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
      require 'ransack/adapters/active_record/ransack/visitor' if current_adapters[:active_record]
      require 'ransack/adapters/mongoid/ransack/visitor' if current_adapters[:mongoid]
    end

    def self.require_nodes
      require 'ransack/adapters/active_record/ransack/nodes/condition' if current_adapters[:active_record]
      require 'ransack/adapters/mongoid/ransack/nodes/condition' if current_adapters[:mongoid]
    end

    def self.require_search
      require 'ransack/adapters/active_record/ransack/context' if current_adapters[:active_record]
      require 'ransack/adapters/mongoid/ransack/context' if current_adapters[:mongoid]
    end
  end
end
