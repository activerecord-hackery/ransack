# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        # OID used to represent geometry/geography database types and attributes.
        #
        # Accepts `geo_type`, `srid`, `has_z`, `has_m`, and `geographic` as parameters.
        # Responsible for parsing sql_types returned from the database and WKT features.
        class Spatial < Type::Value
          def initialize(geo_type: "geometry", srid: 0, has_z: false, has_m: false, geographic: false)
            @geo_type = geo_type
            @srid = srid
            @has_z = has_z
            @has_m = has_m
            @geographic = geographic
          end

          # sql_type: geometry, geometry(Point), geometry(Point,4326), ...
          #
          # returns [geo_type, srid, has_z, has_m]
          #   geo_type: geography, geometry, point, line_string, polygon, ...
          #   srid:     1234
          #   has_z:    false
          #   has_m:    false
          def self.parse_sql_type(sql_type)
            geo_type = nil
            srid = 0
            has_z = false
            has_m = false

            if sql_type =~ /(geography|geometry)\((.*)\)$/i
              # geometry(Point)
              # geometry(Point,4326)
              params = Regexp.last_match(2).split(",")
              if params.first =~ /([a-z]+[^zm])(z?)(m?)/i
                has_z = Regexp.last_match(2).length > 0
                has_m = Regexp.last_match(3).length > 0
                geo_type = Regexp.last_match(1)
              end
              if params.last =~ /(\d+)/
                srid = Regexp.last_match(1).to_i
              end
            else
              # geometry
              # otherType(a,b)
              geo_type = sql_type
            end
            geographic = sql_type.match?(/geography/)

            [geo_type, srid, has_z, has_m, geographic]
          end

          def spatial_factory
            @spatial_factory ||=
              RGeo::ActiveRecord::SpatialFactoryStore.instance.factory(
                factory_attrs
              )
          end

          def spatial?
            true
          end

          def type
            @geographic ? :geography : :geometry
          end

          # support setting an RGeo object or a WKT string
          def serialize(value)
            return if value.nil?
            geo_value = cast_value(value)

            # TODO - only valid types should be allowed
            # e.g. linestring is not valid for point column
            # raise "maybe should raise" unless RGeo::Feature::Geometry.check_type(geo_value)

            RGeo::WKRep::WKBGenerator.new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true)
                                     .generate(geo_value)
          end

          private

          def cast_value(value)
            return if value.nil?
            String === value ? parse_wkt(value) : value
          end

          # convert WKT string into RGeo object
          def parse_wkt(string)
            wkt_parser(string).parse(string)
          rescue RGeo::Error::ParseError
            nil
          end

          def binary_string?(string)
            string[0] == "\x00" || string[0] == "\x01" || string[0, 4] =~ /[0-9a-fA-F]{4}/
          end

          def wkt_parser(string)
            if binary_string?(string)
              RGeo::WKRep::WKBParser.new(spatial_factory, support_ewkb: true, default_srid: @srid)
            else
              RGeo::WKRep::WKTParser.new(spatial_factory, support_ewkt: true, default_srid: @srid)
            end
          end

          def factory_attrs
            {
              geo_type: @geo_type.underscore,
              has_m: @has_m,
              has_z: @has_z,
              srid: @srid,
              sql_type: type.to_s
            }
          end
        end
      end
    end
  end
end
