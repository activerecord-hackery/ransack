# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module Type
        # Look for :postgis types first, then check for :postgresql
        # types to simulate a kind of Type inheritance.
        def lookup(*args, adapter: current_adapter_name, **kwargs)
          super(*args, adapter: adapter, **kwargs)
        rescue ArgumentError => e
          raise e unless current_adapter_name == :postgis

          super(*args, adapter: :postgresql, **kwargs)
        end
      end
    end
  end

  # Type uses `class << self` syntax so we have to prepend to the singleton_class
  Type.singleton_class.prepend(ActiveRecord::ConnectionAdapters::PostGIS::Type)
end
