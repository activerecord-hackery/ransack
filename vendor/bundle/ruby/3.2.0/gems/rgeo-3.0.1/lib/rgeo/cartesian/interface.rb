# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Cartesian toplevel interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Cartesian
    class << self
      # Creates and returns a cartesian factory of the preferred
      # Cartesian implementation.
      #
      # The actual implementation returned depends on which ruby
      # interpreter is running and what libraries are available.
      # RGeo will try to provide a fully-functional and performant
      # implementation if possible. If not, the simple Cartesian
      # implementation will be returned.
      # In practice, this means it returns a Geos implementation if
      # available; otherwise it falls back to the simple implementation.
      #
      # The given options are passed to the factory's constructor.
      # What options are available depends on the particular
      # implementation. See RGeo::Geos.factory and
      # RGeo::Cartesian.simple_factory for details. Unsupported options
      # are ignored.

      def preferred_factory(opts = {})
        if RGeo::Geos.supported?
          RGeo::Geos.factory(opts)
        else
          simple_factory(opts)
        end
      end
      alias factory preferred_factory

      # Returns a factory for the simple Cartesian implementation. This
      # implementation provides all SFS 1.1 types, and also allows Z and
      # M coordinates. It does not depend on external libraries, and is
      # thus always available, but it does not implement many of the more
      # advanced geometric operations. These limitations are:
      #
      # * Relational operators such as Feature::Geometry#intersects? are
      #   not implemented for most types.
      # * Relational constructors such as Feature::Geometry#union are
      #   not implemented for most types.
      # * Buffer and convex hull calculations are not implemented for most
      #   types. Boundaries are available except for GeometryCollection.
      # * Length calculations are available, but areas are not. Distances
      #   are available only between points.
      # * Equality and simplicity evaluation are implemented for some but
      #   not all types.
      # * Assertions for polygons and multipolygons are not implemented.
      #
      # Unimplemented operations may raise Error::UnsupportedOperation
      # if invoked.
      #
      # Options include:
      #
      # [<tt>:srid</tt>]
      #   Set the SRID returned by geometries created by this factory.
      #   Default is 0.
      # [<tt>:coord_sys</tt>]
      #   The coordinate system in OGC form, either as a subclass of
      #   CoordSys::CS::CoordinateSystem, or as a string in WKT format.
      #   Optional. If no coord_sys is given, but an SRID is the factory
      #   will try to create one using the CoordSys::CONFIG.default_coord_sys_class
      #   or the given :coord_sys_class option.
      # [<tt>:coord_sys_class</tt>]
      #   CoordSys::CS::CoordinateSystem implementation used to instansiate
      #   a coord_sys based on the :srid given.
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

      def simple_factory(opts = {})
        Cartesian::Factory.new(opts)
      end
    end
  end
end
