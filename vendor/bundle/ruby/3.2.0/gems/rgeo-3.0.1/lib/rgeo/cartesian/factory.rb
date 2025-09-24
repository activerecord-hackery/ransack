# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Geographic data factory implementation
#
# -----------------------------------------------------------------------------

module RGeo
  module Cartesian
    # This class implements the factory for the simple cartesian
    # implementation.
    class Factory
      include Feature::Factory::Instance
      include ImplHelper::Utils

      attr_reader :coordinate_dimension, :spatial_dimension

      # Returns the SRID.
      attr_reader :srid

      # See RGeo::Feature::Factory#coord_sys
      attr_reader :coord_sys

      # Create a new simple cartesian factory.
      #
      # See RGeo::Cartesian.simple_factory for a list of supported options.

      def initialize(opts = {})
        @has_z = opts[:has_z_coordinate] ? true : false
        @has_m = opts[:has_m_coordinate] ? true : false
        @coordinate_dimension = 2
        @coordinate_dimension += 1 if @has_z
        @coordinate_dimension += 1 if @has_m
        @spatial_dimension = @has_z ? 3 : 2

        coord_sys_info = ImplHelper::Utils.setup_coord_sys(opts[:srid], opts[:coord_sys], opts[:coord_sys_class])
        @coord_sys = coord_sys_info[:coord_sys]
        @srid = coord_sys_info[:srid]

        @buffer_resolution = opts[:buffer_resolution].to_i
        @buffer_resolution = 1 if @buffer_resolution < 1

        wkt_generator = opts[:wkt_generator]
        @wkt_generator =
          case wkt_generator
          when Hash
            WKRep::WKTGenerator.new(wkt_generator)
          else
            WKRep::WKTGenerator.new(convert_case: :upper)
          end
        wkb_generator = opts[:wkb_generator]
        @wkb_generator =
          case wkb_generator
          when Hash
            WKRep::WKBGenerator.new(wkb_generator)
          else
            WKRep::WKBGenerator.new
          end
        wkt_parser = opts[:wkt_parser]
        @wkt_parser =
          case wkt_parser
          when Hash
            WKRep::WKTParser.new(self, wkt_parser)
          else
            WKRep::WKTParser.new(self)
          end
        wkb_parser = opts[:wkb_parser]
        @wkb_parser =
          case wkb_parser
          when Hash
            WKRep::WKBParser.new(self, wkb_parser)
          else
            WKRep::WKBParser.new(self)
          end
      end

      # Equivalence test.

      def eql?(other)
        other.is_a?(self.class) && @srid == other.srid &&
          @has_z == other.property(:has_z_coordinate) &&
          @has_m == other.property(:has_m_coordinate) &&
          @coord_sys == other.instance_variable_get(:@coord_sys)
      end
      alias == eql?

      # Standard hash code

      def hash
        @hash ||= [@srid, @has_z, @has_m, @coord_sys].hash
      end

      # Marshal support

      def marshal_dump # :nodoc:
        hash_ = {
          "hasz" => @has_z,
          "hasm" => @has_m,
          "srid" => @srid,
          "wktg" => @wkt_generator.properties,
          "wkbg" => @wkb_generator.properties,
          "wktp" => @wkt_parser.properties,
          "wkbp" => @wkb_parser.properties,
          "bufr" => @buffer_resolution
        }
        hash_["cs"] = @coord_sys.to_wkt if @coord_sys
        hash_
      end

      def marshal_load(data) # :nodoc:
        cs_class = CoordSys::CONFIG.default_coord_sys_class
        coord_sys = data["cs"]&.then { |cs| cs_class.create_from_wkt(cs) }

        initialize(
          has_z_coordinate: data["hasz"],
          has_m_coordinate: data["hasm"],
          srid: data["srid"],
          wkt_generator: symbolize_hash(data["wktg"]),
          wkb_generator: symbolize_hash(data["wkbg"]),
          wkt_parser: symbolize_hash(data["wktp"]),
          wkb_parser: symbolize_hash(data["wkbp"]),
          buffer_resolution: data["bufr"],
          coord_sys: coord_sys
        )
      end

      # Psych support

      def encode_with(coder) # :nodoc:
        coder["has_z_coordinate"] = @has_z
        coder["has_m_coordinate"] = @has_m
        coder["srid"] = @srid
        coder["buffer_resolution"] = @buffer_resolution
        coder["wkt_generator"] = @wkt_generator.properties
        coder["wkb_generator"] = @wkb_generator.properties
        coder["wkt_parser"] = @wkt_parser.properties
        coder["wkb_parser"] = @wkb_parser.properties
        coder["coord_sys"] = @coord_sys.to_wkt if @coord_sys
      end

      def init_with(coder) # :nodoc:
        cs_class = CoordSys::CONFIG.default_coord_sys_class
        coord_sys = coder["cs"]&.then { |cs| cs_class.create_from_wkt(cs) }

        initialize(
          has_z_coordinate: coder["has_z_coordinate"],
          has_m_coordinate: coder["has_m_coordinate"],
          srid: coder["srid"],
          wkt_generator: symbolize_hash(coder["wkt_generator"]),
          wkb_generator: symbolize_hash(coder["wkb_generator"]),
          wkt_parser: symbolize_hash(coder["wkt_parser"]),
          wkb_parser: symbolize_hash(coder["wkb_parser"]),
          buffer_resolution: coder["buffer_resolution"],
          coord_sys: coord_sys
        )
      end

      # See RGeo::Feature::Factory#property

      def property(name)
        case name
        when :has_z_coordinate
          @has_z
        when :has_m_coordinate
          @has_m
        when :buffer_resolution
          @buffer_resolution
        when :is_cartesian
          true
        end
      end

      # See RGeo::Feature::Factory#parse_wkt

      def parse_wkt(str)
        @wkt_parser.parse(str)
      end

      # See RGeo::Feature::Factory#parse_wkb

      def parse_wkb(str)
        @wkb_parser.parse(str)
      end

      # See RGeo::Feature::Factory#point

      def point(x, y, *extra)
        PointImpl.new(self, x, y, *extra)
      end

      # See RGeo::Feature::Factory#line_string

      def line_string(points)
        LineStringImpl.new(self, points)
      end

      # See RGeo::Feature::Factory#line

      def line(start, stop)
        LineImpl.new(self, start, stop)
      end

      # See RGeo::Feature::Factory#linear_ring

      def linear_ring(points)
        LinearRingImpl.new(self, points)
      end

      # See RGeo::Feature::Factory#polygon

      def polygon(outer_ring, inner_rings = nil)
        PolygonImpl.new(self, outer_ring, inner_rings)
      end

      # See RGeo::Feature::Factory#collection

      def collection(elems)
        GeometryCollectionImpl.new(self, elems)
      end

      # See RGeo::Feature::Factory#multi_point

      def multi_point(elems)
        MultiPointImpl.new(self, elems)
      end

      # See RGeo::Feature::Factory#multi_line_string

      def multi_line_string(elems)
        MultiLineStringImpl.new(self, elems)
      end

      # See RGeo::Feature::Factory#multi_polygon

      def multi_polygon(elems)
        MultiPolygonImpl.new(self, elems)
      end

      def generate_wkt(obj)
        @wkt_generator.generate(obj)
      end

      def generate_wkb(obj)
        @wkb_generator.generate(obj)
      end

      def marshal_wkb_generator
        @marshal_wkb_generator ||= RGeo::WKRep::WKBGenerator.new(type_format: :wkb12)
      end

      def marshal_wkb_parser
        @marshal_wkb_parser ||= RGeo::WKRep::WKBParser.new(self, support_wkb12: true)
      end

      def psych_wkt_generator
        @psych_wkt_generator ||= RGeo::WKRep::WKTGenerator.new(tag_format: :wkt12)
      end

      def psych_wkt_parser
        @psych_wkt_parser ||= RGeo::WKRep::WKTParser.new(self, support_wkt12: true, support_ewkt: true)
      end
    end
  end
end
