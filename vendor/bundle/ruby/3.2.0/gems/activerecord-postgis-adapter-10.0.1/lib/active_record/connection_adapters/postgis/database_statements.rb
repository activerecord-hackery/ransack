# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module PostGIS
      module DatabaseStatements
        def truncate_tables(*table_names)
          table_names -= ["spatial_ref_sys"]
          super(*table_names)
        end
      end
    end
  end
end
