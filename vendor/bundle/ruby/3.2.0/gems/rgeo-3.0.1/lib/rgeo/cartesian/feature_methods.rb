# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Cartesian common methods
#
# -----------------------------------------------------------------------------

module RGeo
  module Cartesian
    module GeometryMethods # :nodoc:
      def srid
        factory.srid
      end

      def envelope
        BoundingBox.new(factory).add(self).to_geometry
      end

      def coordinate_dimension
        factory.coordinate_dimension
      end

      def spatial_dimension
        factory.spatial_dimension
      end

      def is_3d?
        factory.property(:has_z_coordinate)
      end

      def measured?
        factory.property(:has_m_coordinate)
      end

      private

      def graph
        @graph ||= GeometryGraph.new(self)
      end
    end

    module PointMethods # :nodoc:
      def distance(rhs)
        rhs = RGeo::Feature.cast(rhs, @factory)
        case rhs
        when PointImpl
          dx = @x - rhs.x
          dy = @y - rhs.y
          Math.sqrt(dx * dx + dy * dy)
        else
          super
        end
      end

      def buffer(distance)
        point_count = factory.property(:buffer_resolution) * 4
        angle = -::Math::PI * 2.0 / point_count
        points = (0...point_count).map do |i|
          r = angle * i
          factory.point(@x + distance * Math.cos(r), @y + distance * Math.sin(r))
        end
        factory.polygon(factory.linear_ring(points))
      end
    end

    module LineStringMethods # :nodoc:
      def segments
        @segments ||= (0..num_points - 2).map do |i|
          Segment.new(point_n(i), point_n(i + 1))
        end
      end

      def simple?
        # Use a SweeplineIntersector to determine if there are any self-intersections
        # in the ring. The GeometryGraph of the ring could be used by comparing the
        # edges to number of segments (graph.incident_edges.length == segments.length),
        # but this adds computational and memory overhead if graph isn't already memoized.
        # Since graph is not used elsewhere in LineStringMethods, we will just use the
        # SweeplineIntersector for now.
        li = SweeplineIntersector.new(segments)
        li.proper_intersections.empty?
      end

      def length
        segments.inject(0.0) { |sum, seg| sum + seg.length }
      end

      def crosses?(rhs)
        case rhs
        when Feature::LineString
          crosses_line_string?(rhs)
        else
          super
        end
      end

      private

      # Determines if a cross occurs with another linestring.
      # Process is to get the number of proper intersections in each geom
      # then overlay and get the number of proper intersections from that.
      # If the overlaid number is higher than the sum of individual self-ints
      # then there is an intersection. Finally, we need to check the intersection
      # to see that it is not a boundary point of either segment.
      #
      # @param rhs [Feature::LineString]
      #
      # @return [Boolean]
      def crosses_line_string?(rhs)
        self_ints = SweeplineIntersector.new(segments).proper_intersections
        self_ints += SweeplineIntersector.new(rhs.segments).proper_intersections
        overlay_ints = SweeplineIntersector.new(segments + rhs.segments).proper_intersections

        (overlay_ints - self_ints).each do |int|
          s1s = int.s1.s
          s1e = int.s1.e
          s2s = int.s2.s
          s2e = int.s2.e
          return true unless [s1s, s1e, s2s, s2e].include?(int.point)
        end

        false
      end
    end

    module MultiLineStringMethods # :nodoc:
      def length
        inject(0.0) { |sum, geom| sum + geom.length }
      end
    end
  end
end
