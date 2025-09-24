# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Coordinate systems for RGeo
#
# -----------------------------------------------------------------------------

require_relative "coord_sys/cs/factories"
require_relative "coord_sys/cs/entities"
require_relative "coord_sys/cs/wkt_parser"

module RGeo
  # This module provides data structures and tools related to coordinate
  # systems and coordinate transforms. It comprises the following parts:
  #
  # RGeo::CoordSys::Proj4 is a wrapper around the proj4 library, which
  # defines a commonly-used syntax for specifying geographic and projected
  # coordinate systems, and performs coordinate transformations.
  #
  # The RGeo::CoordSys::CS module contains an implementation of the CS
  # (coordinate systems) package of the OGC Coordinate Transform spec.
  # This includes classes for representing ellipsoids, datums, coordinate
  # systems, and other related concepts, as well as a parser for the WKT
  # format for specifying coordinate systems.
  module CoordSys
    CONFIG = Struct.new(:default_coord_sys_class).new(CS::CoordinateSystem)
  end
end
