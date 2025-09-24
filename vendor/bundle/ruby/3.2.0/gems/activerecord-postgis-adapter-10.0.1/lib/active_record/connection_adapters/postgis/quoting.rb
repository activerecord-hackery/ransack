# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module Quoting
        def type_cast(value)
          case value
          when RGeo::Feature::Instance
            value.to_s
          else
            super
          end
        end
      end
    end
  end
end
