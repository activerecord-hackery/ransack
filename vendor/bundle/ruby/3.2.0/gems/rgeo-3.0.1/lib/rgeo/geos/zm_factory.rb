# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# GEOS zm factory implementation
#
# -----------------------------------------------------------------------------

module RGeo
  module Geos
    # A factory for Geos that handles both Z and M.
    class ZMFactory
      include Feature::Factory::Instance
      include ImplHelper::Utils

      # :stopdoc:

      TYPE_KLASSES = {
        Feature::Point => ZMPointImpl,
        Feature::LineString => ZMLineStringImpl,
        Feature::Line => ZMLineImpl,
        Feature::LinearRing => ZMLinearRingImpl,
        Feature::Polygon => ZMPolygonImpl,
        Feature::GeometryCollection => ZMGeometryCollectionImpl,
        Feature::MultiPoint => ZMMultiPointImpl,
        Feature::MultiLineString => ZMMultiLineStringImpl,
        Feature::MultiPolygon => ZMMultiPolygonImpl
      }.freeze

      # :startdoc:

      class << self
        # Create a new factory. Returns nil if the GEOS implementation is
        # not supported.

        def create(opts = {})
          return unless Geos.supported?
          new(opts)
        end
      end

      def initialize(opts = {}) # :nodoc:
        coord_sys = opts[:coord_sys]
        srid = opts[:srid]
        srid ||= coord_sys.authority_code if coord_sys
        config = {
          buffer_resolution: opts[:buffer_resolution], auto_prepare: opts[:auto_prepare],
          wkt_generator: opts[:wkt_generator], wkt_parser: opts[:wkt_parser],
          wkb_generator: opts[:wkb_generator], wkb_parser: opts[:wkb_parser],
          srid: srid.to_i, coord_sys: coord_sys
        }
        native_interface = opts[:native_interface] || Geos.preferred_native_interface
        if native_interface == :ffi
          @zfactory = FFIFactory.new(config.merge(has_z_coordinate: true))
          @mfactory = FFIFactory.new(config.merge(has_m_coordinate: true))
        else
          @zfactory = CAPIFactory.create(config.merge(has_z_coordinate: true))
          @mfactory = CAPIFactory.create(config.merge(has_m_coordinate: true))
        end

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

      # Marshal support

      def marshal_dump # :nodoc:
        hash = {
          "srid" => @zfactory.srid,
          "bufr" => @zfactory.buffer_resolution,
          "wktg" => @wkt_generator.properties,
          "wkbg" => @wkb_generator.properties,
          "wktp" => @wkt_parser.properties,
          "wkbp" => @wkb_parser.properties,
          "apre" => @zfactory.property(:auto_prepare) == :simple,
          "nffi" => @zfactory.is_a?(FFIFactory)
        }
        coord_sys = @zfactory.coord_sys
        hash["cs"] = coord_sys.to_wkt if coord_sys
        hash
      end

      def marshal_load(data) # :nodoc:
        cs_class = CoordSys::CONFIG.default_coord_sys_class
        coord_sys = data["cs"]&.then { |cs| cs_class.create_from_wkt(cs) }

        initialize(
          native_interface: (data["nffi"] ? :ffi : :capi),
          has_z_coordinate: data["hasz"],
          has_m_coordinate: data["hasm"],
          srid: data["srid"],
          buffer_resolution: data["bufr"],
          wkt_generator: symbolize_hash(data["wktg"]),
          wkb_generator: symbolize_hash(data["wkbg"]),
          wkt_parser: symbolize_hash(data["wktp"]),
          wkb_parser: symbolize_hash(data["wkbp"]),
          auto_prepare: (data["apre"] ? :simple : :disabled),
          coord_sys: coord_sys
        )
      end

      # Psych support

      def encode_with(coder) # :nodoc:
        coder["srid"] = @zfactory.srid
        coder["buffer_resolution"] = @zfactory.buffer_resolution
        coder["wkt_generator"] = @wkt_generator.properties
        coder["wkb_generator"] = @wkb_generator.properties
        coder["wkt_parser"] = @wkt_parser.properties
        coder["wkb_parser"] = @wkb_parser.properties
        coder["auto_prepare"] = @zfactory.property(:auto_prepare).to_s
        coder["native_interface"] = @zfactory.is_a?(FFIFactory) ? "ffi" : "capi"

        return unless (coord_sys = @zfactory.coord_sys)

        coder["coord_sys"] = coord_sys.to_wkt
      end

      def init_with(coder) # :nodoc:
        cs_class = CoordSys::CONFIG.default_coord_sys_class
        coord_sys = coder["cs"]&.then { |cs| cs_class.create_from_wkt(cs) }

        initialize(
          native_interface: coder["native_interface"] == "ffi" ? :ffi : :capi,
          has_z_coordinate: coder["has_z_coordinate"],
          has_m_coordinate: coder["has_m_coordinate"],
          srid: coder["srid"],
          buffer_resolution: coder["buffer_resolution"],
          wkt_generator: symbolize_hash(coder["wkt_generator"]),
          wkb_generator: symbolize_hash(coder["wkb_generator"]),
          wkt_parser: symbolize_hash(coder["wkt_parser"]),
          wkb_parser: symbolize_hash(coder["wkb_parser"]),
          auto_prepare: coder["auto_prepare"] == "disabled" ? :disabled : :simple,
          coord_sys: coord_sys
        )
      end

      # Returns the SRID of geometries created by this factory.

      def srid
        @zfactory.srid
      end

      # Returns the resolution used by buffer calculations on geometries
      # created by this factory

      def buffer_resolution
        @zfactory.buffer_resolution
      end

      # Returns the z-only factory corresponding to this factory.

      def z_factory
        @zfactory
      end

      # Returns the m-only factory corresponding to this factory.

      def m_factory
        @mfactory
      end

      # Factory equivalence test.

      def eql?(other)
        other.is_a?(ZMFactory) && other.z_factory == @zfactory
      end
      alias == eql?

      # Standard hash code

      def hash
        @hash ||= [@zfactory, @mfactory].hash
      end

      # See RGeo::Feature::Factory#property

      def property(name)
        case name
        when :has_z_coordinate, :has_m_coordinate, :is_cartesian
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

      def point(x, y, z = 0, m = 0)
        create_feature(
          ZMPointImpl,
          @zfactory.point(x, y, z),
          @mfactory.point(x, y, m)
        )
      end

      # See RGeo::Feature::Factory#line_string

      def line_string(points)
        create_feature(ZMLineStringImpl, @zfactory.line_string(points), @mfactory.line_string(points))
      end

      # See RGeo::Feature::Factory#line

      def line(start, stop)
        create_feature(ZMLineImpl, @zfactory.line(start, stop), @mfactory.line(start, stop))
      end

      # See RGeo::Feature::Factory#linear_ring

      def linear_ring(points)
        create_feature(ZMLinearRingImpl, @zfactory.linear_ring(points), @mfactory.linear_ring(points))
      end

      # See RGeo::Feature::Factory#polygon

      def polygon(outer_ring, inner_rings = nil)
        create_feature(
          ZMPolygonImpl,
          @zfactory.polygon(outer_ring, inner_rings),
          @mfactory.polygon(outer_ring, inner_rings)
        )
      end

      # See RGeo::Feature::Factory#collection

      def collection(elems)
        create_feature(ZMGeometryCollectionImpl, @zfactory.collection(elems), @mfactory.collection(elems))
      end

      # See RGeo::Feature::Factory#multi_point

      def multi_point(elems)
        create_feature(ZMMultiPointImpl, @zfactory.multi_point(elems), @mfactory.multi_point(elems))
      end

      # See RGeo::Feature::Factory#multi_line_string

      def multi_line_string(elems)
        create_feature(ZMMultiLineStringImpl, @zfactory.multi_line_string(elems), @mfactory.multi_line_string(elems))
      end

      # See RGeo::Feature::Factory#multi_polygon

      def multi_polygon(elems)
        create_feature(ZMMultiPolygonImpl, @zfactory.multi_polygon(elems), @mfactory.multi_polygon(elems))
      end

      # See RGeo::Feature::Factory#coord_sys

      def coord_sys
        @zfactory.coord_sys
      end

      # See RGeo::Feature::Factory#override_cast

      def override_cast(original, ntype, flags)
        return unless Geos.supported?
        keep_subtype = flags[:keep_subtype]
        project = flags[:project]
        type = original.geometry_type
        ntype = type if keep_subtype && type.include?(ntype)
        case original
        when ZMGeometryMethods
          # Optimization if we're just changing factories, but to
          # another ZM factory.
          if original.factory != self && ntype == type &&
              (!project || original.factory.coord_sys == @coord_sys)
            zresult = original.z_geometry.dup
            zresult.factory = @zfactory
            mresult = original.m_geometry.dup
            mresult.factory = @mfactory
            return original.class.create(self, zresult, mresult)
          end
          # LineString conversion optimization.
          if (original.factory != self || ntype != type) &&
              (!project || original.factory.coord_sys == @coord_sys) &&
              type.subtypeof?(Feature::LineString) && ntype.subtypeof?(Feature::LineString)
            klass = Factory::IMPL_CLASSES[ntype]
            zresult = klass._copy_from(@zfactory, original.z_geometry)
            mresult = klass._copy_from(@mfactory, original.m_geometry)
            return ZMLineStringImpl.create(self, zresult, mresult)
          end
        end
        false
      end

      def create_feature(klass, zgeometry, mgeometry) # :nodoc:
        klass ||= TYPE_KLASSES[zgeometry.geometry_type] || ZMGeometryImpl
        zgeometry && mgeometry ? klass.new(self, zgeometry, mgeometry) : nil
      end

      def marshal_wkb_generator
        @marshal_wkb_generator ||= RGeo::WKRep::WKBGenerator.new(typeformat: :wkb12)
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
