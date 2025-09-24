# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Projected geographic common method definitions
#
# -----------------------------------------------------------------------------

module RGeo
  module Geographic
    module ProjectedGeometryMethods # :nodoc:
      def srid
        factory.srid
      end

      def projection
        @projection = factory.project(self) unless defined?(@projection)
        @projection
      end

      def envelope
        factory.unproject(projection.unsafe_envelope)
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

      def empty?
        projection.empty?
      end

      def simple?
        projection.simple?
      end

      def valid?
        projection.valid?
      end

      def invalid_reason
        projection.invalid_reason
      end

      # (see RGeo::ImplHelper::ValidityCheck#make_valid)
      def make_valid
        factory.unproject projection.make_valid
      end

      def boundary
        boundary = projection.unsafe_boundary
        boundary ? factory.unproject(boundary) : nil
      end

      def equals?(rhs)
        projection.equals?(Feature.cast(rhs, factory).projection)
      end

      def disjoint?(rhs)
        projection.unsafe_disjoint?(Feature.cast(rhs, factory).projection)
      end

      def intersects?(rhs)
        projection.unsafe_intersects?(Feature.cast(rhs, factory).projection)
      end

      def touches?(rhs)
        projection.unsafe_touches?(Feature.cast(rhs, factory).projection)
      end

      def crosses?(rhs)
        projection.unsafe_crosses?(Feature.cast(rhs, factory).projection)
      end

      def within?(rhs)
        projection.unsafe_within?(Feature.cast(rhs, factory).projection)
      end

      def contains?(rhs)
        projection.unsafe_contains?(Feature.cast(rhs, factory).projection)
      end

      def overlaps?(rhs)
        projection.unsafe_overlaps?(Feature.cast(rhs, factory).projection)
      end

      def relate(rhs, pattern_)
        projection.unsafe_relate(Feature.cast(rhs, factory).projection, pattern_)
      end

      def distance(rhs)
        projection.unsafe_distance(Feature.cast(rhs, factory).projection)
      end

      def buffer(distance)
        factory.unproject(projection.unsafe_buffer(distance))
      end

      def buffer_with_style(distance, end_cap_style, join_style, mitre_limit)
        factory.unproject(projection.unsafe_buffer_with_style(distance, end_cap_style, join_style, mitre_limit))
      end

      def simplify(tolerance)
        factory.unproject(projection.unsafe_simplify(tolerance))
      end

      def simplify_preserve_topology(tolerance)
        factory.unproject(projection.unsafe_simplify_preserve_topology(tolerance))
      end

      def convex_hull
        factory.unproject(projection.unsafe_convex_hull)
      end

      def intersection(rhs)
        factory.unproject(projection.unsafe_intersection(Feature.cast(rhs, factory).projection))
      end

      def union(rhs)
        factory.unproject(projection.unsafe_union(Feature.cast(rhs, factory).projection))
      end

      def difference(rhs)
        factory.unproject(projection.unsafe_difference(Feature.cast(rhs, factory).projection))
      end

      def sym_difference(rhs)
        factory.unproject(projection.unsafe_sym_difference(Feature.cast(rhs, factory).projection))
      end

      def point_on_surface
        factory.unproject(projection.unsafe_point_on_surface)
      end
    end

    module ProjectedPointMethods # :nodoc:
      def canonical_x
        x_ = @x % 360.0
        x_ -= 360.0 if x_ > 180.0
        x_
      end
      alias canonical_longitude canonical_x
      alias canonical_lon canonical_x

      def canonical_point
        if @x >= -180.0 && @x < 180.0
          self
        else
          ProjectedPointImpl.new(@factory, canonical_x, @y)
        end
      end

      def self.included(klass)
        klass.module_eval do
          alias_method :longitude, :x
          alias_method :lon, :x
          alias_method :latitude, :y
          alias_method :lat, :y
        end
      end

      private

      # Ensure coordinates fall within a valid range.
      def init_geometry
        @y = 85.0511287 if @y > 85.0511287
        @y = -85.0511287 if @y < -85.0511287
        super
      end
    end

    module ProjectedNCurveMethods # :nodoc:
      def length
        projection.unsafe_length
      end
    end

    module ProjectedLineStringMethods # :nodoc:
      private

      # Ensure coordinates fall within a valid range.
      def init_geometry
        @points = @points.map(&:canonical_point)
        super
      end
    end

    module ProjectedLinearRingMethods # :nodoc:
      def simple?
        projection.valid?
      end
    end

    module ProjectedNSurfaceMethods # :nodoc:
      def area
        projection.unsafe_area
      end

      def centroid
        factory.unproject(projection.unsafe_centroid)
      end
    end

    module ProjectedPolygonMethods # :nodoc:
      private

      # Ensure projection is available.
      def init_geometry
        super
        raise Error::InvalidGeometry, "Polygon failed assertions" unless projection
      end
    end

    module ProjectedMultiPolygonMethods # :nodoc:
      private

      # Ensure projection is available.
      def init_geometry
        super
        raise Error::InvalidGeometry, "MultiPolygon failed assertions" unless projection
      end
    end
  end
end
