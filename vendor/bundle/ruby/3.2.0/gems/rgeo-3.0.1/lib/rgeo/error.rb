# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Error classes for RGeo
#
# -----------------------------------------------------------------------------

module RGeo
  # All RGeo errors are members of this namespace.

  module Error
    # Base class for all RGeo-related exceptions
    class RGeoError < RuntimeError
    end

    # RGeo error specific to the GEOS implementation.
    class GeosError < RGeoError
    end

    # The specified geometry is invalid
    class InvalidGeometry < RGeoError
    end

    # The specified operation is not supported or not implemented
    class UnsupportedOperation < RGeoError
    end

    # Parsing failed
    class ParseError < RGeoError
    end

    # Standard error messages from
    # https://github.com/locationtech/jts/blob/0afbfb1956ec24912a8b4dc4edff0f1200442857/modules/core/src/main/java/org/locationtech/jts/operation/valid/TopologyValidationError.java#L98-L110
    TOPOLOGY_VALIDATION_ERR = "Topology Validation Error"
    REPEATED_POINT = "Repeated Point"
    HOLE_OUTSIDE_SHELL = "Hole lies outside shell"
    NESTED_HOLES = "Holes are nested"
    DISCONNECTED_INTERIOR = "Interior is disconnected"
    SELF_INTERSECTION = "Self-intersection"
    RING_SELF_INTERSECTION = "Ring Self-intersection"
    NESTED_SHELLS = "Nested shells"
    DUPLICATE_RINGS = "Duplicate Rings"
    TOO_FEW_POINTS = "Too few distinct points in geometry component"
    INVALID_COORDINATE = "Invalid Coordinate"
    UNCLOSED_RING = "Ring is not closed"
  end
end
