# frozen_string_literal: true

module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGIS  # :nodoc:
      class SpatialColumn < ConnectionAdapters::PostgreSQLColumn  # :nodoc:
        # sql_type examples:
        #   "Geometry(Point,4326)"
        #   "Geography(Point,4326)"
        def initialize(name, default, sql_type_metadata = nil, null = true,
                       default_function = nil, collation: nil, comment: nil,
                       serial: nil, generated: nil, spatial: nil, identity: nil)
          @sql_type_metadata = sql_type_metadata
          @geographic = !!(sql_type_metadata.sql_type =~ /geography\(/i)
          if spatial
            # This case comes from an entry in the geometry_columns table
            set_geometric_type_from_name(spatial[:type])
            @srid = spatial[:srid].to_i
            @has_z = !!spatial[:has_z]
            @has_m = !!spatial[:has_m]
          elsif @geographic
            # Geographic type information is embedded in the SQL type
            @srid = 4326
            @has_z = @has_m = false
            build_from_sql_type(sql_type_metadata.sql_type)
          elsif sql_type =~ /geography|geometry|point|linestring|polygon/i
            build_from_sql_type(sql_type_metadata.sql_type)
          elsif sql_type_metadata.sql_type =~ /geography|geometry|point|linestring|polygon/i
            # A geometry column with no geometry_columns entry.
            # @geometric_type = geo_type_from_sql_type(sql_type)
            build_from_sql_type(sql_type_metadata.sql_type)
          end
          super(name, default, sql_type_metadata, null, default_function,
                collation: collation, comment: comment, serial: serial, generated: generated, identity: identity)
          if spatial? && @srid
            @limit = { srid: @srid, type: to_type_name(geometric_type) }
            @limit[:has_z] = true if @has_z
            @limit[:has_m] = true if @has_m
            @limit[:geographic] = true if @geographic
          end
        end

        attr_reader :geographic,
                    :geometric_type,
                    :has_m,
                    :has_z,
                    :srid

        alias :geographic? :geographic
        alias :has_z? :has_z
        alias :has_m? :has_m

        def limit
          spatial? ? @limit : super
        end

        def spatial?
          %i[geometry geography].include?(@sql_type_metadata.type)
        end

        private

        def set_geometric_type_from_name(name)
          @geometric_type = RGeo::ActiveRecord.geometric_type_from_name(name) || RGeo::Feature::Geometry
        end

        def build_from_sql_type(sql_type)
          geo_type, @srid, @has_z, @has_m, @geographic = OID::Spatial.parse_sql_type(sql_type)
          set_geometric_type_from_name(geo_type)
        end

        def to_type_name(geometric_type)
          name = geometric_type.type_name.underscore
          case name
          when "point"
            "st_point"
          when "polygon"
            "st_polygon"
          else
            name
          end
        end
      end
    end
  end
end
