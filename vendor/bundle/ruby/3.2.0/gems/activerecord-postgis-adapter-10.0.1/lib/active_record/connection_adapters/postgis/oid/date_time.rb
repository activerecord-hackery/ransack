# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        module DateTime
          protected

          # Uses PostGIS instead of PostgreSQLAdapter
          def real_type_unless_aliased(real_type)
            ActiveRecord::ConnectionAdapters::PostGISAdapter.datetime_type == real_type ? :datetime : real_type
          end
        end

        PostgreSQL::OID::DateTime.prepend(DateTime)
      end
    end
  end
end
