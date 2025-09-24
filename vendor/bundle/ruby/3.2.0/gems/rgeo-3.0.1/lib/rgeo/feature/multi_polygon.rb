# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# MultiPolygon feature interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # == SFS 1.1 Description
    #
    # A MultiPolygon is a MultiSurface whose elements are Polygons.
    #
    # The assertions for MultiPolygons are as follows.
    #
    # a) The interiors of 2 Polygons that are elements of a MultiPolygon
    # may not intersect.
    #
    # b) The boundaries of any 2 Polygons that are elements of a
    # MultiPolygon may not "cross" and may touch at only a finite number
    # of Points. NOTE: Crossing is prevented by assertion (a) above.
    #
    # c) A MultiPolygon is defined as topologically closed.
    #
    # d) A MultiPolygon may not have cut lines, spikes or punctures, a
    # MultiPolygon is a regular closed Point set:
    #
    # e) The interior of a MultiPolygon with more than 1 Polygon is not
    # connected, the number of connected components of the interior of a
    # MultiPolygon is equal to the number of Polygons in the MultiPolygon.
    #
    # The boundary of a MultiPolygon is a set of closed Curves
    # (LineStrings) corresponding to the boundaries of its element
    # Polygons. Each Curve in the boundary of the MultiPolygon is in the
    # boundary of exactly 1 element Polygon, and every Curve in the
    # boundary of an element Polygon is in the boundary of the
    # MultiPolygon.
    #
    # NOTE: The subclass of Surface named Polyhedral Surface is a faceted
    # Surface whose facets are Polygons. A Polyhedral Surface is not a
    # MultiPolygon because it violates the rule for MultiPolygons that the
    # boundaries of the element Polygons intersect only at a finite number
    # of Points.
    #
    # == Notes
    #
    # MultiPolygon is defined as a module and is provided primarily
    # for the sake of documentation. Implementations need not necessarily
    # include this module itself. Therefore, you should not depend on the
    # kind_of? method to check type. Instead, use the provided check_type
    # class method (or === operator) defined in the Type module.

    module MultiPolygon
      include MultiSurface
      extend Type
    end
  end
end
