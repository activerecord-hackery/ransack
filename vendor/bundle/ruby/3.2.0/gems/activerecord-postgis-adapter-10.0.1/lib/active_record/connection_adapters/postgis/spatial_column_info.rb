# frozen_string_literal: true

module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGIS
      # Do spatial sql queries for column info and memoize that info.
      class SpatialColumnInfo
        def initialize(adapter, table_name)
          @adapter = adapter
          @table_name = table_name
        end

        def all
          info = @adapter.query(
            "SELECT f_geometry_column,coord_dimension,srid,type FROM geometry_columns WHERE f_table_name='#{@table_name}'"
          )
          result = {}
          info.each do |row|
            name = row[0]
            type = row[3]
            dimension = row[1].to_i
            has_m = !!(type =~ /m$/i)
            type.sub!(/m$/, "")
            has_z = dimension > 3 || (dimension == 3 && !has_m)
            result[name] = {
              dimension: dimension,
              has_m:     has_m,
              has_z:     has_z,
              name:      name,
              srid:      row[2].to_i,
              type:      type,
            }
          end
          result
        end

        # do not query the database for non-spatial columns/tables
        def get(column_name, type)
          return unless PostGISAdapter.spatial_column_options(type.to_sym)
          @spatial_column_info ||= all
          @spatial_column_info[column_name]
        end
      end
    end
  end
end
