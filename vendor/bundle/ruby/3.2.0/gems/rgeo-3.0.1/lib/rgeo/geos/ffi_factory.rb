# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# FFI-GEOS factory implementation
#
# -----------------------------------------------------------------------------

module RGeo
  module Geos
    # This the FFI-GEOS implementation of RGeo::Feature::Factory.
    class FFIFactory
      include Feature::Factory::Instance
      include ImplHelper::Utils

      attr_reader :coordinate_dimension, :spatial_dimension, :_has_3d, :_auto_prepare

      # Returns the SRID of geometries created by this factory.
      attr_reader :srid

      # Returns the resolution used by buffer calculations on geometries
      # created by this factory
      attr_reader :buffer_resolution

      # See RGeo::Feature::Factory#coord_sys
      attr_reader :coord_sys

      # Create a new factory. Returns nil if the FFI-GEOS implementation
      # is not supported.
      #
      # See RGeo::Geos.factory for a list of supported options.

      def initialize(opts = {})
        @has_z = opts[:has_z_coordinate] ? true : false
        @has_m = opts[:has_m_coordinate] ? true : false

        if @has_z && @has_m
          raise Error::UnsupportedOperation, "GEOS cannot support both Z and M coordinates at the same time."
        end

        @coordinate_dimension = 2
        @coordinate_dimension += 1 if @has_z
        @coordinate_dimension += 1 if @has_m
        @spatial_dimension = @has_z ? 3 : 2

        @_has_3d = @has_z || @has_m
        @buffer_resolution = opts[:buffer_resolution].to_i
        @buffer_resolution = 1 if @buffer_resolution < 1
        @_auto_prepare = opts[:auto_prepare] != :disabled

        # Interpret the generator options
        wkt_generator = opts[:wkt_generator]
        case wkt_generator
        when Hash
          @wkt_generator = WKRep::WKTGenerator.new(wkt_generator)
          @wkt_writer = nil
        else
          @wkt_writer = ::Geos::WktWriter.new
          @wkt_writer.output_dimensions = 2
          @wkt_writer.trim = true
          @wkt_generator = nil
        end
        wkb_generator = opts[:wkb_generator]
        case wkb_generator
        when Hash
          @wkb_generator = WKRep::WKBGenerator.new(wkb_generator)
          @wkb_writer = nil
        else
          @wkb_writer = ::Geos::WkbWriter.new
          @wkb_writer.output_dimensions = 2
          @wkb_generator = nil
        end

        # Coordinate system (srid and coord_sys)
        coord_sys_info = ImplHelper::Utils.setup_coord_sys(opts[:srid], opts[:coord_sys], opts[:coord_sys_class])
        @srid = coord_sys_info[:srid]
        @coord_sys = coord_sys_info[:coord_sys]

        # Interpret parser options
        wkt_parser = opts[:wkt_parser]
        case wkt_parser
        when Hash
          @wkt_parser = WKRep::WKTParser.new(self, wkt_parser)
          @wkt_reader = nil
        else
          @wkt_reader = ::Geos::WktReader.new
          @wkt_parser = nil
        end
        wkb_parser = opts[:wkb_parser]
        case wkb_parser
        when Hash
          @wkb_parser = WKRep::WKBParser.new(self, wkb_parser)
          @wkb_reader = nil
        else
          @wkb_reader = ::Geos::WkbReader.new
          @wkb_parser = nil
        end
      end

      # Standard object inspection output

      def inspect
        "#<#{self.class}:0x#{object_id.to_s(16)} srid=#{srid}>"
      end

      # Factory equivalence test.

      def eql?(other)
        other.is_a?(self.class) && @srid == other.srid &&
          @has_z == other.property(:has_z_coordinate) &&
          @has_m == other.property(:has_m_coordinate) &&
          @buffer_resolution == other.property(:buffer_resolution) &&
          @coord_sys.eql?(other.coord_sys)
      end
      alias == eql?

      # Standard hash code

      def hash
        @hash ||= [@srid, @has_z, @has_m, @buffer_resolution, @coord_sys].hash
      end

      # Marshal support

      def marshal_dump # :nodoc:
        hash = {
          "hasz" => @has_z,
          "hasm" => @has_m,
          "srid" => @srid,
          "bufr" => @buffer_resolution,
          "wktg" => @wkt_generator&.properties,
          "wkbg" => @wkb_generator&.properties,
          "wktp" => @wkt_parser&.properties,
          "wkbp" => @wkb_parser&.properties,
          "apre" => @_auto_prepare
        }
        hash["cs"] = @coord_sys.to_wkt if @coord_sys
        hash
      end

      def marshal_load(data) # :nodoc:
        cs_class = CoordSys::CONFIG.default_coord_sys_class
        coord_sys = data["cs"]&.then { |cs| cs_class.create_from_wkt(cs) }

        initialize(
          has_z_coordinate: data["hasz"],
          has_m_coordinate: data["hasm"],
          srid: data["srid"],
          buffer_resolution: data["bufr"],
          wkt_generator: data["wktg"] && symbolize_hash(data["wktg"]),
          wkb_generator: data["wkbg"] && symbolize_hash(data["wkbg"]),
          wkt_parser: data["wktp"] && symbolize_hash(data["wktp"]),
          wkb_parser: data["wkbp"] && symbolize_hash(data["wkbp"]),
          auto_prepare: (data["apre"] ? :simple : :disabled),
          coord_sys: coord_sys
        )
      end

      # Psych support

      def encode_with(coder) # :nodoc:
        coder["has_z_coordinate"] = @has_z
        coder["has_m_coordinate"] = @has_m
        coder["srid"] = @srid
        coder["buffer_resolution"] = @buffer_resolution
        coder["wkt_generator"] = @wkt_generator&.properties
        coder["wkb_generator"] = @wkb_generator&.properties
        coder["wkt_parser"] = @wkt_parser&.properties
        coder["wkb_parser"] = @wkb_parser&.properties
        coder["auto_prepare"] = @_auto_prepare ? "simple" : "disabled"
        coder["coord_sys"] = @coord_sys.to_wkt if @coord_sys
      end

      def init_with(coder) # :nodoc:
        cs_class = CoordSys::CONFIG.default_coord_sys_class
        coord_sys = coder["cs"]&.then { |cs| cs_class.create_from_wkt(cs) }

        initialize(
          has_z_coordinate: coder["has_z_coordinate"],
          has_m_coordinate: coder["has_m_coordinate"],
          srid: coder["srid"],
          buffer_resolution: coder["buffer_resolution"],
          wkt_generator: coder["wkt_generator"] && symbolize_hash(coder["wkt_generator"]),
          wkb_generator: coder["wkb_generator"] && symbolize_hash(coder["wkb_generator"]),
          wkt_parser: coder["wkt_parser"] && symbolize_hash(coder["wkt_parser"]),
          wkb_parser: coder["wkb_parser"] && symbolize_hash(coder["wkb_parser"]),
          auto_prepare: coder["auto_prepare"] == "disabled" ? :disabled : :simple,
          coord_sys: coord_sys
        )
      end

      # See RGeo::Feature::Factory#property
      def property(name_)
        case name_
        when :has_z_coordinate
          @has_z
        when :has_m_coordinate
          @has_m
        when :is_cartesian
          true
        when :buffer_resolution
          @buffer_resolution
        when :auto_prepare
          @_auto_prepare ? :simple : :disabled
        end
      end

      # See RGeo::Feature::Factory#parse_wkt
      def parse_wkt(str)
        if @wkt_reader
          begin
            wrap_fg_geom(@wkt_reader.read(str), nil)
          rescue ::Geos::WktReader::ParseError => e
            raise RGeo::Error::ParseError, e.message.partition(":").last
          end
        else
          @wkt_parser.parse(str)
        end
      end

      # See RGeo::Feature::Factory#parse_wkb

      def parse_wkb(str)
        if @wkb_reader
          begin
            meth = str[0].match?(/[0-9a-fA-F]/) ? :read_hex : :read
            wrap_fg_geom(@wkb_reader.public_send(meth, str), nil)
          rescue ::Geos::WkbReader::ParseError => e
            raise RGeo::Error::ParseError, e.message.partition(":").last
          end
        else
          @wkb_parser.parse(str)
        end
      end

      # See RGeo::Feature::Factory#point

      def point(x, y, z = 0)
        cs = ::Geos::CoordinateSequence.new(1, 3)
        cs.set_x(0, x)
        cs.set_y(0, y)
        cs.set_z(0, z)
        FFIPointImpl.new(self, ::Geos::Utils.create_point(cs), nil)
      end

      # See RGeo::Feature::Factory#line_string

      def line_string(points)
        points = points.to_a unless points.is_a?(Array)
        size = points.size
        raise(Error::InvalidGeometry, "Must have more than one point") if size == 1
        cs = ::Geos::CoordinateSequence.new(size, 3)
        points.each_with_index do |p, i|
          raise(Error::InvalidGeometry, "Invalid point: #{p}") unless RGeo::Feature::Point.check_type(p)
          cs.set_x(i, p.x)
          cs.set_y(i, p.y)
          if @has_z
            cs.set_z(i, p.z)
          elsif @has_m
            cs.set_z(i, p.m)
          end
        end
        FFILineStringImpl.new(self, ::Geos::Utils.create_line_string(cs), nil)
      end

      # See RGeo::Feature::Factory#line

      def line(start, stop)
        return unless RGeo::Feature::Point.check_type(start) &&
          RGeo::Feature::Point.check_type(stop)
        cs = ::Geos::CoordinateSequence.new(2, 3)
        cs.set_x(0, start.x)
        cs.set_x(1, stop.x)
        cs.set_y(0, start.y)
        cs.set_y(1, stop.y)
        if @has_z
          cs.set_z(0, start.z)
          cs.set_z(1, stop.z)
        elsif @has_m
          cs.set_z(0, start.m)
          cs.set_z(1, stop.m)
        end
        FFILineImpl.new(self, ::Geos::Utils.create_line_string(cs), nil)
      end

      # See RGeo::Feature::Factory#linear_ring

      def linear_ring(points)
        points = points.to_a unless points.is_a?(Array)
        fg_geom = create_fg_linear_ring(points)
        FFILinearRingImpl.new(self, fg_geom, nil)
      end

      # See RGeo::Feature::Factory#polygon

      def polygon(outer_ring, inner_rings = nil)
        inner_rings = inner_rings.to_a unless inner_rings.is_a?(Array)
        return unless RGeo::Feature::LineString.check_type(outer_ring)
        outer_ring = create_fg_linear_ring(outer_ring.points)
        return unless inner_rings.all? { |r| RGeo::Feature::LineString.check_type(r) }
        inner_rings = inner_rings.map { |r| create_fg_linear_ring(r.points) }
        inner_rings.compact!
        fg_geom = ::Geos::Utils.create_polygon(outer_ring, *inner_rings)
        FFIPolygonImpl.new(self, fg_geom, nil)
      end

      # See RGeo::Feature::Factory#collection

      def collection(elems)
        elems = elems.to_a unless elems.is_a?(Array)
        klasses = []
        my_fg_geoms = []
        elems.each do |elem|
          k = elem._klasses if elem.factory.is_a?(FFIFactory)
          elem = RGeo::Feature.cast(elem, self, :force_new, :keep_subtype)
          if elem
            klasses << (k || elem.class)
            my_fg_geoms << elem.detach_fg_geom
          end
        end
        fg_geom = ::Geos::Utils.create_collection(::Geos::GeomTypes::GEOS_GEOMETRYCOLLECTION, my_fg_geoms)
        FFIGeometryCollectionImpl.new(self, fg_geom, klasses)
      end

      # See RGeo::Feature::Factory#multi_point

      def multi_point(elems)
        elems = elems.to_a unless elems.is_a?(Array)
        elems = elems.map do |elem|
          RGeo::Feature.cast(
            elem,
            self,
            RGeo::Feature::Point,
            :force_new,
            :keep_subtype
          )
        end
        return unless elems.all?
        elems = elems.map(&:detach_fg_geom)
        klasses = Array.new(elems.size, FFIPointImpl)
        fg_geom = ::Geos::Utils.create_collection(::Geos::GeomTypes::GEOS_MULTIPOINT, elems)
        FFIMultiPointImpl.new(self, fg_geom, klasses)
      end

      # See RGeo::Feature::Factory#multi_line_string

      def multi_line_string(elems)
        elems = elems.to_a unless elems.is_a?(Array)
        klasses = []
        elems = elems.map do |elem|
          elem = RGeo::Feature.cast(elem, self, RGeo::Feature::LineString, :force_new, :keep_subtype)
          raise(RGeo::Error::InvalidGeometry, "Parse error") unless elem
          klasses << elem.class
          elem.detach_fg_geom
        end
        fg_geom = ::Geos::Utils.create_collection(::Geos::GeomTypes::GEOS_MULTILINESTRING, elems)
        FFIMultiLineStringImpl.new(self, fg_geom, klasses)
      end

      # See RGeo::Feature::Factory#multi_polygon

      def multi_polygon(elems)
        elems = elems.to_a unless elems.is_a?(Array)
        elems = elems.map do |elem|
          elem = RGeo::Feature.cast(elem, self, RGeo::Feature::Polygon, :force_new, :keep_subtype)
          raise(RGeo::Error::InvalidGeometry, "Could not cast to polygon: #{elem}") unless elem
          elem.detach_fg_geom
        end
        klasses = Array.new(elems.size, FFIPolygonImpl)
        fg_geom = ::Geos::Utils.create_collection(::Geos::GeomTypes::GEOS_MULTIPOLYGON, elems)
        FFIMultiPolygonImpl.new(self, fg_geom, klasses)
      end

      # See RGeo::Feature::Factory#override_cast

      def override_cast(_original, _ntype, _flags)
        false
        # TODO
      end

      # Create a feature that wraps the given ffi-geos geometry object
      def wrap_fg_geom(fg_geom, klass = nil)
        klasses = nil

        # We don't allow "empty" points, so replace such objects with
        # an empty collection.
        if fg_geom.type_id == ::Geos::GeomTypes::GEOS_POINT && fg_geom.empty?
          fg_geom = ::Geos::Utils.create_geometry_collection
          klass = FFIGeometryCollectionImpl
        end

        unless klass.is_a?(::Class)
          is_collection = false
          case fg_geom.type_id
          when ::Geos::GeomTypes::GEOS_POINT
            inferred_klass = FFIPointImpl
          when ::Geos::GeomTypes::GEOS_MULTIPOINT
            inferred_klass = FFIMultiPointImpl
            is_collection = true
          when ::Geos::GeomTypes::GEOS_LINESTRING
            inferred_klass = FFILineStringImpl
          when ::Geos::GeomTypes::GEOS_LINEARRING
            inferred_klass = FFILinearRingImpl
          when ::Geos::GeomTypes::GEOS_MULTILINESTRING
            inferred_klass = FFIMultiLineStringImpl
            is_collection = true
          when ::Geos::GeomTypes::GEOS_POLYGON
            inferred_klass = FFIPolygonImpl
          when ::Geos::GeomTypes::GEOS_MULTIPOLYGON
            inferred_klass = FFIMultiPolygonImpl
            is_collection = true
          when ::Geos::GeomTypes::GEOS_GEOMETRYCOLLECTION
            inferred_klass = FFIGeometryCollectionImpl
            is_collection = true
          else
            inferred_klass = FFIGeometryImpl
          end
          klasses = klass if is_collection && klass.is_a?(Array)
          klass = inferred_klass
        end
        klass.new(self, fg_geom, klasses)
      end

      def convert_to_fg_geometry(obj, type = nil)
        obj = Feature.cast(obj, self, type) if type && obj.factory != self

        geom = obj&.fg_geom
        raise RGeo::Error::InvalidGeometry, "Unable to cast the geometry to the FFI Factory" if geom.nil?

        geom
      end

      def generate_wkt(geom)
        if @wkt_writer
          @wkt_writer.write(geom.fg_geom)
        else
          @wkt_generator.generate(geom)
        end
      end

      def generate_wkb(geom)
        if @wkb_writer
          @wkb_writer.write(geom.fg_geom)
        else
          @wkb_generator.generate(geom)
        end
      end

      def write_for_marshal(geom)
        if Utils.ffi_supports_set_output_dimension || !@_has_3d
          wkb_writer = ::Geos::WkbWriter.new
          wkb_writer.output_dimensions = 2
          wkb_writer.output_dimensions = 3 if @_has_3d
          wkb_writer.write(geom.fg_geom)
        else
          Utils.marshal_wkb_generator.generate(geom)
        end
      end

      def read_for_marshal(str)
        ::Geos::WkbReader.new.read(str)
      end

      def write_for_psych(geom)
        if Utils.ffi_supports_set_output_dimension || !@_has_3d
          wkt_writer = ::Geos::WktWriter.new
          wkt_writer.output_dimensions = 2
          wkt_writer.trim = true
          wkt_writer.output_dimensions = 3 if @_has_3d
          wkt_writer.write(geom.fg_geom)
        else
          Utils.psych_wkt_generator.generate(geom)
        end
      end

      def read_for_psych(str)
        ::Geos::WktReader.new.read(str)
      end

      private

      def create_fg_linear_ring(points)
        size = points.size
        return if size.between?(1, 2)
        if size > 0 && points.first != points.last
          points += [points.first]
          size += 1
        end
        cs = ::Geos::CoordinateSequence.new(size, 3)
        return unless points.all? { |p| RGeo::Feature::Point.check_type(p) }
        points.each_with_index do |p, i|
          cs.set_x(i, p.x)
          cs.set_y(i, p.y)
          if @has_z
            cs.set_z(i, p.z)
          elsif @has_m
            cs.set_z(i, p.m)
          end
        end
        ::Geos::Utils.create_linear_ring(cs)
      end
    end
  end
end
