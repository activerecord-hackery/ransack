# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# OGC CS factory for RGeo
#
# -----------------------------------------------------------------------------

module RGeo
  module CoordSys
    # This module contains an implementation of the CS (coordinate
    # systems) package of the OGC Coordinate Transform spec. It provides
    # classes for representing ellipsoids, datums, coordinate systems,
    # and other related concepts, as well as a parser for the WKT format
    # for specifying coordinate systems.
    #
    # Generally, the easiest way to create coordinate system objects is
    # to use RGeo::CoordSys::CS.create_from_wkt, which parses the WKT
    # format. You can also use the create methods available for each
    # object class.
    #
    # Most but not all of the spec is implemented here.
    # Currently missing are:
    #
    # * XML format is not implemented. We're assuming that WKT is the
    #   preferred format.
    # * The PT and CT packages are not implemented.
    # * FittedCoordinateSystem is not implemented.
    # * The defaultEnvelope attribute of CS_CoordinateSystem is not
    #   implemented.
    module CS
      # A class implementing the CS_CoordinateSystemFactory interface.
      # It provides methods for building up complex objects from simpler
      # objects or values.
      #
      # Note that the methods of CS_CoordinateSystemFactory do not provide
      # facilities for setting the authority. If you need to set authority
      # values, use the create methods for the object classes themselves.
      class CoordinateSystemFactory
        # Create a CompoundCoordinateSystem from a name, and two
        # constituent coordinate systems.

        def create_compound_coordinate_system(name, head, tail)
          CompoundCoordinateSystem.create(name, head, tail)
        end

        # Create an Ellipsoid from a name, semi-major axis, and semi-minor
        # axis. You can also provide a LinearUnit, but this is optional
        # and may be set to nil.

        def create_ellipsoid(name, semi_major_axis, semi_minor_axis, linear_unit)
          Ellipsoid.create_ellipsoid(name, semi_major_axis, semi_minor_axis, linear_unit)
        end

        # Create an Ellipsoid from a name, semi-major axis, and an inverse
        # flattening factor. You can also provide a LinearUnit, but this
        # is optional and may be set to nil.

        def create_flattened_sphere(name, semi_major_axis, inverse_flattening, linear_unit)
          Ellipsoid.create_flattened_sphere(name, semi_major_axis, inverse_flattening, linear_unit)
        end

        # Create any object given the OGC WKT format. Raises
        # Error::ParseError if a syntax error is encounterred.

        def create_from_wkt(str)
          WKTParser.new(str).parse
        end

        # Create a GeographicCoordinateSystem, given a name, an
        # AngularUnit, a HorizontalDatum, a PrimeMeridian, and two
        # AxisInfo objects. The AxisInfo objects are optional and may be
        # set to nil.

        def create_geographic_coordinate_system(name, angular_unit, horizontal_datum, prime_meridian, axis0, axis1)
          GeographicCoordinateSystem.create(name, angular_unit, horizontal_datum, prime_meridian, axis0, axis1)
        end

        # Create a HorizontalDatum given a name, a horizontal datum type
        # code, an Ellipsoid, and a WGS84ConversionInfo. The
        # WGS84ConversionInfo is optional and may be set to nil.

        def create_horizontal_datum(name, horizontal_datum_type, ellipsoid, to_wgs84)
          HorizontalDatum.create(name, horizontal_datum_type, ellipsoid, to_wgs84)
        end

        # Create a LocalCoordinateSystem given a name, a LocalDatum, a
        # Unit, and an array of at least one AxisInfo.

        def create_local_coordinate_system(name, datum, unit, axes)
          LocalCoordinateSystem.create(name, datum, unit, axes)
        end

        # Create a LocalDatum given a name and a local datum type code.

        def create_local_datum(_name, local_datum_type)
          LocalDatum.create(name, local_datum_type)
        end

        # Create a PrimeMeridian given a name, an AngularUnit, and a
        # longitude offset.

        def create_prime_meridian(_name, angular_unit, longitude)
          PrimeMeridian.create(name, angular_unit, longitude)
        end

        # Create a ProjectedCoordinateSystem given a name, a
        # GeographicCoordinateSystem, and Projection, a LinearUnit, and
        # two AxisInfo objects. The AxisInfo objects are optional and may
        # be set to nil.

        def create_projected_coordinate_system(name, gcs, projection, linear_unit, axis0, axis1)
          ProjectedCoordinateSystem.create(name, gcs, projection, linear_unit, axis0, axis1)
        end

        # Create a Projection given a name, a projection class, and an
        # array of ProjectionParameter.

        def create_projection(name, wkt_projection_class, parameters)
          Projection.create(name, wkt_projection_class, parameters)
        end

        # Create a VerticalCoordinateSystem given a name, a VerticalDatum,
        # a VerticalUnit, and an AxisInfo. The AxisInfo is optional and
        # may be nil.

        def create_vertical_coordinate_system(name, vertical_datum, vertical_unit, axis)
          VerticalCoordinateSystem.create(name, vertical_datum, vertical_unit, axis)
        end

        # Create a VerticalDatum given a name ane a datum type code.

        def create_vertical_datum(name, vertical_datum_type)
          VerticalDatum.create(name, vertical_datum_type)
        end
      end

      class << self
        # Parsees OGC WKT format and returns the object created. Raises
        # Error::ParseError if a syntax error is encounterred.

        def create_from_wkt(str)
          WKTParser.new(str).parse
        end
      end
    end
  end
end
