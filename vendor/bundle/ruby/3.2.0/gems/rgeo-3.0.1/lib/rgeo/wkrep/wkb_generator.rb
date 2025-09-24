# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Well-known binary generator for RGeo
#
# -----------------------------------------------------------------------------

module RGeo
  module WKRep
    # This class provides the functionality of serializing a geometry as
    # WKB (well-known binary) format. You may also customize the
    # serializer to generate PostGIS EWKB extensions to the output, or to
    # follow the Simple Features Specification 1.2 extensions for Z and M
    # coordinates.
    #
    # To use this class, create an instance with the desired settings and
    # customizations, and call the generate method.
    #
    # === Configuration options
    #
    # The following options are recognized. These can be passed to the
    # constructor, or set on the object afterwards.
    #
    # [<tt>:type_format</tt>]
    #   The format for type codes. Possible values are <tt>:wkb11</tt>,
    #   indicating SFS 1.1 WKB (i.e. no Z or M values); <tt>:ewkb</tt>,
    #   indicating the PostGIS EWKB extensions (i.e. Z and M presence
    #   flagged by the two high bits of the type code, and support for
    #   embedded SRID); or <tt>:wkb12</tt> (indicating SFS 1.2 WKB
    #   (i.e. Z and M presence flagged by adding 1000 and/or 2000 to
    #   the type code.) Default is <tt>:wkb11</tt>.
    # [<tt>:emit_ewkb_srid</tt>]
    #   If true, embed the SRID in the toplevel geometry. Available only
    #   if <tt>:type_format</tt> is <tt>:ewkb</tt>. Default is false.
    # [<tt>:hex_format</tt>]
    #   If true, output a hex string instead of a byte string.
    #   Default is false.
    # [<tt>:little_endian</tt>]
    #   If true, output little endian (NDR) byte order. If false, output
    #   big endian (XDR), or network byte order. Default is false.
    class WKBGenerator
      # :stopdoc:
      TYPE_CODES = {
        Feature::Point => 1,
        Feature::LineString => 2,
        Feature::LinearRing => 2,
        Feature::Line => 2,
        Feature::Polygon => 3,
        Feature::MultiPoint => 4,
        Feature::MultiLineString => 5,
        Feature::MultiPolygon => 6,
        Feature::GeometryCollection => 7
      }.freeze
      # :startdoc:

      # Create and configure a WKB generator. See the WKBGenerator
      # documentation for the options that can be passed.

      def initialize(opts = {})
        @type_format = opts[:type_format] || :wkb11
        @emit_ewkb_srid = @type_format == :ewkb && opts[:emit_ewkb_srid]
        @hex_format = opts[:hex_format] ? true : false
        @little_endian = opts[:little_endian] ? true : false
      end

      # Returns the format for type codes. See WKBGenerator for details.
      attr_reader :type_format

      # Returns whether SRID is embedded. See WKBGenerator for details.
      def emit_ewkb_srid?
        @emit_ewkb_srid
      end

      # Returns whether output is converted to hex.
      # See WKBGenerator for details.
      def hex_format?
        @hex_format
      end

      # Returns whether output is little-endian (NDR).
      # See WKBGenerator for details.
      def little_endian?
        @little_endian
      end

      def properties
        {
          "type_format" => @type_format.to_s,
          "emit_ewkb_srid" => @emit_ewkb_srid,
          "hex_format" => @hex_format,
          "little_endian" => @little_endian
        }
      end

      # Generate and return the WKB format for the given geometry object,
      # according to the current settings.

      def generate(obj)
        factory = obj.factory
        if @type_format == :ewkb || @type_format == :wkb12
          has_z = factory.property(:has_z_coordinate)
          has_m = factory.property(:has_m_coordinate)
        else
          has_z = false
          has_m = false
        end
        result = Result.new(has_z, has_m)
        generate_feature(obj, result, toplevel: true)
        result.emit(@hex_format)
      end

      private

      class Result
        def initialize(has_z, has_m)
          @buffer = []
          @has_z = has_z
          @has_m = has_m
        end

        def <<(data)
          @buffer << data
        end

        def emit(hex_format)
          str = @buffer.join
          hex_format ? str.unpack1("H*") : str
        end

        def z?
          @has_z
        end

        def m?
          @has_m
        end
      end
      private_constant :Result

      def emit_byte(value, rval)
        rval << [value].pack("C")
      end

      def emit_integer(value, rval)
        rval << [value].pack(@little_endian ? "V" : "N")
      end

      def emit_doubles(array, rval)
        rval << array.pack(@little_endian ? "E*" : "G*")
      end

      def emit_line_string_coords(obj, rval)
        array = []
        obj.points.each { |pt| point_coords(pt, rval, array) }
        emit_integer(obj.num_points, rval)
        emit_doubles(array, rval)
      end

      def point_coords(obj, rval, array = [])
        array << obj.x
        array << obj.y
        array << obj.z if rval.z?
        array << obj.m if rval.m?
        array
      end

      def generate_feature(obj, rval, toplevel: false)
        emit_byte(@little_endian ? 1 : 0, rval)
        type = obj.geometry_type
        type_code = TYPE_CODES[type]
        raise Error::ParseError, "Unrecognized Geometry Type: #{type}" unless type_code
        emit_srid = false
        case @type_format
        when :ewkb
          type_code |= 0x80000000 if rval.z?
          type_code |= 0x40000000 if rval.m?
          if @emit_ewkb_srid && toplevel
            type_code |= 0x20000000
            emit_srid = true
          end
        when :wkb12
          type_code += 1000 if rval.z?
          type_code += 2000 if rval.m?
        end
        emit_integer(type_code, rval)
        emit_integer(obj.srid, rval) if emit_srid
        type_is_collection = [
          Feature::GeometryCollection,
          Feature::MultiPoint,
          Feature::MultiLineString,
          Feature::MultiPolygon
        ].include?(type)
        if type == Feature::Point
          emit_doubles(point_coords(obj, rval), rval)
        elsif type.subtype_of?(Feature::LineString)
          emit_line_string_coords(obj, rval)
        elsif type == Feature::Polygon
          exterior_ring = obj.exterior_ring
          if exterior_ring.empty?
            emit_integer(0, rval)
          else
            emit_integer(1 + obj.num_interior_rings, rval)
            emit_line_string_coords(exterior_ring, rval)
            obj.interior_rings.each { |r| emit_line_string_coords(r, rval) }
          end
        elsif type_is_collection
          emit_integer(obj.num_geometries, rval)
          obj.each { |g| generate_feature(g, rval) }
        end
      end
    end
  end
end
