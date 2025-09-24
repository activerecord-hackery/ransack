# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Geographic data factory implementation
#
# -----------------------------------------------------------------------------

module RGeo
  module Geographic
    # This class implements the various factories for geography features.
    # See methods of the RGeo::Geographic module for the API for creating
    # geography factories.
    class Factory
      include Feature::Factory::Instance
      include ImplHelper::Utils

      attr_writer :projector

      attr_reader :coordinate_dimension, :spatial_dimension

      # Returns the srid reported by this factory.
      attr_reader :srid

      # See RGeo::Feature::Factory#coord_sys
      attr_reader :coord_sys

      def initialize(impl_prefix, opts = {}) # :nodoc:
        @impl_prefix = impl_prefix
        @point_class = Geographic.const_get("#{impl_prefix}PointImpl")
        @line_string_class = Geographic.const_get("#{impl_prefix}LineStringImpl")
        @linear_ring_class = Geographic.const_get("#{impl_prefix}LinearRingImpl")
        @line_class = Geographic.const_get("#{impl_prefix}LineImpl")
        @polygon_class = Geographic.const_get("#{impl_prefix}PolygonImpl")
        @geometry_collection_class = Geographic.const_get("#{impl_prefix}GeometryCollectionImpl")
        @multi_point_class = Geographic.const_get("#{impl_prefix}MultiPointImpl")
        @multi_line_string_class = Geographic.const_get("#{impl_prefix}MultiLineStringImpl")
        @multi_polygon_class = Geographic.const_get("#{impl_prefix}MultiPolygonImpl")
        @support_z = opts[:has_z_coordinate] ? true : false
        @support_m = opts[:has_m_coordinate] ? true : false
        @coordinate_dimension = 2
        @coordinate_dimension += 1 if @support_z
        @coordinate_dimension += 1 if @support_m
        @spatial_dimension = @support_z ? 3 : 2

        srid = opts.fetch(:srid, 4326).to_i
        coord_sys_info = ImplHelper::Utils.setup_coord_sys(srid, opts[:coord_sys], opts[:coord_sys_class])
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
        @projector = nil
      end

      # Equivalence test.

      def eql?(other)
        other.is_a?(Geographic::Factory) &&
          @impl_prefix == other.instance_variable_get(:@impl_prefix) &&
          @support_z == other.instance_variable_get(:@support_z) &&
          @support_m == other.instance_variable_get(:@support_m) &&
          @coord_sys == other.instance_variable_get(:@coord_sys)
      end
      alias == eql?

      # Standard hash code

      def hash
        @hash ||= [@impl_prefix, @support_z, @support_m, @coord_sys].hash
      end

      # Marshal support

      def marshal_dump # :nodoc:
        hash_ = {
          "pref" => @impl_prefix,
          "hasz" => @support_z,
          "hasm" => @support_m,
          "srid" => @srid,
          "wktg" => @wkt_generator.properties,
          "wkbg" => @wkb_generator.properties,
          "wktp" => @wkt_parser.properties,
          "wkbp" => @wkb_parser.properties,
          "bufr" => @buffer_resolution
        }
        hash_["cs"] = @coord_sys.to_wkt if @coord_sys
        if @projector
          hash_["prjc"] = @projector.class.name.sub(/.*::/, "")
          hash_["prjf"] = @projector.projection_factory
        end
        hash_
      end

      def marshal_load(data_) # :nodoc:
        cs_class = CoordSys::CONFIG.default_coord_sys_class
        coord_sys = data_["cs"]&.then { |cs| cs_class.create_from_wkt(cs) }

        initialize(
          data_["pref"],
          has_z_coordinate: data_["hasz"],
          has_m_coordinate: data_["hasm"],
          srid: data_["srid"],
          wkt_generator: symbolize_hash(data_["wktg"]),
          wkb_generator: symbolize_hash(data_["wkbg"]),
          wkt_parser: symbolize_hash(data_["wktp"]),
          wkb_parser: symbolize_hash(data_["wkbp"]),
          buffer_resolution: data_["bufr"],
          coord_sys: coord_sys
        )
        proj_klass = data_["prjc"]
        proj_factory = data_["prjf"]

        return unless proj_klass && proj_factory

        klass_ = RGeo::Geographic.const_get(proj_klass)

        return unless klass_

        projector = klass_.allocate
        projector.set_factories(self, proj_factory)
        @projector = projector
      end

      # Psych support

      def encode_with(coder) # :nodoc:
        coder["impl_prefix"] = @impl_prefix
        coder["has_z_coordinate"] = @support_z
        coder["has_m_coordinate"] = @support_m
        coder["srid"] = @srid
        coder["wkt_generator"] = @wkt_generator.properties
        coder["wkb_generator"] = @wkb_generator.properties
        coder["wkt_parser"] = @wkt_parser.properties
        coder["wkb_parser"] = @wkb_parser.properties
        coder["buffer_resolution"] = @buffer_resolution
        coder["coord_sys"] = @coord_sys.to_wkt if @coord_sys

        return unless @projector

        coder["projectorclass"] = @projector.class.name.sub(/.*::/, "")
        coder["projection_factory"] = @projector.projection_factory
      end

      def init_with(coder) # :nodoc:
        cs_class = CoordSys::CONFIG.default_coord_sys_class
        coord_sys = coder["cs"]&.then { |cs| cs_class.create_from_wkt(cs) }

        initialize(
          coder["impl_prefix"],
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
        proj_klass = coder["projectorclass"]
        proj_factory = coder["projection_factory"]

        return unless proj_klass && proj_factory

        klass_ = RGeo::Geographic.const_get(proj_klass)

        return unless klass_

        projector = klass_.allocate
        projector.set_factories(self, proj_factory)
        @projector = projector
      end

      # Returns true if this factory supports a projection.

      def has_projection?
        !@projector.nil?
      end

      # Returns the factory for the projected coordinate space,
      # or nil if this factory does not support a projection.

      def projection_factory
        @projector&.projection_factory
      end

      # Projects the given geometry into the projected coordinate space,
      # and returns the projected geometry.
      # Returns nil if this factory does not support a projection.
      # Raises Error::InvalidGeometry if the given geometry is not of
      # this factory.

      def project(geometry)
        return unless @projector && geometry
        raise Error::InvalidGeometry, "Wrong geometry type" unless geometry.factory == self
        @projector.project(geometry)
      end

      # Reverse-projects the given geometry from the projected coordinate
      # space into lat-long space.
      # Raises Error::InvalidGeometry if the given geometry is not of
      # the projection defined by this factory.

      def unproject(geometry)
        return unless geometry

        unless @projector && @projector.projection_factory == geometry.factory
          raise Error::InvalidGeometry, "You can unproject only features that are in the projected coordinate space."
        end

        @projector.unproject(geometry)
      end

      # Returns true if this factory supports a projection and the
      # projection wraps its x (easting) direction. For example, a
      # Mercator projection wraps, but a local projection that is valid
      # only for a small area does not wrap. Returns nil if this factory
      # does not support or a projection, or if it is not known whether
      # or not it wraps.

      def projection_wraps?
        @projector ? @projector.wraps? : nil
      end

      # Returns a ProjectedWindow specifying the limits of the domain of
      # the projection space.
      # Returns nil if this factory does not support a projection, or the
      # projection limits are not known.

      def projection_limits_window
        return @projection_limits_window if defined?(@projection_limits_window)
        return unless @projector

        @projection_limits_window = @projector.limits_window
      end

      # See RGeo::Feature::Factory#property

      def property(name)
        case name
        when :has_z_coordinate
          @support_z
        when :has_m_coordinate
          @support_m
        when :buffer_resolution
          @buffer_resolution
        when :is_geographic
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
        @point_class.new(self, x, y, *extra)
      end

      # See RGeo::Feature::Factory#line_string

      def line_string(points)
        @line_string_class.new(self, points)
      end

      # See RGeo::Feature::Factory#line

      def line(start, stop)
        @line_class.new(self, start, stop)
      end

      # See RGeo::Feature::Factory#linear_ring

      def linear_ring(points)
        @linear_ring_class.new(self, points)
      end

      # See RGeo::Feature::Factory#polygon

      def polygon(outer_ring, inner_rings = nil)
        @polygon_class.new(self, outer_ring, inner_rings)
      end

      # See RGeo::Feature::Factory#collection

      def collection(elems)
        @geometry_collection_class.new(self, elems)
      end

      # See RGeo::Feature::Factory#multi_point

      def multi_point(elems)
        @multi_point_class.new(self, elems)
      end

      # See RGeo::Feature::Factory#multi_line_string

      def multi_line_string(elems)
        @multi_line_string_class.new(self, elems)
      end

      # See RGeo::Feature::Factory#multi_polygon

      def multi_polygon(elems)
        @multi_polygon_class.new(self, elems)
      end

      def generate_wkt(obj)
        @wkt_generator.generate(obj)
      end

      def generate_wkb(obj) # :nodoc:
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
