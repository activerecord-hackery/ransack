# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# GEOS factory implementation
#
# -----------------------------------------------------------------------------

module RGeo
  module Geos
    # This the GEOS CAPI implementation of RGeo::Feature::Factory.
    class CAPIFactory
      include Feature::Factory::Instance
      include ImplHelper::Utils

      class << self
        # Create a new factory. Returns nil if the GEOS CAPI implementation
        # is not supported.
        #
        # See RGeo::Geos.factory for a list of supported options.

        def create(opts = {})
          # Make sure GEOS is available
          return unless respond_to?(:_create)

          # Get flags to pass to the C extension
          flags = 0
          flags |= 2 if opts[:has_z_coordinate]
          flags |= 4 if opts[:has_m_coordinate]

          if flags & 6 == 6
            raise Error::UnsupportedOperation, "GEOS cannot support both Z and M coordinates at the same time."
          end

          flags |= 8 unless opts[:auto_prepare] == :disabled

          # Buffer resolution
          buffer_resolution = opts[:buffer_resolution].to_i
          buffer_resolution = 1 if buffer_resolution < 1

          # Interpret the generator options
          wkt_generator = opts[:wkt_generator]
          wkt_generator =
            case wkt_generator
            when Hash
              WKRep::WKTGenerator.new(wkt_generator)
            end
          wkb_generator = opts[:wkb_generator]
          wkb_generator =
            case wkb_generator
            when Hash
              WKRep::WKBGenerator.new(wkb_generator)
            end

          # Coordinate system (srid and coord_sys)
          coord_sys_info = ImplHelper::Utils.setup_coord_sys(opts[:srid], opts[:coord_sys], opts[:coord_sys_class])
          srid = coord_sys_info[:srid]
          coord_sys = coord_sys_info[:coord_sys]

          # Create the factory and set instance variables
          result = _create(
            flags,
            srid.to_i,
            buffer_resolution,
            wkt_generator,
            wkb_generator,
            coord_sys
          )

          # Interpret parser options
          wkt_parser = opts[:wkt_parser]
          wkt_parser =
            case wkt_parser
            when Hash
              WKRep::WKTParser.new(result, wkt_parser)
            end
          wkb_parser = opts[:wkb_parser]
          wkb_parser =
            case wkb_parser
            when Hash
              WKRep::WKBParser.new(result, wkb_parser)
            end
          result._set_wkrep_parsers(wkt_parser, wkb_parser)

          # Return the result
          result
        end
        alias new create
      end

      # Standard object inspection output

      def inspect
        "#<#{self.class}:0x#{object_id.to_s(16)} srid=#{_srid} bufres=#{_buffer_resolution} flags=#{_flags}>"
      end

      # Factory equivalence test.

      def eql?(other)
        other.is_a?(CAPIFactory) && other.srid == _srid &&
          other._buffer_resolution == _buffer_resolution && other._flags == _flags &&
          other.coord_sys == coord_sys
      end
      alias == eql?

      # Standard hash code

      def hash
        @hash ||= [_srid, _buffer_resolution, _flags].hash
      end

      # Marshal support

      def marshal_dump # :nodoc:
        hash_ = {
          "hasz" => supports_z?,
          "hasm" => supports_m?,
          "srid" => _srid,
          "bufr" => _buffer_resolution,
          "wktg" => _wkt_generator ? _wkt_generator.properties : {},
          "wkbg" => _wkb_generator ? _wkb_generator.properties : {},
          "wktp" => _wkt_parser ? _wkt_parser.properties : {},
          "wkbp" => _wkb_parser ? _wkb_parser.properties : {},
          "apre" => auto_prepare
        }
        if (coord_sys_ = _coord_sys)
          hash_["cs"] = coord_sys_.to_wkt
        end
        hash_
      end

      def marshal_load(data_) # :nodoc:
        cs_class = CoordSys::CONFIG.default_coord_sys_class
        coord_sys_ = data_["cs"]&.then { |cs| cs_class.create_from_wkt(cs) }

        initialize_copy(
          CAPIFactory.create(
            has_z_coordinate: data_["hasz"],
            has_m_coordinate: data_["hasm"],
            srid: data_["srid"],
            buffer_resolution: data_["bufr"],
            wkt_generator: symbolize_hash(data_["wktg"]),
            wkb_generator: symbolize_hash(data_["wkbg"]),
            wkt_parser: symbolize_hash(data_["wktp"]),
            wkb_parser: symbolize_hash(data_["wkbp"]),
            auto_prepare: data_["apre"],
            coord_sys: coord_sys_
          )
        )
      end

      # Psych support

      def encode_with(coder_) # :nodoc:
        coder_["has_z_coordinate"] = supports_z?
        coder_["has_m_coordinate"] = supports_m?
        coder_["srid"] = _srid
        coder_["buffer_resolution"] = _buffer_resolution
        coder_["wkt_generator"] = _wkt_generator ? _wkt_generator.properties : {}
        coder_["wkb_generator"] = _wkb_generator ? _wkb_generator.properties : {}
        coder_["wkt_parser"] = _wkt_parser ? _wkt_parser.properties : {}
        coder_["wkb_parser"] = _wkb_parser ? _wkb_parser.properties : {}
        coder_["auto_prepare"] = auto_prepare

        return unless (coord_sys_ = _coord_sys)

        coder_["coord_sys"] = coord_sys_.to_wkt
      end

      def init_with(coder_) # :nodoc:
        cs_class = CoordSys::CONFIG.default_coord_sys_class
        coord_sys_ = coder_["cs"]&.then { |cs| cs_class.create_from_wkt(cs) }

        initialize_copy(
          CAPIFactory.create(
            has_z_coordinate: coder_["has_z_coordinate"],
            has_m_coordinate: coder_["has_m_coordinate"],
            srid: coder_["srid"],
            buffer_resolution: coder_["buffer_resolution"],
            wkt_generator: symbolize_hash(coder_["wkt_generator"]),
            wkb_generator: symbolize_hash(coder_["wkb_generator"]),
            wkt_parser: symbolize_hash(coder_["wkt_parser"]),
            wkb_parser: symbolize_hash(coder_["wkb_parser"]),
            auto_prepare: coder_["auto_prepare"] == "disabled" ? :disabled : :simple,
            coord_sys: coord_sys_
          )
        )
      end

      # Returns the SRID of geometries created by this factory.

      def srid
        _srid
      end

      # Returns the resolution used by buffer calculations on geometries
      # created by this factory

      def buffer_resolution
        _buffer_resolution
      end

      # See RGeo::Feature::Factory#property
      def property(name_)
        case name_
        when :has_z_coordinate
          supports_z?
        when :has_m_coordinate
          supports_m?
        when :is_cartesian
          true
        when :buffer_resolution
          _buffer_resolution
        when :auto_prepare
          prepare_heuristic? ? :simple : :disabled
        end
      end

      # See RGeo::Feature::Factory#parse_wkt

      def parse_wkt(str_)
        if (wkt_parser_ = _wkt_parser)
          wkt_parser_.parse(str_)
        else
          _parse_wkt_impl(str_)
        end
      end

      # See RGeo::Feature::Factory#parse_wkb

      def parse_wkb(str_)
        if (wkb_parser_ = _wkb_parser)
          wkb_parser_.parse(str_)
        else
          _parse_wkb_impl(str_)
        end
      end

      # See RGeo::Feature::Factory#point

      def point(x, y, *extra)
        raise(RGeo::Error::InvalidGeometry, "Parse error") if extra.length > (supports_z_or_m? ? 1 : 0)

        CAPIPointImpl.create(self, x, y, extra[0].to_f)
      end

      # See RGeo::Feature::Factory#line_string

      def line_string(points_)
        points_ = points_.to_a unless points_.is_a?(Array)
        CAPILineStringImpl.create(self, points_) ||
          raise(RGeo::Error::InvalidGeometry, "Parse error")
      end

      # See RGeo::Feature::Factory#line

      def line(start_, end_)
        CAPILineImpl.create(self, start_, end_)
      end

      # See RGeo::Feature::Factory#linear_ring

      def linear_ring(points_)
        points_ = points_.to_a unless points_.is_a?(Array)
        CAPILinearRingImpl.create(self, points_)
      end

      # See RGeo::Feature::Factory#polygon

      def polygon(outer_ring_, inner_rings_ = nil)
        inner_rings_ = inner_rings_.to_a unless inner_rings_.is_a?(Array)
        CAPIPolygonImpl.create(self, outer_ring_, inner_rings_)
      end

      # See RGeo::Feature::Factory#collection

      def collection(elems_)
        elems_ = elems_.to_a unless elems_.is_a?(Array)
        CAPIGeometryCollectionImpl.create(self, elems_)
      end

      # See RGeo::Feature::Factory#multi_point

      def multi_point(elems_)
        elems_ = elems_.to_a unless elems_.is_a?(Array)
        CAPIMultiPointImpl.create(self, elems_)
      end

      # See RGeo::Feature::Factory#multi_line_string

      def multi_line_string(elems_)
        elems_ = elems_.to_a unless elems_.is_a?(Array)
        CAPIMultiLineStringImpl.create(self, elems_)
      end

      # See RGeo::Feature::Factory#multi_polygon

      def multi_polygon(elems_)
        elems_ = elems_.to_a unless elems_.is_a?(Array)
        CAPIMultiPolygonImpl.create(self, elems_) ||
          raise(RGeo::Error::InvalidGeometry, "Parse error")
      end

      # See RGeo::Feature::Factory#coord_sys

      def coord_sys
        _coord_sys
      end

      # See RGeo::Feature::Factory#override_cast

      def override_cast(original, ntype, flags)
        return unless Geos.supported?
        keep_subtype = flags[:keep_subtype]
        # force_new_ = flags[:force_new]
        project = flags[:project]
        type = original.geometry_type
        ntype = type if keep_subtype && type.include?(ntype)
        case original
        when CAPIGeometryMethods
          # Optimization if we're just changing factories, but the
          # factories are zm-compatible and coord_sys-compatible.
          if original.factory != self && ntype == type &&
              original.factory._flags & FLAG_SUPPORTS_Z_OR_M == _flags & FLAG_SUPPORTS_Z_OR_M &&
              (!project || original.factory.coord_sys == coord_sys)
            result = original.dup
            result.factory = self
            return result
          end
          # LineString conversion optimization.
          if (original.factory != self || ntype != type) &&
              original.factory._flags & FLAG_SUPPORTS_Z_OR_M == _flags & FLAG_SUPPORTS_Z_OR_M &&
              (!project || original.factory.coord_sys == coord_sys) &&
              type.subtype_of?(Feature::LineString) && ntype.subtype_of?(Feature::LineString)
            return IMPL_CLASSES[ntype]._copy_from(self, original)
          end
        when ZMGeometryMethods
          # Optimization for just removing a coordinate from an otherwise
          # compatible factory
          if supports_z? && !supports_m? && self == original.factory.z_factory
            return Feature.cast(original.z_geometry, ntype, flags)
          end

          if supports_m? && !supports_z? && self == original.factory.m_factory
            return Feature.cast(original.m_geometry, ntype, flags)
          end
        end
        false
      end

      def auto_prepare # :nodoc:
        prepare_heuristic? ? :simple : :disabled
      end

      # :stopdoc:

      IMPL_CLASSES = {
        Feature::Point => CAPIPointImpl,
        Feature::LineString => CAPILineStringImpl,
        Feature::LinearRing => CAPILinearRingImpl,
        Feature::Line => CAPILineImpl,
        Feature::GeometryCollection => CAPIGeometryCollectionImpl,
        Feature::MultiPoint => CAPIMultiPointImpl,
        Feature::MultiLineString => CAPIMultiLineStringImpl,
        Feature::MultiPolygon => CAPIMultiPolygonImpl
      }.freeze

      # :startdoc:
    end
  end
end
