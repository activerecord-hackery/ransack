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

      end
    end
  end
end