# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# A projected window in a geography implementation
#
# -----------------------------------------------------------------------------

module RGeo
  module Geographic
    # This object represents an axis-aligned rectangle in a map projection
    # coordinate system. It is commonly used to specify the viewport for a
    # map visualization, an envelope in a projected coordinate system, or
    # a spatial constraint. It must be attached to a Geographic::Factory
    # that has a projection.
    class ProjectedWindow
      # Create a new ProjectedWindow given the Geographic::Factory, and the
      # x and y extents of the rectangle.
      #
      # The window will be intelligently clamped to the limits imposed by
      # the factory. For example, the simple mercator factory limits
      # latitude to approximately +/-85 degrees.
      #
      # Generally, you will not need to call this low-level constructor
      # directly. Instead, use one of the provided class methods.

      def initialize(factory_, x_min_, y_min_, x_max_, y_max_, opts_ = {})
        @factory = factory_
        limits_ = opts_[:is_limits] ? nil : factory_.projection_limits_window
        wraps_ = factory_.projection_wraps?
        y_max_, y_min_ = y_min_, y_max_ if y_max_ < y_min_
        x_max_, x_min_ = x_min_, x_max_ if x_max_ < x_min_ && !wraps_
        if limits_
          y_max_ = limits_.y_max if y_max_ > limits_.y_max
          y_min_ = limits_.y_min if y_min_ < limits_.y_min
          if wraps_
            width_ = limits_.x_span
            if x_max_ - x_min_ > width_
              center_ = (x_max_ + x_min_) * 0.5
              x_min_ = center_ - width_ * 0.499999999
              x_max_ = center_ + width_ * 0.499999999
            end
            x_max_ = x_max_ % width_
            x_max_ -= width_ if x_max_ >= limits_.x_max
            x_min_ = x_min_ % width_
            x_min_ -= width_ if x_min_ >= limits_.x_max
          else
            x_max_ = limits_.x_max if x_max_ > limits_.x_max
            x_min_ = limits_.x_min if x_min_ < limits_.x_min
          end
        end
        @x_min = x_min_
        @y_min = y_min_
        @x_max = x_max_
        @y_max = y_max_
      end

      def to_s # :nodoc:
        "#<#{self.class}:0x#{object_id.to_s(16)} s=#{@y_min} w=#{@x_min} n=#{@y_max} e=#{@x_max}>"
      end

      def inspect # :nodoc:
        to_s
      end

      def eql?(other) # :nodoc:
        return false unless other.is_a?(ProjectedWindow)
        @factory == other.factory && @x_min == other.x_min && @x_max == other.x_max &&
          @y_min = other.y_min && @y_max = other.y_max
      end
      alias == eql?

      def hash # :nodoc:
        [@factory, @x_min, @x_max, @y_min, @y_max].hash
      end

      # Returns the Geographic::Factory associated with this window.
      # Note that this factory is the overall geography factory, not the
      # projected factory (which can be obtained by calling
      # Geographic::Factory#projection_factory on this factory).
      attr_reader :factory

      # Returns the lower limit in the x (easting) direction.
      attr_reader :x_min

      # Returns the upper limit in the x (easting) direction.
      attr_reader :x_max

      # Returns the lower limit in the y (northing) direction.
      attr_reader :y_min

      # Returns the upper limit in the y (northing) direction.
      attr_reader :y_max

      # Returns true if the projection wraps along the x axis, and this
      # rectangle crosses that seam.

      def crosses_seam?
        @x_max < @x_min
      end

      # Returns true if the rectangle has zero area.

      def degenerate?
        @x_min == @x_max || @y_min == @y_max
      end

      # Returns the width of the rectangle.

      def x_span
        span_ = @x_max - @x_min
        span_ += @factory.projection_limits_window.x_span if span_ < 0
        span_
      end
      alias width x_span

      # Returns the height of the rectangle.

      def y_span
        @y_max - @y_min
      end
      alias height y_span

      # Returns a two-element array containing the x and y coordinates
      # of the center of the rectangle.

      def center_xy
        y_ = (@y_min + @y_max) * 0.5
        if @x_min > @x_max
          x_ = @x_min + x_span * 0.5
          limits_ = @factory.projection_limits_window
          x_ -= limits_.x_span if x_ >= limits_.x_max
        else
          x_ = (@x_min + @x_max) * 0.5
        end
        [x_, y_]
      end

      # Returns the southwest corner of the rectangle in _unprojected_
      # (lat/lng) space, as a Feature::Point object.

      def sw_point
        return @sw_point if defined?(@sw_point)

        @sw_point = @factory.unproject(@factory.projection_factory.point(@x_min, @y_min))
      end

      # Returns the southeast corner of the rectangle in _unprojected_
      # (lat/lng) space, as a Feature::Point object.

      def se_point
        return @se_point if defined?(@se_point)

        @se_point = @factory.unproject(@factory.projection_factory.point(@x_max, @y_min))
      end

      # Returns the northwest corner of the rectangle in _unprojected_
      # (lat/lng) space, as a Feature::Point object.

      def nw_point
        return @nw_point if defined?(@nw_point)

        @nw_point = @factory.unproject(@factory.projection_factory.point(@x_min, @y_max))
      end

      # Returns the northeast corner of the rectangle in _unprojected_
      # (lat/lng) space, as a Feature::Point object.

      def ne_point
        return @ne_point if defined?(@ne_point)

        @ne_point = @factory.unproject(@factory.projection_factory.point(@x_max, @y_max))
      end

      # Returns the center of the rectangle in _unprojected_
      # (lat/lng) space, as a Feature::Point object.

      def center_point
        return @center_point if defined?(@center_point)

        @center_point = @factory.unproject(@factory.projection_factory.point(*center_xy))
      end

      # Returns a random point inside the rectangle in _unprojected_
      # (lat/lng) space, as a Feature::Point object.

      def random_point
        y_ = @y_min + y_span * rand
        x_ = @x_min + x_span * rand
        limits_ = @factory.projection_limits_window
        x_ -= limits_.x_span if x_ >= limits_.x_max
        @factory.unproject(@factory.projection_factory.point(x_, y_))
      end

      # Returns true if the rectangle contains the given point, which
      # must be a Feature::Point in _unprojected_ (lat/lng) space.

      def contains_point?(point_)
        projection_ = @factory.project(point_)
        y_ = projection_.y
        if y_ <= @y_max && y_ >= @y_min
          x_ = projection_.x
          limits_ = @factory.projection_limits_window
          width_ = limits_.x_span
          x_ = x_ % width_
          x_ -= width_ if x_ >= limits_.x_max
          if @x_max < @x_min
            x_ <= @x_max || x_ >= @x_min
          else
            x_ <= @x_max && x_ >= @x_min
          end
        else
          false
        end
      end

      # Returns true if the given window is completely contained within
      # this window.

      def contains_window?(window_)
        return if window_.factory != @factory
        if window_.y_max <= @y_max && window_.y_min >= @y_min
          if (@x_max < @x_min) == window_.crosses_seam?
            window_.x_max <= @x_max && window_.x_min >= @x_min
          else
            @x_max < @x_min && (window_.x_max <= @x_max || window_.x_min >= @x_min)
          end
        else
          false
        end
      end

      # Returns a new window resulting from scaling this window by the
      # given factors, which must be floating-point values.
      # If y_factor is not explicitly given, it defaults to the same as
      # the x_factor.

      def scaled_by(x_factor_, y_factor_ = nil)
        y_factor_ ||= x_factor_
        if x_factor_ != 1 || y_factor_ != 1
          x_, y_ = *center_xy
          xr_ = x_span * 0.5 * x_factor_
          yr_ = y_span * 0.5 * y_factor_
          ProjectedWindow.new(@factory, x_ - xr_, y_ - yr_, x_ + xr_, y_ + yr_)
        else
          self
        end
      end
      alias * scaled_by

      # Returns a new window resulting from clamping this window to the
      # given minimum and maximum widths and heights, in the projected
      # coordinate system. The center of the resulting window is the
      # same as the center of this window. Any of the arguments may be
      # given as nil, indicating no constraint.

      def clamped_by(min_width_, min_height_, max_width_, max_height_)
        xr_ = x_span
        yr_ = y_span
        changed_ = false
        if min_width_ && xr_ < min_width_
          changed_ = true
          xr_ = min_width_
        end
        if max_width_ && xr_ > max_width_
          changed_ = true
          xr_ = max_width_
        end
        if min_height_ && yr_ < min_height_
          changed_ = true
          yr_ = min_height_
        end
        if max_height_ && yr_ > max_height_
          changed_ = true
          yr_ = max_height_
        end
        if changed_
          x_, y_ = *center_xy
          xr_ *= 0.5
          yr_ *= 0.5
          ProjectedWindow.new(@factory, x_ - xr_, y_ - yr_, x_ + xr_, y_ + yr_)
        else
          self
        end
      end

      # Returns a new window resulting from adding the given margin to
      # this window. If y_margin is not given, it defaults to the same
      # value as x_margin. Note that the margins may be negative to
      # indicate shrinking of the window.

      def with_margin(x_margin_, y_margin_ = nil)
        y_margin_ ||= x_margin_
        if x_margin_ != 0 || y_margin_ != 0
          ProjectedWindow.new(
            @factory,
            @x_min - x_margin_,
            @y_min - y_margin_,
            @x_max + x_margin_,
            @y_max + y_margin_
          )
        else
          self
        end
      end

      class << self
        # Creates a new window whose coordinates are the given points,
        # which must be Feature::Point objects in unprojected (lat/lng)
        # space.

        def for_corners(sw_, ne_)
          factory_ = sw_.factory
          psw_ = factory_.project(sw_)
          pne_ = factory_.project(ne_)
          ProjectedWindow.new(factory_, psw_.x, psw_.y, pne_.x, pne_.y)
        end

        # Creates a new window that surrounds the given point with the
        # given margin. The point must be a Feature::Point object in
        # unprojected (lat/lng) space, while the margins are numbers in
        # projected space. The y_margin may be given as nil, in which
        # case it is set to the same as the x_margin.

        def surrounding_point(point_, x_margin_ = nil, y_margin_ = nil)
          x_margin_ ||= 0.0
          y_margin_ ||= x_margin_
          factory_ = point_.factory
          projection_ = factory_.project(point_)
          ProjectedWindow.new(
            factory_,
            projection_.x - x_margin_,
            projection_.y - y_margin_,
            projection_.x + x_margin_,
            projection_.y + y_margin_
          )
        end

        # Creates a new window that contains all of the given points.
        # which must be Feature::Point objects in unprojected (lat/lng)
        # space.

        def bounding_points(points_)
          factory_ = nil
          limits_ = nil
          width_ = nil
          x_max_ = nil
          x_min_ = nil
          y_max_ = nil
          y_min_ = nil
          x_array_ = nil
          points_.each do |p_|
            unless factory_
              factory_ = p_.factory
              limits_ = factory_.projection_limits_window
              width_ = limits_.x_span
              x_array_ = [] if factory_.projection_wraps?
            end
            proj_ = factory_.project(p_)
            x_ = proj_.x
            if x_array_
              x_ = x_ % width_
              x_ -= width_ if x_ >= limits_.x_max
              x_array_ << x_
            else
              x_max_ = x_ if !x_max_ || x_max_ < x_
              x_min_ = x_ if !x_min_ || x_min_ > x_
            end
            y_ = proj_.y
            y_max_ = y_ if !y_max_ || y_max_ < y_
            y_min_ = y_ if !y_min_ || y_min_ > y_
          end
          return unless factory_
          if x_array_
            x_array_.sort!
            largest_span_ = nil
            last_ = x_array_.last
            x_array_.each do |x_|
              if largest_span_
                span_ = x_ - last_
                if span_ > largest_span_
                  largest_span_ = span_
                  x_min_ = x_
                  x_max_ = last_
                end
              else
                largest_span_ = x_ - last_ + width_
                x_min_ = x_
                x_max_ = last_
              end
              last_ = x_
            end
          end
          ProjectedWindow.new(factory_, x_min_, y_min_, x_max_, y_max_)
        end
      end
    end
  end
end
