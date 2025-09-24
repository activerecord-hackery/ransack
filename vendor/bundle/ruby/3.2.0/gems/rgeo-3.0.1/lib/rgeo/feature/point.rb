# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Point feature interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # == SFS 1.1 Description
    #
    # A Point is a 0-dimensional geometric object and represents a single
    # location in coordinate space. A Point has an x-coordinate value and
    # a y-coordinate value.
    #
    # The boundary of a Point is the empty set.
    #
    # == Notes
    #
    # Point is defined as a module and is provided primarily
    # for the sake of documentation. Implementations need not necessarily
    # include this module itself. Therefore, you should not depend on the
    # kind_of? method to check type. Instead, use the provided check_type
    # class method (or === operator) defined in the Type module.
    #
    # Some implementations may support higher dimensional points.
    #
    # Some libraries, such as GEOS, support "empty" points. Such objects
    # might be returned as, for example, the centroid of an empty
    # MultiPolygon. The SFS does not clearly define or even acknowledge
    # the existence of such a type, so RGeo will currently generally
    # replace them with empty GeometryCollection objects. Therefore,
    # currently, every RGeo Point object represents an actual location
    # with real coordinates.
    module Point
      include Geometry
      extend Type

      # === SFS 1.1 Description
      #
      # The x-coordinate value for this Point.
      #
      # === Notes
      #
      # Returns a floating-point scalar value.

      def x
        raise Error::UnsupportedOperation, "Method #{self.class}#x not defined."
      end

      # === SFS 1.1 Description
      #
      # The y-coordinate value for this Point.
      #
      # === Notes
      #
      # Returns a floating-point scalar value.

      def y
        raise Error::UnsupportedOperation, "Method #{self.class}#y not defined."
      end

      # Returns the z-coordinate for this Point as a floating-point
      # scalar value.
      #
      # This method may not be available if the point's factory does
      # not support Z coordinates.

      def z
        raise Error::UnsupportedOperation, "Method #{self.class}#z not defined."
      end

      # Returns the m-coordinate for this Point as a floating-point
      # scalar value.
      #
      # This method may not be available if the point's factory does
      # not support M coordinates.

      def m
        raise Error::UnsupportedOperation, "Method #{self.class}#m not defined."
      end
    end
  end
end
