# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# FFI-GEOS geometry implementation
#
# -----------------------------------------------------------------------------

require "ffi-geos"

module RGeo
  module Geos
    module FFIGeometryMethods # :nodoc:
      include Feature::Instance

      attr_reader :factory, :fg_geom, :_klasses

      def initialize(factory, fg_geom, klasses)
        @factory = factory
        @fg_geom = fg_geom
        @_fg_prep = factory._auto_prepare ? 1 : 0
        @_klasses = klasses
        fg_geom.srid = factory.srid
      end

      def inspect
        "#<#{self.class}:0x#{object_id.to_s(16)} #{as_text.inspect}>"
      end

      # Marshal support

      def marshal_dump # :nodoc:
        [@factory, @factory.write_for_marshal(self)]
      end

      def marshal_load(data) # :nodoc:
        @factory = data[0]
        @fg_geom = @factory.read_for_marshal(data[1])
        @fg_geom.srid = @factory.srid
        @_fg_prep = @factory._auto_prepare ? 1 : 0
        @_klasses = nil
      end

      # Psych support

      def encode_with(coder) # :nodoc:
        coder["factory"] = @factory
        str = @factory.write_for_psych(self)
        str = str.encode("US-ASCII") if str.respond_to?(:encode)
        coder["wkt"] = str
      end

      def init_with(coder) # :nodoc:
        @factory = coder["factory"]
        @fg_geom = @factory.read_for_psych(coder["wkt"])
        @fg_geom.srid = @factory.srid
        @_fg_prep = @factory._auto_prepare ? 1 : 0
        @_klasses = nil
      end

      def initialize_copy(orig)
        @factory = orig.factory
        @fg_geom = orig.fg_geom.clone
        @fg_geom.srid = orig.fg_geom.srid
        @_fg_prep = @factory._auto_prepare ? 1 : 0
        @_klasses = orig._klasses
      end

      def srid
        @fg_geom.srid
      end

      def dimension
        Utils.ffi_compute_dimension(@fg_geom)
      end

      def coordinate_dimension
        factory.coordinate_dimension
      end

      def spatial_dimension
        factory.spatial_dimension
      end

      def geometry_type
        Feature::Geometry
      end

      def prepared?
        !@_fg_prep.is_a?(Integer)
      end

      def prepare!
        @_fg_prep = ::Geos::PreparedGeometry.new(@fg_geom) if @_fg_prep.is_a?(Integer)
        self
      end

      def envelope
        @factory.wrap_fg_geom(@fg_geom.envelope, nil)
      end

      def boundary
        @factory.wrap_fg_geom(@fg_geom.boundary, nil)
      rescue ::Geos::GEOSException
        raise Error::InvalidGeometry, "Operation not supported by GeometryCollection"
      end

      def as_text
        str = @factory.generate_wkt(self)
        str.force_encoding("US-ASCII") if str.respond_to?(:force_encoding)
        str
      end
      alias to_s as_text

      def as_binary
        @factory.generate_wkb(self)
      end

      def empty?
        @fg_geom.empty?
      end

      def simple?
        @fg_geom.simple?
      end

      def is_3d?
        factory.property(:has_z_coordinate)
      end

      def measured?
        factory.property(:has_m_coordinate)
      end

      def valid?
        @fg_geom.valid?
      end

      def invalid_reason
        # valid_detail gives solely the reason, or nil if valid, which is
        # what we want.
        fg_geom.valid_detail&.dig(:detail)&.force_encoding(Encoding::UTF_8)
      end

      # (see RGeo::ImplHelper::ValidityCheck#make_valid)
      # Only available since GEOS 3.8+
      if ::Geos::FFIGeos.respond_to?(:GEOSMakeValid_r)
        def make_valid
          @factory.wrap_fg_geom(@fg_geom.make_valid, nil)
        rescue ::Geos::GEOSException
          raise Error::UnsupportedOperation
        end
      end

      def equals?(rhs)
        return false unless rhs.is_a?(RGeo::Feature::Instance)
        fg = factory.convert_to_fg_geometry(rhs)

        # GEOS has a bug where empty geometries are not spatially equal
        # to each other. Work around this case first.
        if fg.empty? && @fg_geom.empty?
          true
        else
          @fg_geom.eql?(fg)
        end
      end
      alias == equals?

      def disjoint?(rhs)
        fg = factory.convert_to_fg_geometry(rhs)
        prep = request_prepared if Utils.ffi_supports_prepared_level2
        prep ? prep.disjoint?(fg) : @fg_geom.disjoint?(fg)
      end

      def intersects?(rhs)
        fg = factory.convert_to_fg_geometry(rhs)
        prep = request_prepared if Utils.ffi_supports_prepared_level1
        prep ? prep.intersects?(fg) : @fg_geom.intersects?(fg)
      end

      def touches?(rhs)
        fg = factory.convert_to_fg_geometry(rhs)
        prep = request_prepared if Utils.ffi_supports_prepared_level2
        prep ? prep.touches?(fg) : @fg_geom.touches?(fg)
      end

      def crosses?(rhs)
        fg = factory.convert_to_fg_geometry(rhs)
        prep = request_prepared if Utils.ffi_supports_prepared_level2
        prep ? prep.crosses?(fg) : @fg_geom.crosses?(fg)
      end

      def within?(rhs)
        fg = factory.convert_to_fg_geometry(rhs)
        prep = request_prepared if Utils.ffi_supports_prepared_level2
        prep ? prep.within?(fg) : @fg_geom.within?(fg)
      end

      def contains?(rhs)
        fg = factory.convert_to_fg_geometry(rhs)
        prep = request_prepared if Utils.ffi_supports_prepared_level1
        prep ? prep.contains?(fg) : @fg_geom.contains?(fg)
      end

      def overlaps?(rhs)
        fg = factory.convert_to_fg_geometry(rhs)
        prep = request_prepared if Utils.ffi_supports_prepared_level2
        prep ? prep.overlaps?(fg) : @fg_geom.overlaps?(fg)
      end

      def relate?(rhs, pattern)
        fg = factory.convert_to_fg_geometry(rhs)
        @fg_geom.relate_pattern(fg, pattern)
      end

      def distance(rhs)
        fg = factory.convert_to_fg_geometry(rhs)
        @fg_geom.distance(fg)
      end

      def buffer(distance)
        @factory.wrap_fg_geom(@fg_geom.buffer(distance, @factory.buffer_resolution), nil)
      end

      def convex_hull
        @factory.wrap_fg_geom(@fg_geom.convex_hull, nil)
      end

      def intersection(rhs)
        fg = factory.convert_to_fg_geometry(rhs)
        @factory.wrap_fg_geom(@fg_geom.intersection(fg), nil)
      end

      alias * intersection

      def union(rhs)
        fg = factory.convert_to_fg_geometry(rhs)
        @factory.wrap_fg_geom(@fg_geom.union(fg), nil)
      end

      alias + union

      def unary_union
        return unless @fg_geom.respond_to?(:unary_union)
        @factory.wrap_fg_geom(@fg_geom.unary_union)
      end

      def difference(rhs)
        fg = factory.convert_to_fg_geometry(rhs)
        @factory.wrap_fg_geom(@fg_geom.difference(fg), nil)
      end

      alias - difference

      def sym_difference(rhs)
        fg = factory.convert_to_fg_geometry(rhs)
        @factory.wrap_fg_geom(@fg_geom.sym_difference(fg), nil)
      end

      def eql?(other)
        rep_equals?(other)
      end

      def detach_fg_geom
        fg = @fg_geom
        @fg_geom = nil
        fg
      end

      def point_on_surface
        @factory.wrap_fg_geom(@fg_geom.point_on_surface, FFIPointImpl)
      end

      private

      def request_prepared
        case @_fg_prep
        when 0
          nil
        when 1
          @_fg_prep = 2
          nil
        when 2
          @_fg_prep = ::Geos::PreparedGeometry.new(@fg_geom)
        else
          @_fg_prep
        end
      end
    end

    module FFIPointMethods # :nodoc:
      def x
        @fg_geom.coord_seq.get_x(0)
      end

      def y
        @fg_geom.coord_seq.get_y(0)
      end

      def z
        @fg_geom.coord_seq.get_z(0) if @factory.property(:has_z_coordinate)
      end

      def m
        @fg_geom.coord_seq.get_z(0) if @factory.property(:has_m_coordinate)
      end

      def geometry_type
        Feature::Point
      end

      def rep_equals?(rhs)
        rhs.instance_of?(self.class) && rhs.factory.eql?(@factory) &&
          Utils.ffi_coord_seqs_equal?(rhs.fg_geom.coord_seq, @fg_geom.coord_seq, @factory._has_3d)
      end

      def hash
        @hash ||= Utils.ffi_coord_seq_hash(@fg_geom.coord_seq, [@factory, geometry_type].hash)
      end

      def coordinates
        [x, y].tap do |coords|
          coords << z if @factory.property(:has_z_coordinate)
          coords << m if @factory.property(:has_m_coordinate)
        end
      end
    end

    module FFILineStringMethods  # :nodoc:
      def geometry_type
        Feature::LineString
      end

      def length
        @fg_geom.length
      end

      def num_points
        @fg_geom.num_points
      end

      def point_n(idx)
        return unless idx >= 0 && idx < @fg_geom.num_points

        coord_seq = @fg_geom.coord_seq
        x = coord_seq.get_x(idx)
        y = coord_seq.get_y(idx)
        extra = @factory._has_3d ? [coord_seq.get_z(idx)] : []

        @factory.point(x, y, *extra)
      end

      def start_point
        point_n(0)
      end

      def end_point
        point_n(@fg_geom.num_points - 1)
      end

      def points
        coord_seq = @fg_geom.coord_seq
        has_3d = @factory._has_3d
        Array.new(@fg_geom.num_points) do |n|
          x = coord_seq.get_x(n)
          y = coord_seq.get_y(n)
          extra = has_3d ? [coord_seq.get_z(n)] : []
          @factory.point(x, y, *extra)
        end
      end

      def closed?
        @fg_geom.closed?
      end

      def ring?
        @fg_geom.ring?
      end

      def rep_equals?(rhs)
        rhs.instance_of?(self.class) && rhs.factory.eql?(@factory) &&
          Utils.ffi_coord_seqs_equal?(rhs.fg_geom.coord_seq, @fg_geom.coord_seq, @factory._has_3d)
      end

      def hash
        @hash ||= Utils.ffi_coord_seq_hash(@fg_geom.coord_seq, [@factory, geometry_type].hash)
      end

      def coordinates
        points.map(&:coordinates)
      end
    end

    module FFILinearRingMethods  # :nodoc:
      def geometry_type
        Feature::LinearRing
      end

      def ccw?
        RGeo::Cartesian::Analysis.ccw?(self)
      end
    end

    module FFILineMethods # :nodoc:
      def geometry_type
        Feature::Line
      end
    end

    module FFIPolygonMethods # :nodoc:
      def geometry_type
        Feature::Polygon
      end

      def area
        @fg_geom.area
      end

      def centroid
        @factory.wrap_fg_geom(@fg_geom.centroid, FFIPointImpl)
      end

      def point_on_surface
        @factory.wrap_fg_geom(@fg_geom.point_on_surface, FFIPointImpl)
      end

      def exterior_ring
        @factory.wrap_fg_geom(@fg_geom.exterior_ring, FFILinearRingImpl)
      end

      def num_interior_rings
        @fg_geom.num_interior_rings
      end

      def interior_ring_n(idx)
        return unless idx >= 0 && idx < @fg_geom.num_interior_rings

        @factory.wrap_fg_geom(@fg_geom.interior_ring_n(idx), FFILinearRingImpl)
      end

      def interior_rings
        Array.new(@fg_geom.num_interior_rings) do |n|
          @factory.wrap_fg_geom(@fg_geom.interior_ring_n(n), FFILinearRingImpl)
        end
      end

      def rep_equals?(rhs)
        if rhs.instance_of?(self.class) && rhs.factory.eql?(@factory) &&
          rhs.exterior_ring.rep_equals?(exterior_ring)
          sn = @fg_geom.num_interior_rings
          rn = rhs.num_interior_rings
          if sn == rn
            sn.times do |i|
              return false unless interior_ring_n(i).rep_equals?(rhs.interior_ring_n(i))
            end
            return true
          end
        end
        false
      end

      def hash
        @hash ||= begin
          hash = Utils.ffi_coord_seq_hash(
            @fg_geom.exterior_ring.coord_seq,
            [@factory, geometry_type].hash
          )
          @fg_geom.interior_rings.inject(hash) do |h, r|
            Utils.ffi_coord_seq_hash(r.coord_seq, h)
          end
        end
      end

      def coordinates
        ([exterior_ring] + interior_rings).map(&:coordinates)
      end
    end

    module FFIGeometryCollectionMethods # :nodoc:
      def geometry_type
        Feature::GeometryCollection
      end

      def rep_equals?(rhs)
        if rhs.instance_of?(self.class) && rhs.factory.eql?(@factory)
          size = @fg_geom.num_geometries
          if size == rhs.num_geometries
            size.times do |n|
              return false unless geometry_n(n).rep_equals?(rhs.geometry_n(n))
            end
            return true
          end
        end
        false
      end

      def num_geometries
        @fg_geom.num_geometries
      end
      alias size num_geometries

      def geometry_n(idx)
        return unless idx >= 0 && idx < @fg_geom.num_geometries

        @factory.wrap_fg_geom(
          @fg_geom.get_geometry_n(idx),
          @_klasses ? @_klasses[idx] : nil
        )
      end

      def [](idx)
        idx += @fg_geom.num_geometries if idx < 0

        return unless idx >= 0 && idx < @fg_geom.num_geometries

        @factory.wrap_fg_geom(
          @fg_geom.get_geometry_n(idx),
          @_klasses ? @_klasses[idx] : nil
        )
      end

      def hash
        @hash ||= [@factory, geometry_type, *(0...num_geometries).map { |i| geometry_n(i) }].hash
      end

      def each
        if block_given?
          @fg_geom.num_geometries.times do |n|
            yield @factory.wrap_fg_geom(@fg_geom.get_geometry_n(n), @_klasses ? @_klasses[n] : nil)
          end
          self
        else
          enum_for
        end
      end

      include Enumerable
    end

    module FFIMultiPointMethods # :nodoc:
      def geometry_type
        Feature::MultiPoint
      end

      def coordinates
        each.map(&:coordinates)
      end
    end

    module FFIMultiLineStringMethods # :nodoc:
      def geometry_type
        Feature::MultiLineString
      end

      def length
        @fg_geom.length
      end

      def closed?
        size = num_geometries
        size.times do |n|
          return false unless @fg_geom.get_geometry_n(n).closed?
        end
        true
      end

      def coordinates
        each.map(&:coordinates)
      end
    end

    module FFIMultiPolygonMethods # :nodoc:
      def geometry_type
        Feature::MultiPolygon
      end

      def area
        @fg_geom.area
      end

      def centroid
        @factory.wrap_fg_geom(@fg_geom.centroid, FFIPointImpl)
      end

      def coordinates
        each.map(&:coordinates)
      end
    end
  end
end
