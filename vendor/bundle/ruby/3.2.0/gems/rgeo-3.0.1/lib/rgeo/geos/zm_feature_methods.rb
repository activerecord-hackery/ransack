# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# GEOS implementation additions written in Ruby
#
# -----------------------------------------------------------------------------

module RGeo
  module Geos
    module ZMGeometryMethods # :nodoc:
      include Feature::Instance

      def initialize(factory, zgeometry, mgeometry)
        @factory = factory
        @zgeometry = zgeometry
        @mgeometry = mgeometry
      end

      def inspect # :nodoc:
        "#<#{self.class}:0x#{object_id.to_s(16)} #{as_text.inspect}>"
      end

      def to_s # :nodoc:
        as_text
      end

      def hash
        [@factory, @zgeometry, @mgeometry].hash
      end

      def factory
        @factory
      end

      def z_geometry
        @zgeometry
      end

      def m_geometry
        @mgeometry
      end

      def dimension
        @zgeometry.dimension
      end

      def coordinate_dimension
        4
      end

      def spatial_dimension
        3
      end

      def geometry_type
        @zgeometry.geometry_type
      end

      def srid
        @factory.srid
      end

      def envelope
        @factory.create_feature(nil, @zgeometry.envelope, @mgeometry.envelope)
      end

      def as_text
        @factory.instance_variable_get(:@wkt_generator).generate(self)
      end

      def as_binary
        @factory.instance_variable_get(:@wkb_generator).generate(self)
      end

      def empty?
        @zgeometry.empty?
      end

      def simple?
        @zgeometry.simple?
      end

      def is_3d?
        true
      end

      def measured?
        true
      end

      def boundary
        @factory.create_feature(nil, @zgeometry.boundary, @mgeometry.boundary)
      end

      def equals?(rhs)
        @zgeometry.equals?(RGeo::Feature.cast(rhs, self).z_geometry)
      end

      def disjoint?(rhs)
        @zgeometry.disjoint?(RGeo::Feature.cast(rhs, self).z_geometry)
      end

      def intersects?(rhs)
        @zgeometry.intersects?(RGeo::Feature.cast(rhs, self).z_geometry)
      end

      def touches?(rhs)
        @zgeometry.touches?(RGeo::Feature.cast(rhs, self).z_geometry)
      end

      def crosses?(rhs)
        @zgeometry.crosses?(RGeo::Feature.cast(rhs, self).z_geometry)
      end

      def within?(rhs)
        @zgeometry.within?(RGeo::Feature.cast(rhs, self).z_geometry)
      end

      def contains?(rhs)
        @zgeometry.contains?(RGeo::Feature.cast(rhs, self).z_geometry)
      end

      def overlaps?(rhs)
        @zgeometry.overlaps?(RGeo::Feature.cast(rhs, self).z_geometry)
      end

      def relate?(rhs, pattern)
        @zgeometry.relate?(RGeo::Feature.cast(rhs, self).z_geometry, pattern)
      end

      def distance(rhs)
        @zgeometry.distance(RGeo::Feature.cast(rhs, self).z_geometry)
      end

      def buffer(distance_)
        @factory.create_feature(nil, @zgeometry.buffer(distance_), @mgeometry.buffer(distance_))
      end

      def convex_hull
        @factory.create_feature(nil, @zgeometry.convex_hull, @mgeometry.convex_hull)
      end

      def intersection(rhs)
        rhs = RGeo::Feature.cast(rhs, self)
        @factory.create_feature(nil, @zgeometry.intersection(rhs.z_geometry), @mgeometry.intersection(rhs.m_geometry))
      end

      def union(rhs)
        rhs = RGeo::Feature.cast(rhs, self)
        @factory.create_feature(nil, @zgeometry.union(rhs.z_geometry), @mgeometry.union(rhs.m_geometry))
      end

      def difference(rhs)
        rhs = RGeo::Feature.cast(rhs, self)
        @factory.create_feature(nil, @zgeometry.difference(rhs.z_geometry), @mgeometry.difference(rhs.m_geometry))
      end

      def sym_difference(rhs)
        rhs = RGeo::Feature.cast(rhs, self)
        @factory.create_feature(
          nil,
          @zgeometry.sym_difference(rhs.z_geometry),
          @mgeometry.sym_difference(rhs.m_geometry)
        )
      end

      def rep_equals?(rhs)
        rhs = RGeo::Feature.cast(rhs, self)
        rhs.is_a?(self.class) &&
          @factory.eql?(rhs.factory) &&
          @zgeometry.rep_equals?(rhs.z_geometry) &&
          @mgeometry.rep_equals?(rhs.m_geometry)
      end

      alias eql? rep_equals?
      alias == equals?

      alias - difference
      alias + union
      alias * intersection

      def marshal_dump # :nodoc:
        [@factory, @factory.marshal_wkb_generator.generate(self)]
      end

      def marshal_load(data)  # :nodoc:
        copy_state_from(data[0].marshal_wkb_parser.parse(data[1]))
      end

      def encode_with(coder)  # :nodoc:
        coder["factory"] = @factory
        coder["wkt"] = @factory.psych_wkt_generator.generate(self)
      end

      def init_with(coder) # :nodoc:
        copy_state_from(coder["factory"].psych_wkt_parser.parse(coder["wkt"]))
      end

      private

      def copy_state_from(obj)
        @factory = obj.factory
        @zgeometry = obj.z_geometry
        @mgeometry = obj.m_geometry
      end
    end

    module ZMPointMethods # :nodoc:
      def x
        @zgeometry.x
      end

      def y
        @zgeometry.y
      end

      def z
        @zgeometry.z
      end

      def m
        @mgeometry.m
      end

      def coordinates
        [x, y].tap do |coords|
          coords << z if @factory.property(:has_z_coordinate)
          coords << m if @factory.property(:has_m_coordinate)
        end
      end
    end

    module ZMLineStringMethods # :nodoc:
      def length
        @zgeometry.length
      end

      def start_point
        point_n(0)
      end

      def end_point
        point_n(num_points - 1)
      end

      def closed?
        @zgeometry.closed?
      end

      def ring?
        @zgeometry.ring?
      end

      def num_points
        @zgeometry.num_points
      end

      def point_n(idx)
        @factory.create_feature(ZMPointImpl, @zgeometry.point_n(idx), @mgeometry.point_n(idx))
      end

      def points
        result_ = []
        zpoints_ = @zgeometry.points
        mpoints_ = @mgeometry.points
        zpoints_.size.times do |i_|
          result_ << @factory.create_feature(ZMPointImpl, zpoints_[i_], mpoints_[i_])
        end
        result_
      end

      def coordinates
        points.map(&:coordinates)
      end
    end

    module ZMPolygonMethods # :nodoc:
      def area
        @zgeometry.area
      end

      def centroid
        @factory.create_feature(ZMPointImpl, @zgeometry.centroid, @mgeometry.centroid)
      end

      def point_on_surface
        @factory.create_feature(ZMPointImpl, @zgeometry.centroid, @mgeometry.centroid)
      end

      def exterior_ring
        @factory.create_feature(ZMLineStringImpl, @zgeometry.exterior_ring, @mgeometry.exterior_ring)
      end

      def num_interior_rings
        @zgeometry.num_interior_rings
      end

      def interior_ring_n(idx)
        @factory.create_feature(ZMLineStringImpl, @zgeometry.interior_ring_n(idx), @mgeometry.interior_ring_n(idx))
      end

      def interior_rings
        result_ = []
        zrings_ = @zgeometry.interior_rings
        mrings_ = @mgeometry.interior_rings
        zrings_.size.times do |i_|
          result_ << @factory.create_feature(ZMLineStringImpl, zrings_[i_], mrings_[i_])
        end
        result_
      end

      def coordinates
        ([exterior_ring] + interior_rings).map(&:coordinates)
      end
    end

    module ZMGeometryCollectionMethods # :nodoc:
      def num_geometries
        @zgeometry.num_geometries
      end
      alias size num_geometries

      def geometry_n(idx)
        @factory.create_feature(nil, @zgeometry.geometry_n(idx), @mgeometry.geometry_n(idx))
      end
      alias [] geometry_n

      def each
        if block_given?
          num_geometries.times do |i|
            yield geometry_n(i)
          end
          self
        else
          enum_for
        end
      end

      include Enumerable
    end

    module ZMMultiLineStringMethods # :nodoc:
      def length
        @zgeometry.length
      end

      def closed?
        @zgeometry.closed?
      end

      def coordinates
        each.map(&:coordinates)
      end
    end

    module ZMMultiPolygonMethods # :nodoc:
      def area
        @zgeometry.area
      end

      def centroid
        @factory.create_feature(ZMPointImpl, @zgeometry.centroid, @mgeometry.centroid)
      end

      def point_on_surface
        @factory.create_feature(ZMPointImpl, @zgeometry.centroid, @mgeometry.centroid)
      end

      def coordinates
        each.map(&:coordinates)
      end
    end
  end
end
