# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Access to geographic data factories
#
# -----------------------------------------------------------------------------

module RGeo
  module Geographic
    class << self
      # Creates and returns a geographic factory that does not include a
      # a projection, and which performs calculations assuming a
      # spherical earth. In other words, geodesics are treated as great
      # circle arcs, and geometric calculations are handled accordingly.
      # Size and distance calculations report results in meters.
      # This implementation is thus ideal for everyday calculations on
      # the globe in which good accuracy is desired, but in which it is
      # not deemed necessary to perform the complex ellipsoidal
      # calculations needed for greater precision.
      #
      # The maximum error is about 0.5 percent, for objects and
      # calculations that span a significant percentage of the globe, due
      # to distortion caused by rotational flattening of the earth. For
      # calculations that span a much smaller area, the error can drop to
      # a few meters or less.
      #
      # === Limitations
      #
      # This implementation does not implement some of the more advanced
      # geometric operations. In particular:
      #
      # * Relational operators such as Feature::Geometry#intersects? are
      #   not implemented for most types.
      # * Relational constructors such as Feature::Geometry#union are
      #   not implemented for most types.
      # * Buffer, convex hull, and envelope calculations are not
      #   implemented for most types. Boundaries are available except for
      #   GeometryCollection.
      # * Length calculations are available, but areas are not. Distances
      #   are available only between points.
      # * Equality and simplicity evaluation are implemented for some but
      #   not all types.
      # * Assertions for polygons and multipolygons are not implemented.
      #
      # Unimplemented operations will return nil if invoked.
      #
      # === Options
      #
      # You may use the following options when creating a spherical
      # factory:
      #
      # [<tt>:has_z_coordinate</tt>]
      #   Support a Z coordinate. Default is false.
      # [<tt>:has_m_coordinate</tt>]
      #   Support an M coordinate. Default is false.
      # [<tt>:buffer_resolution</tt>]
      #   The resolution of buffers around geometries created by this
      #   factory. This controls the number of line segments used to
      #   approximate curves. The default is 1, which causes, for
      #   example, the buffer around a point to be approximated by a
      #   4-sided polygon. A resolution of 2 would cause that buffer
      #   to be approximated by an 8-sided polygon. The exact behavior
      #   for different kinds of buffers is not specified precisely,
      #   but in general the value is taken as the number of segments
      #   per 90-degree curve.
      # [<tt>:coord_sys</tt>]
      #   Provide a coordinate system in OGC format, either as an object
      #   (one of the CoordSys::CS classes) or as a string in WKT format.
      #   This coordinate system must be a GeographicCoordinateSystem.
      #   The default is the "popular visualization CRS" (EPSG 4055).
      # [<tt>:coord_sys_class</tt>]
      #   CoordSys::CS::CoordinateSystem implementation used to instansiate
      #   a coord_sys based on the :srid given.
      # [<tt>:srid</tt>]
      #   The SRID that should be returned by features from this factory.
      #   Default is 4055, indicating EPSG 4055, the "popular
      #   visualization crs". You may alternatively wish to set the srid
      #   to 4326, indicating the WGS84 crs, but note that that value
      #   implies an ellipsoidal datum, not a spherical datum.
      # [<tt>:wkt_parser</tt>]
      #   Configure the parser for WKT. The value is a hash of
      #   configuration parameters for WKRep::WKTParser.new. Default is
      #   the empty hash, indicating the default configuration for
      #   WKRep::WKTParser.
      # [<tt>:wkb_parser</tt>]
      #   Configure the parser for WKB. The value is a hash of
      #   configuration parameters for WKRep::WKBParser.new. Default is
      #   the empty hash, indicating the default configuration for
      #   WKRep::WKBParser.
      # [<tt>:wkt_generator</tt>]
      #   Configure the generator for WKT. The value is a hash of
      #   configuration parameters for WKRep::WKTGenerator.new.
      #   Default is <tt>{:convert_case => :upper}</tt>.
      # [<tt>:wkb_generator</tt>]
      #   Configure the generator for WKT. The value is a hash of
      #   configuration parameters for WKRep::WKTGenerator.new.
      #   Default is the empty hash, indicating the default configuration
      #   for WKRep::WKBGenerator.

      def spherical_factory(opts = {})
        coord_sys = opts[:coord_sys]
        srid = opts[:srid]
        srid ||= coord_sys.authority_code if coord_sys
        Geographic::Factory.new(
          "Spherical",
          has_z_coordinate: opts[:has_z_coordinate],
          has_m_coordinate: opts[:has_m_coordinate],
          coord_sys: coord_sys || coord_sys4055,
          buffer_resolution: opts[:buffer_resolution],
          wkt_parser: opts[:wkt_parser],
          wkb_parser: opts[:wkb_parser],
          wkt_generator: opts[:wkt_generator],
          wkb_generator: opts[:wkb_generator],
          srid: (srid || 4055).to_i
        )
      end

      # Creates and returns a geographic factory that is designed for
      # visualization applications that use Google or Bing maps, or any
      # other visualization systems that use the same projection. It
      # includes a projection factory that matches the projection used
      # by those mapping systems.
      #
      # Like all geographic factories, this one creates features using
      # latitude-longitude values. However, calculations such as
      # intersections are done in the projected coordinate system, and
      # size and distance calculations report results in the projected
      # units.
      #
      # The behavior of the simple_mercator factory could also be obtained
      # using a projected_factory with appropriate Proj4 specifications.
      # However, the simple_mercator implementation is done without
      # actually requiring the Proj4 library. The projections are simple
      # enough to be implemented in pure ruby.
      #
      # === About the coordinate system
      #
      # Many popular visualization technologies, such as Google and Bing
      # maps, actually use two coordinate systems. The first is the
      # standard WSG84 lat-long system used by the GPS and represented
      # by EPSG 4326. Most API calls and input-output in these mapping
      # technologies utilize this coordinate system. The second is a
      # Mercator projection based on a "sphericalization" of the WGS84
      # lat-long system. This projection is the basis of the map's screen
      # and tiling coordinates, and has been assigned EPSG 3857.
      #
      # This factory represents both coordinate systems. The main factory
      # produces data in the lat-long system and reports SRID 4326, and
      # the projected factory produces data in the projection and reports
      # SRID 3857. Latitudes are restricted to the range
      # (-85.05112877980659, 85.05112877980659), which conveniently
      # results in a square projected domain.
      #
      # === Options
      #
      # You may use the following options when creating a simple_mercator
      # factory:
      #
      # [<tt>:has_z_coordinate</tt>]
      #   Support a Z coordinate. Default is false.
      # [<tt>:has_m_coordinate</tt>]
      #   Support an M coordinate. Default is false.
      # [<tt>:wkt_parser</tt>]
      #   Configure the parser for WKT. The value is a hash of
      #   configuration parameters for WKRep::WKTParser.new. Default is
      #   the empty hash, indicating the default configuration for
      #   WKRep::WKTParser.
      # [<tt>:wkb_parser</tt>]
      #   Configure the parser for WKB. The value is a hash of
      #   configuration parameters for WKRep::WKBParser.new. Default is
      #   the empty hash, indicating the default configuration for
      #   WKRep::WKBParser.
      # [<tt>:wkt_generator</tt>]
      #   Configure the generator for WKT. The value is a hash of
      #   configuration parameters for WKRep::WKTGenerator.new.
      #   Default is <tt>{:convert_case => :upper}</tt>.
      # [<tt>:wkb_generator</tt>]
      #   Configure the generator for WKT. The value is a hash of
      #   configuration parameters for WKRep::WKTGenerator.new.
      #   Default is the empty hash, indicating the default configuration
      #   for WKRep::WKBGenerator.
      #
      # You may also provide options understood by the underlying
      # projected Cartesian factory. For example, if GEOS is used for the
      # projected factory, you may also set the <tt>:buffer_resolution</tt>
      # options. See RGeo::Geos.factory for more details.

      def simple_mercator_factory(opts = {})
        factory = Geographic::Factory.new(
          "Projected",
          coord_sys: coord_sys4326,
          srid: 4326,
          wkt_parser: opts[:wkt_parser],
          wkb_parser: opts[:wkb_parser],
          wkt_generator: opts[:wkt_generator],
          wkb_generator: opts[:wkb_generator],
          has_z_coordinate: opts[:has_z_coordinate],
          has_m_coordinate: opts[:has_m_coordinate]
        )
        projector = Geographic::SimpleMercatorProjector.new(
          factory,
          buffer_resolution: opts[:buffer_resolution],
          has_z_coordinate: opts[:has_z_coordinate],
          has_m_coordinate: opts[:has_m_coordinate]
        )
        factory.projector = projector
        factory
      end

      # Creates and returns a geographic factory that includes a
      # projection specified by a coordinate system. Like all
      # geographic factories, this one creates features using latitude-
      # longitude values. However, calculations such as intersections are
      # done in the projected coordinate system, and size and distance
      # calculations report results in the projected units. Thus, this
      # factory actually includes two factories representing different
      # coordinate systems: the main factory representing the geographic
      # lat-long coordinate system, and an auxiliary "projection factory"
      # representing the projected coordinate system.
      #
      # This implementation is intended for advanced GIS applications
      # requiring greater control over the projection being used.
      #
      # === Options
      #
      # When creating a projected implementation, you must provide enough
      # information to construct a CoordinateSystem specification for the projection.
      # Generally, this means you will provide either the projection's
      # factory itself (via the <tt>:projection_factory</tt> option), in
      # which case the factory must include a coord_sys;
      # or, alternatively, you should provide the coordinate system
      # and let this method construct a projection factory for you (which
      # it will do using the preferred Cartesian factory generator).
      # If you choose this second method, you may provide the coord_sys
      # via the <tt>:projection_coord_sys</tt> or <option or <tt>:projection_srid</tt>.
      #
      # Following are detailed descriptions of the various options you can
      # pass to this method.
      #
      # [<tt>:projection_factory</tt>]
      #   Specify an existing Cartesian factory to use for the projection.
      #   This factory must have a non-nil coord_sys. If this is provided, any
      #   <tt>:projection_coord_sys</tt> and
      #   <tt>:projection_srid</tt> are ignored.
      # [<tt>:projection_coord_sys</tt>]
      #   Specify a OGC coordinate system for the projection. This may be
      #   specified as an RGeo::CoordSys::CS::GeographicCoordinateSystem
      #   object, or as a String in OGC WKT format. Optional.
      # [<tt>:projection_srid</tt>]
      #   The SRID value to use for the projection factory. Defaults to
      #   the given projection coordinate system's authority code, or to
      #   0 if no projection coordinate system is known. If this is provided
      #   without a projection_coord_sys, one will be instansiated from
      #   the default_coord_sys_class or projection_coord_sys_class if given.
      # [<tt>:projection_coord_sys_class</tt>]
      #   Class to create the projection_coord_sys from if only a projection_srid
      #   is provided.
      # [<tt>:coord_sys</tt>]
      #   An OGC coordinate system for the geographic (lat-lon) factory,
      #   which may be an RGeo::CoordSys::CS::GeographicCoordinateSystem
      #   object or a string in OGC WKT format. It defaults to the
      #   geographic system embedded in the projection coordinate system.
      #   Generally, you should leave it at the default unless you want
      #   the geographic coordinate system to be based on a different
      #   horizontal datum than the projection.
      # [<tt>:srid</tt>]
      #   The SRID value to use for the main geographic factory. Defaults
      #   to the given geographic coordinate system's authority code, or
      #   to 0 if no geographic coordinate system is known.
      # [<tt>:has_z_coordinate</tt>]
      #   Support a Z coordinate. Default is false.
      #   Note: this is ignored if a <tt>:projection_factory</tt> is
      #   provided; in that case, the geographic factory's z-coordinate
      #   availability will match the projection factory's setting.
      # [<tt>:has_m_coordinate</tt>]
      #   Support an M coordinate. Default is false.
      #   Note: this is ignored if a <tt>:projection_factory</tt> is
      #   provided; in that case, the geographic factory's m-coordinate
      #   availability will match the projection factory's setting.
      # [<tt>:wkt_parser</tt>]
      #   Configure the parser for WKT. The value is a hash of
      #   configuration parameters for WKRep::WKTParser.new. Default is
      #   the empty hash, indicating the default configuration for
      #   WKRep::WKTParser.
      # [<tt>:wkb_parser</tt>]
      #   Configure the parser for WKB. The value is a hash of
      #   configuration parameters for WKRep::WKBParser.new. Default is
      #   the empty hash, indicating the default configuration for
      #   WKRep::WKBParser.
      # [<tt>:wkt_generator</tt>]
      #   Configure the generator for WKT. The value is a hash of
      #   configuration parameters for WKRep::WKTGenerator.new.
      #   Default is <tt>{:convert_case => :upper}</tt>.
      # [<tt>:wkb_generator</tt>]
      #   Configure the generator for WKT. The value is a hash of
      #   configuration parameters for WKRep::WKTGenerator.new.
      #   Default is the empty hash, indicating the default configuration
      #   for WKRep::WKBGenerator.
      #
      # If a <tt>:projection_factory</tt> is _not_ provided, you may also
      # provide options for configuring the projected Cartesian factory.
      # For example, if GEOS is used for the projected factory, you may
      # also set the <tt>:buffer_resolution</tt> option. See RGeo::Geos.factory
      # for more details.

      def projected_factory(opts = {})
        if (projection_factory = opts[:projection_factory])
          # Get the projection coordinate systems from the given factory
          projection_coord_sys = projection_factory.coord_sys

          if projection_coord_sys && !projection_coord_sys.projected?
            raise ArgumentError, "The :projection_factory's coord_sys is not a ProjectedCoordinateSystem."
          end

          # Determine geographic coordinate system. First check parameters.
          coord_sys = opts[:coord_sys]
          srid = opts[:srid]
          # Fall back to getting the values from the projection.
          coord_sys ||= projection_coord_sys.geographic_coordinate_system if projection_coord_sys
          srid ||= coord_sys.authority_code if coord_sys
          srid ||= 4326
          # Now we should have all the coordinate system info.
          factory = Geographic::Factory.new(
            "Projected",
            coord_sys: coord_sys,
            srid: srid.to_i,
            has_z_coordinate: projection_factory.property(:has_z_coordinate),
            has_m_coordinate: projection_factory.property(:has_m_coordinate),
            wkt_parser: opts[:wkt_parser], wkt_generator: opts[:wkt_generator],
            wkb_parser: opts[:wkb_parser], wkb_generator: opts[:wkb_generator]
          )
          projector = Geographic::Projector.create_from_existing_factory(
            factory,
            projection_factory
          )
        else
          # Determine projection coordinate system. First check the parameters.
          projection_coord_sys_info = ImplHelper::Utils.setup_coord_sys(
            opts[:projection_srid],
            opts[:projection_coord_sys],
            opts[:projection_coord_sys_class]
          )
          projection_coord_sys = projection_coord_sys_info[:coord_sys]
          projection_srid = projection_coord_sys_info[:srid]

          # Determine geographic coordinate system. First check parameters.
          coord_sys = opts[:coord_sys]
          srid = opts[:srid]

          # Fall back to getting the values from the projection.
          coord_sys ||= projection_coord_sys.geographic_coordinate_system if projection_coord_sys
          srid ||= coord_sys.authority_code if coord_sys
          srid ||= 4326
          # Now we should have all the coordinate system info.
          factory = Geographic::Factory.new(
            "Projected",
            coord_sys: coord_sys,
            srid: srid.to_i,
            has_z_coordinate: opts[:has_z_coordinate],
            has_m_coordinate: opts[:has_m_coordinate],
            wkt_parser: opts[:wkt_parser], wkt_generator: opts[:wkt_generator],
            wkb_parser: opts[:wkb_parser], wkb_generator: opts[:wkb_generator]
          )
          projector = Geographic::Projector.create_from_opts(
            factory,
            srid: projection_srid,
            coord_sys: projection_coord_sys,
            buffer_resolution: opts[:buffer_resolution],
            has_z_coordinate: opts[:has_z_coordinate],
            has_m_coordinate: opts[:has_m_coordinate],
            wkt_parser: opts[:wkt_parser], wkt_generator: opts[:wkt_generator],
            wkb_parser: opts[:wkb_parser], wkb_generator: opts[:wkb_generator]
          )
        end
        factory.projector = projector
        factory
      end

      private

      def coord_sys4055
        return @coord_sys4055 if defined?(@coord_sys4055)

        @coord_sys4055 = CoordSys::CONFIG.default_coord_sys_class.create(4055)
      end

      def coord_sys4326
        return @coord_sys4326 if defined?(@coord_sys4326)

        @coord_sys4326 = CoordSys::CONFIG.default_coord_sys_class.create(4326)
      end
    end
  end
end
