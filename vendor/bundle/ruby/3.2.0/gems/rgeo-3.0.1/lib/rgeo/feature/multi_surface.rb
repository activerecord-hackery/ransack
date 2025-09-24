# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# MultiSurface feature interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # == SFS 1.1 Description
    #
    # A MultiSurface is a 2-dimensional GeometryCollection whose elements
    # are Surfaces. The interiors of any two Surfaces in a MultiSurface may
    # not intersect. The boundaries of any two elements in a MultiSurface
    # may intersect, at most, at a finite number of Points.
    #
    # MultiSurface is a non-instantiable class in this International
    # Standard. It defines a set of methods for its subclasses and is
    # included for reasons of extensibility. The instantiable subclass of
    # MultiSurface is MultiPolygon, corresponding to a collection of
    # Polygons.
    #
    # == Notes
    #
    # MultiSurface is defined as a module and is provided primarily
    # for the sake of documentation. Implementations need not necessarily
    # include this module itself. Therefore, you should not depend on the
    # kind_of? method to check type. Instead, use the provided check_type
    # class method (or === operator) defined in the Type module.
    module MultiSurface
      include GeometryCollection
      extend Type

      # === SFS 1.1 Description
      #
      # The area of this MultiSurface, as measured in the spatial reference
      # system of this MultiSurface.
      #
      # === Notes
      #
      # Returns a floating-point scalar value.

      def area
        raise Error::UnsupportedOperation, "Method #{self.class}#area not defined."
      end

      # === SFS 1.1 Description
      #
      # The mathematical centroid for this MultiSurface as a Point. The
      # result is not guaranteed to be on this MultiSurface.
      #
      # === Notes
      #
      # Returns an object that supports the Point interface.

      def centroid
        raise Error::UnsupportedOperation, "Method #{self.class}#centroid not defined."
      end

      # === SFS 1.1 Description
      #
      # A Point guaranteed to be on this MultiSurface.
      #
      # === Notes
      #
      # Returns an object that supports the Point interface.

      def point_on_surface
        raise Error::UnsupportedOperation, "Method #{self.class}#point_on_surface not defined."
      end
    end
  end
end
