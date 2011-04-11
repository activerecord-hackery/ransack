module Ransack
  module Adapters
    module ActiveRecord
      module Base

        def self.extended(base)
          alias :search :ransack unless base.method_defined? :search
        end

        def ransack(params = {})
          Search.new(self, params)
        end

        def ransacker(name, opts = {}, &block)
          unless method_defined?(:_ransackers)
            class_attribute :_ransackers
            self._ransackers ||= {}
          end

          opts[:type] ||= :string
          opts[:args] ||= [:parent]
          opts[:callable] ||= block || (method(name) if method_defined?(name)) || proc {|parent| parent.table[name]}

          _ransackers[name.to_s] = opts
        end

      end
    end
  end
end