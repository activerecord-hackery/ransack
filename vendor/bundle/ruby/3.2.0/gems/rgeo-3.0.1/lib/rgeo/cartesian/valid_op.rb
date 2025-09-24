# frozen_string_literal: true

module RGeo
  module Cartesian
    module ValidOp
      include ImplHelper::ValidOp

      def validity_helper
        ValidOpHelpers
      end
    end

    module ValidOpHelpers
      include ImplHelper::ValidOpHelpers

      module_function(*ImplHelper::ValidOpHelpers.singleton_methods) # rubocop:disable Style/AccessModifierDeclarations

      module_function

      # Checks that there are no invalid intersections between the components
      # of a polygon.
      #
      # @param [RGeo::Feature::Polygon] poly
      #
      # @return [String] invalid_reason
      def check_consistent_area(poly)
        # Get set of unique coords
        pts = poly.exterior_ring.coordinates.to_set
        poly.interior_rings.each do |ring|
          pts += ring.coordinates
        end
        num_points = pts.size

        # if additional nodes were added, there must be an intersection
        # through a boundary.
        return Error::SELF_INTERSECTION if poly.send(:graph).incident_edges.size > num_points

        rings = [poly.exterior_ring] + poly.interior_rings
        return Error::SELF_INTERSECTION if rings.uniq.size != rings.size

        nil
      end

      # Checks that the interior of a polygon is connected.
      #
      # Process to do this is to walk around an interior cycle of the
      # exterior shell in the polygon's geometry graph. It will keep track
      # of all the nodes it visited and if that set is a superset of the
      # coordinates in the exterior_ring, the interior is connected, otherwise
      # it is split somewhere.
      #
      # @param [RGeo::Feature::Polygon] poly
      #
      # @return [String] invalid_reason
      def check_connected_interiors(poly)
        exterior_coords = poly.exterior_ring.coordinates.to_set

        visited = Set.new
        poly.send(:graph).geom_edges.first.exterior_edge.and_connected do |hedge|
          visited << hedge.origin.coordinates
        end

        return Error::DISCONNECTED_INTERIOR unless exterior_coords.subset?(visited)

        nil
      end
    end
  end
end
