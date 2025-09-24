# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Cartesian bounding box
#
# -----------------------------------------------------------------------------

module RGeo
  module Cartesian
    # This is a bounding box for Cartesian data.
    # The simple cartesian implementation uses this internally to compute
    # envelopes. You may also use it directly to compute and represent
    # bounding boxes.
    #
    # A bounding box is a set of ranges in each dimension: X, Y, as well
    # as Z and M if supported. You can compute a bounding box for one or
    # more geometry objects by creating a new bounding box object, and
    # adding the geometries to it. You may then query it for the bounds,
    # or use it to determine whether it encloses other geometries or
    # bounding boxes.
    class BoundingBox
      # Returns the bounding box's factory.
      attr_reader :factory

      # Returns true if this bounding box tracks Z coordinates.
      attr_reader :has_z

      # Returns true if this bounding box tracks M coordinates.
      attr_reader :has_m

      # Returns the minimum X, or nil if this bounding box is empty.
      attr_reader :min_x

      # Returns the maximum X, or nil if this bounding box is empty.
      attr_reader :max_x

      # Returns the minimum Y, or nil if this bounding box is empty.
      attr_reader :min_y

      # Returns the maximum Y, or nil if this bounding box is empty.
      attr_reader :max_y

      # Returns the minimum Z, or nil if this bounding box is empty.
      attr_reader :min_z

      # Returns the maximum Z, or nil if this bounding box is empty.
      attr_reader :max_z

      # Returns the minimum M, or nil if this bounding box is empty.
      attr_reader :min_m

      # Returns the maximum M, or nil if this bounding box is empty.
      attr_reader :max_m

      # Create a bounding box given two corner points.
      # The bounding box will be given the factory of the first point.
      # You may also provide the same options available to
      # BoundingBox.new.

      def self.create_from_points(point1, point2, opts = {})
        factory = point1.factory
        new(factory, opts).add_geometry(point1).add(point2)
      end

      # Create a bounding box given a geometry to surround.
      # The bounding box will be given the factory of the geometry.
      # You may also provide the same options available to
      # BoundingBox.new.

      def self.create_from_geometry(geom, opts = {})
        factory = geom.factory
        new(factory, opts).add_geometry(geom)
      end

      # Create a new empty bounding box with the given factory.
      #
      # The factory defines the coordinate system for the bounding box,
      # and also defines whether it should track Z and M coordinates.
      # All geometries will be cast to this factory when added to this
      # bounding box, and any generated envelope geometry will have this
      # as its factory.
      #
      # Options include:
      #
      # [<tt>:ignore_z</tt>]
      #   If true, ignore z coordinates even if the factory supports them.
      #   Default is false.
      # [<tt>:ignore_m</tt>]
      #   If true, ignore m coordinates even if the factory supports them.
      #   Default is false.

      def initialize(factory, opts = {})
        @factory = factory
        if (values = opts[:raw])
          @has_z, @has_m, @min_x, @max_x, @min_y, @max_y, @min_z, @max_z, @min_m, @max_m = values
        else
          @has_z = !opts[:ignore_z] && factory.property(:has_z_coordinate) ? true : false
          @has_m = !opts[:ignore_m] && factory.property(:has_m_coordinate) ? true : false
          @min_x = @max_x = @min_y = @max_y = @min_z = @max_z = @min_m = @max_m = nil
        end
      end

      def eql?(other) # :nodoc:
        other.is_a?(BoundingBox) && @factory == other.factory &&
          @min_x == other.min_x && @max_x == other.max_x &&
          @min_y == other.min_y && @max_y == other.max_y &&
          @min_z == other.min_z && @max_z == other.max_z &&
          @min_m == other.min_m && @max_m == other.max_m
      end
      alias == eql?

      # Returns true if this bounding box is still empty.

      def empty?
        @min_x.nil?
      end

      # Returns true if this bounding box is degenerate. That is,
      # it is nonempty but contains only a single point because both
      # the X and Y spans are 0. Infinitesimal boxes are also
      # always degenerate.

      def infinitesimal?
        @min_x && @min_x == @max_x && @min_y == @max_y
      end

      # Returns true if this bounding box is degenerate. That is,
      # it is nonempty but has zero area because either or both
      # of the X or Y spans are 0.

      def degenerate?
        @min_x && (@min_x == @max_x || @min_y == @max_y)
      end

      # Returns the midpoint X, or nil if this bounding box is empty.

      def center_x
        @max_x ? (@max_x + @min_x) * 0.5 : nil
      end

      # Returns the X span, or 0 if this bounding box is empty.

      def x_span
        @max_x ? @max_x - @min_x : 0
      end

      # Returns the midpoint Y, or nil if this bounding box is empty.

      def center_y
        @max_y ? (@max_y + @min_y) * 0.5 : nil
      end

      # Returns the Y span, or 0 if this bounding box is empty.

      def y_span
        @max_y ? @max_y - @min_y : 0
      end

      # Returns the midpoint Z, or nil if this bounding box is empty or has no Z.

      def center_z
        @max_z ? (@max_z + @min_z) * 0.5 : nil
      end

      # Returns the Z span, 0 if this bounding box is empty, or nil if it has no Z.

      def z_span
        return unless @has_z

        return 0 unless @max_z

        @max_z - @min_z
      end

      # Returns the midpoint M, or nil if this bounding box is empty or has no M.

      def center_m
        @max_m ? (@max_m + @min_m) * 0.5 : nil
      end

      # Returns the M span, 0 if this bounding box is empty, or nil if it has no M.

      def m_span
        return unless @has_m

        return 0 unless @max_m

        @max_m - @min_m
      end

      # Returns a point representing the minimum extent in all dimensions,
      # or nil if this bounding box is empty.

      def min_point
        return unless @min_x

        extras = []
        extras << @min_z if @has_z
        extras << @min_m if @has_m

        @factory.point(@min_x, @min_y, *extras)
      end

      # Returns a point representing the maximum extent in all dimensions,
      # or nil if this bounding box is empty.

      def max_point
        return unless @min_x

        extras = []
        extras << @max_z if @has_z
        extras << @max_m if @has_m

        @factory.point(@max_x, @max_y, *extras)
      end

      # Adjusts the extents of this bounding box to encompass the given
      # object, which may be a geometry or another bounding box.
      # Returns self.

      def add(geometry)
        case geometry
        when BoundingBox
          add(geometry.min_point)
          add(geometry.max_point)
        when Feature::Geometry
          if geometry.factory == @factory
            add_geometry(geometry)
          else
            add_geometry(Feature.cast(geometry, @factory))
          end
        end
        self
      end

      # Converts this bounding box to an envelope, which will be the
      # empty collection (if the bounding box is empty), a point (if the
      # bounding box is not empty but both spans are 0), a line (if only
      # one of the two spans is 0) or a polygon (if neither span is 0).

      def to_geometry
        if @min_x
          extras = []
          extras << @min_z if @has_z
          extras << @min_m if @has_m
          point_min = @factory.point(@min_x, @min_y, *extras)
          if infinitesimal?
            point_min
          else
            extras = []
            extras << @max_z if @has_z
            extras << @max_m if @has_m
            point_max = @factory.point(@max_x, @max_y, *extras)
            if degenerate?
              @factory.line(point_min, point_max)
            else
              @factory.polygon(@factory.linear_ring([point_min,
                                                     @factory.point(@max_x, @min_y, *extras), point_max,
                                                     @factory.point(@min_x, @max_y, *extras), point_min]))
            end
          end
        else
          @factory.collection([])
        end
      end

      # Returns true if this bounding box contains the given object,
      # which may be a geometry or another bounding box.
      #
      # Supports these options:
      #
      # [<tt>:ignore_z</tt>]
      #   Ignore the Z coordinate when testing, even if both objects
      #   have Z. Default is false.
      # [<tt>:ignore_m</tt>]
      #   Ignore the M coordinate when testing, even if both objects
      #   have M. Default is false.

      def contains?(rhs, opts = {})
        return contains?(BoundingBox.new(@factory).add(rhs)) if Feature::Geometry === rhs

        return true if rhs.empty?

        return false if empty?

        cmp_xymz =
          (@min_x > rhs.min_x || @max_x < rhs.max_x || @min_y > rhs.min_y || @max_y < rhs.max_y) ||
          (@has_m && rhs.has_m && !opts[:ignore_m] && (@min_m > rhs.min_m || @max_m < rhs.max_m)) ||
          (@has_z && rhs.has_z && !opts[:ignore_z] && (@min_z > rhs.min_z || @max_z < rhs.max_z))

        !cmp_xymz
      end

      # Returns this bounding box subdivided, as an array of bounding boxes.
      # If this bounding box is empty, returns the empty array.
      # If this bounding box is a point, returns a one-element array
      # containing the current point.
      # If the x or y span is 0, bisects the line.
      # Otherwise, generally returns a 4-1 subdivision in the X-Y plane.
      # Does not subdivide on Z or M.
      #
      # [<tt>:bisect_factor</tt>]
      #   An optional floating point value that should be greater than 1.0.
      #   If the ratio between the larger span and the smaller span is
      #   greater than this factor, the bounding box is divided only in
      #   half instead of fourths.

      def subdivide(opts = {})
        return [] if empty?
        if infinitesimal?
          return [
            BoundingBox.new(@factory, raw: [@has_z, @has_m,
                                            @min_x, @max_x, @min_y, @max_y, @min_z, @max_z, @min_m, @max_m])
          ]
        end
        factor = opts[:bisect_factor]
        factor ||= 1 if degenerate?
        if factor
          if x_span > y_span * factor
            return [
              BoundingBox.new(@factory, raw: [@has_z, @has_m,
                                              @min_x, center_x, @min_y, @max_y, @min_z, @max_z, @min_m, @max_m]),
              BoundingBox.new(@factory, raw: [@has_z, @has_m,
                                              center_x, @max_x, @min_y, @max_y, @min_z, @max_z, @min_m, @max_m])
            ]
          elsif y_span > x_span * factor
            return [
              BoundingBox.new(@factory, raw: [@has_z, @has_m,
                                              @min_x, @max_x, @min_y, center_y, @min_z, @max_z, @min_m, @max_m]),
              BoundingBox.new(@factory, raw: [@has_z, @has_m,
                                              @min_x, @max_x, center_y, @max_y, @min_z, @max_z, @min_m, @max_m])
            ]
          end
        end
        [
          BoundingBox.new(@factory, raw: [@has_z, @has_m,
                                          @min_x, center_x, @min_y, center_y, @min_z, @max_z, @min_m, @max_m]),
          BoundingBox.new(@factory, raw: [@has_z, @has_m,
                                          center_x, @max_x, @min_y, center_y, @min_z, @max_z, @min_m, @max_m]),
          BoundingBox.new(@factory, raw: [@has_z, @has_m,
                                          @min_x, center_x, center_y, @max_y, @min_z, @max_z, @min_m, @max_m]),
          BoundingBox.new(@factory, raw: [@has_z, @has_m,
                                          center_x, @max_x, center_y, @max_y, @min_z, @max_z, @min_m, @max_m])
        ]
      end

      def add_geometry(geometry)
        case geometry
        when Feature::Point
          add_point(geometry)
        when Feature::LineString
          geometry.points.each { |p| add_point(p) }
        when Feature::Polygon
          geometry.exterior_ring.points.each { |p| add_point(p) }
        when Feature::MultiPoint
          geometry.each { |p| add_point(p) }
        when Feature::MultiLineString
          geometry.each { |line| line.points.each { |p| add_point(p) } }
        when Feature::MultiPolygon
          geometry.each { |poly| poly.exterior_ring.points.each { |p| add_point(p) } }
        when Feature::GeometryCollection
          geometry.each { |g| add_geometry(g) }
        end
        self
      end

      private

      def add_point(point)
        if @min_x
          x = point.x
          @min_x = x if x < @min_x
          @max_x = x if x > @max_x
          y_ = point.y
          @min_y = y_ if y_ < @min_y
          @max_y = y_ if y_ > @max_y
          if @has_z
            z_ = point.z
            @min_z = z_ if z_ < @min_z
            @max_z = z_ if z_ > @max_z
          end
          if @has_m
            m_ = point.m
            @min_m = m_ if m_ < @min_m
            @max_m = m_ if m_ > @max_m
          end
        else
          @min_x = @max_x = point.x
          @min_y = @max_y = point.y
          @min_z = @max_z = point.z if @has_z
          @min_m = @max_m = point.m if @has_m
        end
      end
    end
  end
end
