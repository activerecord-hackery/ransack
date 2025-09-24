# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Spherical geographic common methods
#
# -----------------------------------------------------------------------------

module RGeo
  module Geographic
    module SphericalGeometryMethods # :nodoc:
      def srid
        factory.srid
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
    end

    module SphericalPointMethods # :nodoc:
      def xyz
        @xyz ||= SphericalMath::PointXYZ.from_latlon(@y, @x)
      end

      def distance(rhs)
        rhs = Feature.cast(rhs, @factory)
        case rhs
        when SphericalPointImpl
          xyz.dist_to_point(rhs.xyz) * SphericalMath::RADIUS
        else
          super
        end
      end

      def equals?(rhs)
        return false unless rhs.is_a?(self.class) && rhs.factory == factory
        case rhs
        when Feature::Point
          case @y
          when 90
            rhs.y == 90
          when -90
            rhs.y == -90
          else
            rhs.x == @x && rhs.y == @y
          end
        when Feature::LineString
          rhs.num_points > 0 && rhs.points.all? { |elem| equals?(elem) }
        when Feature::GeometryCollection
          rhs.num_geometries > 0 && rhs.all? { |elem| equals?(elem) }
        else
          false
        end
      end

      def buffer(distance)
        radius = distance / SphericalMath::RADIUS
        radius = 1.5 if radius > 1.5
        cos = Math.cos(radius)
        sin = Math.sin(radius)
        point_count = factory.property(:buffer_resolution) * 4
        p0 = xyz
        p1 = p0.create_perpendicular
        p2 = p1 % p0
        angle = Math::PI * 2.0 / point_count
        points = (0...point_count).map do |i|
          r = angle * i
          pi = SphericalMath::PointXYZ.weighted_combination(p1, Math.cos(r), p2, Math.sin(r))
          p = SphericalMath::PointXYZ.weighted_combination(p0, cos, pi, sin)
          factory.point(*p.lonlat)
        end
        factory.polygon(factory.linear_ring(points))
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
        if @x < -180.0 || @x > 180.0
          @x = @x % 360.0
          @x -= 360.0 if @x > 180.0
        end
        @y = 90.0 if @y > 90.0
        @y = -90.0 if @y < -90.0
        super
      end
    end

    module SphericalLineStringMethods # :nodoc:
      def arcs
        @arcs ||= (0..num_points - 2).map do |i|
          SphericalMath::ArcXYZ.new(point_n(i).xyz, point_n(i + 1).xyz)
        end
      end

      def simple?
        len = arcs.length
        return false if arcs.any?(&:degenerate?)
        return true if len == 1
        return arcs[0].s != arcs[1].e if len == 2
        arcs.each_with_index do |arc, index|
          nindex = index + 1
          nindex = nil if nindex == len
          return false if nindex && arc.contains_point?(arcs[nindex].e)
          pindex = index - 1
          pindex = nil if pindex < 0
          return false if pindex && arc.contains_point?(arcs[pindex].s)
          next unless nindex
          oindex = nindex + 1
          while oindex < len
            oarc = arcs[oindex]
            return false if !(index == 0 && oindex == len - 1 && arc.s == oarc.e) && arc.intersects_arc?(oarc)
            oindex += 1
          end
        end
        true
      end

      def length
        arcs.inject(0.0) { |sum, arc| sum + arc.length } * SphericalMath::RADIUS
      end

      def intersects?(rhs)
        case rhs
        when Feature::LineString
          intersects_line_string?(rhs)
        else
          super
        end
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

      # TODO: replace with better algorithm (https://github.com/rgeo/rgeo/issues/274)
      # Very simple algorithm to determine if 2 LineStrings intersect.
      # Uses a nested for loop to look at each arc in the LineStrings and
      # check if each arc intersects.
      #
      # @param [RGeo::Geographic::SphericalLineStringImpl] rhs
      #
      # @return [Boolean]
      def intersects_line_string?(rhs)
        arcs.each do |arc|
          rhs.arcs.each do |rhs_arc|
            return true if arc.intersects_arc?(rhs_arc)
          end
        end

        false
      end

      # TODO: replace with better algorithm (https://github.com/rgeo/rgeo/issues/274)
      # Very simple algorithm to determine if 2 LineStrings cross.
      # Uses a nested for loop to look at each arc in the LineStrings and
      # check if each arc crosses.
      #
      # @param [RGeo::Geographic::SphericalLineStringImpl] rhs
      #
      # @return [Boolean]
      def crosses_line_string?(rhs)
        arcs.each do |arc|
          rhs.arcs.each do |rhs_arc|
            next unless arc.intersects_arc?(rhs_arc)

            # check that endpoints aren't the intersection point
            is_endpoint = arc.contains_point?(rhs_arc.s) ||
              arc.contains_point?(rhs_arc.e) ||
              rhs_arc.contains_point?(arc.s) ||
              rhs_arc.contains_point?(arc.e)

            return true unless is_endpoint
          end
        end

        false
      end
    end

    module SphericalMultiLineStringMethods # :nodoc:
      def length
        inject(0.0) { |sum, geom| sum + geom.length }
      end
    end

    module SphericalPolygonMethods # :nodoc:
      def centroid
        return super unless num_interior_rings == 0

        centroid_lat = 0.0
        centroid_lng = 0.0
        signed_area = 0.0

        exterior_ring.points.each_cons(2) do |p0, p1|
          area = (p0.x * p1.y) - (p1.x * p0.y)
          signed_area += area
          centroid_lat += (p0.x + p1.x) * area
          centroid_lng += (p0.y + p1.y) * area
        end

        signed_area *= 0.5
        centroid_lat /= (6.0 * signed_area)
        centroid_lng /= (6.0 * signed_area)

        factory.point(centroid_lat, centroid_lng)
      end
    end
  end
end
