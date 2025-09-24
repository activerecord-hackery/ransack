# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module ColumnMethods

        def spatial(name, options = {})
          raise "You must set a type. For example: 't.spatial type: :st_point'" unless options[:type]
          column(name, options[:type], **options)
        end

        def geography(name, options = {})
          column(name, :geography, **options)
        end

        def geometry(name, options = {})
          column(name, :geometry, **options)
        end

        def geometry_collection(name, options = {})
          column(name, :geometry_collection, **options)
        end

        def line_string(name, options = {})
          column(name, :line_string, **options)
        end

        def multi_line_string(name, options = {})
          column(name, :multi_line_string, **options)
        end

        def multi_point(name, options = {})
          column(name, :multi_point, **options)
        end

        def multi_polygon(name, options = {})
          column(name, :multi_polygon, **options)
        end

        def st_point(name, options = {})
          column(name, :st_point, **options)
        end

        def st_polygon(name, options = {})
          column(name, :st_polygon, **options)
        end

        private
        def valid_column_definition_options
          super + [:srid, :has_z, :has_m, :geographic, :spatial_type]
        end
      end
    end

    PostgreSQL::Table.include PostGIS::ColumnMethods
  end
end
