# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Core calculations on the sphere
#
# -----------------------------------------------------------------------------

module RGeo
  module Geographic
    module SphericalMath # :nodoc:
      RADIUS = 6_378_137.0

      # Represents a point on the unit sphere in (x,y,z) coordinates
      # instead of lat-lon. This form is often faster, more convenient,
      # and more numerically stable for certain computations.
      #
      # The coordinate system is a right-handed system where the z-axis
      # goes through the north pole, the x-axis goes through the prime
      # meridian, and the y-axis goes through +90 degrees longitude.
      #
      # This object is also used to represent a great circle, as its axis
      # of rotation.

      class PointXYZ # :nodoc:
        attr_reader :x, :y, :z

        def initialize(x, y, z)
          r = Math.sqrt(x * x + y * y + z * z)
          @x = (x / r).to_f
          @y = (y / r).to_f
          @z = (z / r).to_f
          raise "Not a number" if @x.nan? || @y.nan? || @z.nan?
        end

        def to_s
          "(#{@x}, #{@y}, #{@z})"
        end

        def eql?(other)
          other.is_a?(PointXYZ) && @x == other.x && @y == other.y && @z == other.z
        end
        alias == eql?

        def latlon
          lat_rad = Math.asin(@z)
          lon_rad = Math.atan2(@y, @x)
          rpd = ImplHelper::Math::RADIANS_PER_DEGREE
          [lat_rad / rpd, lon_rad / rpd]
        end

        def lonlat
          lat_rad = Math.asin(@z)
          lon_rad = Math.atan2(@y, @x)
          rpd = ImplHelper::Math::RADIANS_PER_DEGREE
          [lon_rad / rpd, lat_rad / rpd]
        end

        def *(other)
          val = @x * other.x + @y * other.y + @z * other.z
          val = 1.0 if val > 1.0
          val = -1.0 if val < -1.0
          val
        end

        def %(other)
          rx = other.x
          ry = other.y
          rz = other.z
          begin
            PointXYZ.new(@y * rz - @z * ry, @z * rx - @x * rz, @x * ry - @y * rx)
          rescue StandardError
            nil
          end
        end

        def dist_to_point(rhs)
          rx = rhs.x
          ry = rhs.y
          rz = rhs.z
          dot = @x * rx + @y * ry + @z * rz
          if dot > -0.8 && dot < 0.8
            Math.acos(dot)
          else
            x = @y * rz - @z * ry
            y = @z * rx - @x * rz
            z = @x * ry - @y * rx
            as = Math.asin(Math.sqrt(x * x + y * y + z * z))
            dot > 0.0 ? as : Math::PI - as
          end
        end

        # Creates some point that is perpendicular to this point

        def create_perpendicular
          p1dot = self * P1
          p2dot = self * P2
          p1dot = -p1dot if p1dot < 0
          p2dot = -p2dot if p2dot < 0
          p1dot < p2dot ? (self % P1) : (self % P2)
        end

        def self.from_latlon(lat, lon)
          rpd = ImplHelper::Math::RADIANS_PER_DEGREE
          lat_rad = rpd * lat
          lon_rad = rpd * lon
          z = Math.sin(lat_rad)
          r = Math.cos(lat_rad)
          x = Math.cos(lon_rad) * r
          y = Math.sin(lon_rad) * r
          new(x, y, z)
        end

        def self.weighted_combination(pt1, wt1, pt2, wt2)
          new(pt1.x * wt1 + pt2.x * wt2, pt1.y * wt1 + pt2.y * wt2, pt1.z * wt1 + pt2.z * wt2)
        end

        P1 = new(1, 0, 0)
        P2 = new(0, 1, 0)
      end

      # Represents a finite arc on the sphere.

      class ArcXYZ # :nodoc:
        attr_reader :s, :e

        def initialize(start, stop)
          @s = start
          @e = stop
          @axis = false
        end

        def to_s
          "#{@s} - #{@e}"
        end

        def eql?(other)
          other.is_a?(ArcXYZ) && @s == other.s && @e == other.e
        end
        alias == eql?

        def degenerate?
          my_axis = axis
          my_axis.x == 0 && my_axis.y == 0 && my_axis.z == 0
        end

        def axis
          @axis = @s % @e if @axis == false
          @axis
        end

        def contains_point?(obj)
          my_axis = axis
          s_axis = ArcXYZ.new(@s, obj).axis
          e_axis = ArcXYZ.new(obj, @e).axis
          !s_axis || !e_axis || obj * my_axis == 0 && s_axis * my_axis > 0 && e_axis * my_axis > 0
        end

        def intersects_arc?(obj)
          my_axis = axis
          dot1 = my_axis * obj.s
          dot2 = my_axis * obj.e
          if dot1 >= 0.0 && dot2 <= 0.0 || dot1 <= 0.0 && dot2 >= 0.0
            ob_axis = obj.axis
            dot1 = ob_axis * @s
            dot2 = ob_axis * @e
            dot1 >= 0.0 && dot2 <= 0.0 || dot1 <= 0.0 && dot2 >= 0.0
          else
            false
          end
        end

        def length
          @s.dist_to_point(@e)
        end
      end
    end
  end
end
