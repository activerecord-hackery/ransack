# frozen_string_literal: true

require "set"

module RGeo
  module ImplHelper
    # Mixin based off of the JTS/GEOS IsValidOp class.
    # Implements #valid? and #invalid_reason on Features that include this.
    #
    # @see https://github.com/locationtech/jts/blob/master/modules/core/src/main/java/org/locationtech/jts/operation/valid/IsValidOp.java
    module ValidOp
      # Validity of geometry
      #
      # @return Boolean
      def valid?
        invalid_reason.nil?
      end

      # Reason for invalidity or nil if valid
      #
      # @return String
      def invalid_reason
        return @invalid_reason if defined?(@invalid_reason)
        @invalid_reason = check_valid
      end

      private

      def validity_helper
        ValidOpHelpers
      end

      # Method that performs validity checking. Just checks the type of geometry
      # and delegates to the proper validity checker.
      #
      # Returns a string describing the error or nil if it's a valid geometry.
      # In some cases, "Unkown Validity" is returned if a dependent method has
      # not been implemented.
      #
      # @return String
      def check_valid
        case self
        when Feature::Point
          check_valid_point
        when Feature::LinearRing
          check_valid_linear_ring
        when Feature::LineString
          check_valid_line_string
        when Feature::Polygon
          check_valid_polygon
        when Feature::MultiPoint
          check_valid_multi_point
        when Feature::MultiPolygon
          check_valid_multi_polygon
        when Feature::GeometryCollection
          check_valid_geometry_collection
        else
          raise NotImplementedError, "check_valid is not implemented for #{self}"
        end
      rescue RGeo::Error::UnsupportedOperation, NoMethodError
        "Unkown Validity"
      end

      def check_valid_point
        validity_helper.check_invalid_coordinate(self)
      end

      def check_valid_line_string
        # check coordinates are all valid
        points.each do |pt|
          check = validity_helper.check_invalid_coordinate(pt)
          return check unless check.nil?
        end

        # check more than 1 point
        return Error::TOO_FEW_POINTS unless num_points > 1

        nil
      end

      def check_valid_linear_ring
        # check coordinates are all valid
        points.each do |pt|
          check = validity_helper.check_invalid_coordinate(pt)
          return check unless check.nil?
        end

        # check closed
        return Error::UNCLOSED_RING unless closed?

        # check more than 3 points
        return Error::TOO_FEW_POINTS unless num_points > 3

        # check no self-intersections
        validity_helper.check_no_self_intersections(self)
      end

      def check_valid_polygon
        # check coordinates are all valid
        exterior_ring.points.each do |pt|
          check = validity_helper.check_invalid_coordinate(pt)
          return check unless check.nil?
        end
        interior_rings.each do |ring|
          ring.points.each do |pt|
            check = validity_helper.check_invalid_coordinate(pt)
            return check unless check.nil?
          end
        end

        # check closed
        return Error::UNCLOSED_RING unless exterior_ring.closed?
        return Error::UNCLOSED_RING unless interior_rings.all?(&:closed?)

        # check more than 3 points in each ring
        return Error::TOO_FEW_POINTS unless exterior_ring.num_points > 3
        return Error::TOO_FEW_POINTS unless interior_rings.all? { |r| r.num_points > 3 }

        # can skip this check if there's no holes
        unless interior_rings.empty?
          check = validity_helper.check_consistent_area(self)
          return check unless check.nil?
        end

        # check that there are no self-intersections
        check = validity_helper.check_no_self_intersecting_rings(self)
        return check unless check.nil?

        # can skip these checks if there's no holes
        unless interior_rings.empty?
          check = validity_helper.check_holes_in_shell(self)
          return check unless check.nil?

          check = validity_helper.check_holes_not_nested(self)
          return check unless check.nil?

          check = validity_helper.check_connected_interiors(self)
          return check unless check.nil?
        end

        nil
      end

      def check_valid_multi_point
        geometries.each do |pt|
          check = validity_helper.check_invalid_coordinate(pt)
          return check unless check.nil?
        end
        nil
      end

      def check_valid_multi_polygon
        geometries.each do |poly|
          return poly.invalid_reason unless poly.invalid_reason.nil?
        end

        check = validity_helper.check_consistent_area_mp(self)
        return check unless check.nil?

        # check no shells are nested
        check = validity_helper.check_shells_not_nested(self)
        return check unless check.nil?

        nil
      end

      def check_valid_geometry_collection
        geometries.each do |geom|
          return geom.invalid_reason unless geom.invalid_reason.nil?
        end

        nil
      end
    end

    ##
    # Helper functions for specific validity checks
    ##
    module ValidOpHelpers
      module_function

      # Checks that the given point has valid coordinates.
      #
      # @param point [RGeo::Feature::Point]
      #
      # @return [String] invalid_reason
      def check_invalid_coordinate(point)
        x = point.x
        y = point.y
        return if x.finite? && y.finite? && x.real? && y.real?

        Error::INVALID_COORDINATE
      end

      # Checks that the edges in the polygon form a consistent area.
      #
      # Specifically, checks that there are intersections no between the
      # holes and the shell.
      #
      # Also checks that there are no duplicate rings.
      #
      # @param poly [RGeo::Feature::Polygon]
      #
      # @return [String] invalid_reason
      def check_consistent_area(poly)
        # Holes don't cross exterior check.
        exterior = poly.exterior_ring
        poly.interior_rings.each do |ring|
          return Error::SELF_INTERSECTION if ring.crosses?(exterior)
        end

        # check interiors do not cross
        poly.interior_rings.combination(2).each do |ring1, ring2|
          return Error::SELF_INTERSECTION if ring1.crosses?(ring2)
        end

        # Duplicate rings check
        rings = [exterior] + poly.interior_rings
        return Error::SELF_INTERSECTION if rings.uniq.size != rings.size

        nil
      end

      # Checks that the ring does not self-intersect. This is just a simplicity
      # check on the ring.
      #
      # @param ring [RGeo::Feature::LinearRing]
      #
      # @return [String] invalid_reason
      def check_no_self_intersections(ring)
        return Error::SELF_INTERSECTION unless ring.simple?
      end

      # Check that rings do not self intersect in a polygon
      #
      # @param poly [RGeo::Feature::Polygon]
      #
      # @return [String] invalid_reason
      def check_no_self_intersecting_rings(poly)
        exterior = poly.exterior_ring

        check = check_no_self_intersections(exterior)
        return check unless check.nil?

        poly.interior_rings.each do |ring|
          check = check_no_self_intersections(ring)
          return check unless check.nil?
        end

        nil
      end

      # Checks holes are contained inside the exterior of a polygon.
      # Assuming check_consistent_area has already passed on the polygon,
      # a simple point in polygon check can be done on one of the points
      # in each hole to verify (since we know none of them intersect).
      #
      # @param poly [RGeo::Feature::Polygon]
      #
      # @return [String] invalid_reason
      def check_holes_in_shell(poly)
        # get hole-less shell as test polygon
        shell = poly.exterior_ring
        shell = shell.factory.polygon(shell)

        poly.interior_rings.each do |interior|
          test_pt = interior.start_point
          return Error::HOLE_OUTSIDE_SHELL unless shell.contains?(test_pt) || poly.exterior_ring.contains?(test_pt)
        end

        nil
      end

      # Checks that holes are not nested within each other.
      #
      # @param poly [RGeo::Feature::Polygon]
      #
      # @return [String] invalid_reason
      def check_holes_not_nested(poly)
        # convert holes from linear_rings to polygons
        # Same logic that applies to check_holes_in_shell applies here
        # since we've already passed the consistent area test, we just
        # have to check if one point from each hole is contained in the other.
        holes = poly.interior_rings
        holes = holes.map { |v| v.factory.polygon(v) }
        holes.combination(2).each do |p1, p2|
          if p1.contains?(p2.exterior_ring.start_point) || p2.contains?(p1.exterior_ring.start_point)
            return Error::NESTED_HOLES
          end
        end

        nil
      end

      # Checks that the interior of the polygon is connected.
      # A disconnected interior can be described by this polygon for example
      # POLYGON((0 0, 10 0, 10 10, 0 10, 0 0), (5 0, 10 5, 5 10, 0 5, 5 0))
      #
      # Which is a square with a diamond inside of it.
      #
      # @param poly [RGeo::Feature::Polygon]
      #
      # @return [String] invalid_reason
      def check_connected_interiors(poly)
        # This is not proper and will flag valid geometries as invalid, but
        # is an ok approximation.
        # Idea is to check if a single hole has multiple points on the
        # exterior ring.
        poly.interior_rings.each do |ring|
          touches = Set.new
          ring.points.each do |pt|
            touches.add(pt) if poly.exterior_ring.contains?(pt)
          end

          return Error::DISCONNECTED_INTERIOR if touches.size > 1
        end

        nil
      end

      # Checks that polygons do not intersect in a multipolygon.
      #
      # @param mpoly [RGeo::Feature::MultiPolygon]
      #
      # @return [String] invalid_reason
      def check_consistent_area_mp(mpoly)
        mpoly.geometries.combination(2) do |p1, p2|
          return Error::SELF_INTERSECTION if p1.exterior_ring.crosses?(p2.exterior_ring)
        end
        nil
      end

      # Checks that individual polygons within a multipolygon are not nested.
      #
      # @param mpoly [RGeo::Feature::MultiPolygon]
      #
      # @return [String] invalid_reason
      def check_shells_not_nested(mpoly)
        # Since we've passed the consistent area test, we can just check
        # that one point lies in the other.
        mpoly.geometries.combination(2) do |p1, p2|
          if p1.contains?(p2.exterior_ring.start_point) || p2.contains?(p1.exterior_ring.start_point)
            return Error::NESTED_SHELLS
          end
        end
        nil
      end
    end
  end
end
