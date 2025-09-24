# frozen_string_literal: true

module RGeo
  module ActiveRecord
    # Returns true if spatial expressions (i.e. the methods in the
    # SpatialExpressions module) are supported.
    def self.spatial_expressions_supported?
      defined?(Arel::Nodes::NamedFunction)
    end

    # A set of spatial expression builders.
    # These methods can be chained off other spatial expressions to form
    # complex expressions.
    module SpatialExpressions
      #--
      # Generic functions
      #++

      def st_function(function, *args)
        spatial_info = args.last.is_a?(::Array) ? args.pop : []
        SpatialNamedFunction.new(function, [self] + args, spatial_info)
      end

      #--
      # Geometry functions
      #++

      def st_dimension
        SpatialNamedFunction.new("ST_Dimension", [self], [false, true])
      end

      def st_geometrytype
        SpatialNamedFunction.new("ST_GeometryType", [self], [false, true])
      end

      def st_astext
        SpatialNamedFunction.new("ST_AsText", [self], [false, true])
      end

      def st_asbinary
        SpatialNamedFunction.new("ST_AsBinary", [self], [false, true])
      end

      def st_srid
        SpatialNamedFunction.new("ST_SRID", [self], [false, true])
      end

      def st_isempty
        SpatialNamedFunction.new("ST_IsEmpty", [self], [false, true])
      end

      def st_issimple
        SpatialNamedFunction.new("ST_IsSimple", [self], [false, true])
      end

      def st_boundary
        SpatialNamedFunction.new("ST_Boundary", [self], [true, true])
      end

      def st_envelope
        SpatialNamedFunction.new("ST_Envelope", [self], [true, true])
      end

      def st_equals(rhs)
        SpatialNamedFunction.new("ST_Equals", [self, rhs], [false, true, true])
      end

      def st_disjoint(rhs)
        SpatialNamedFunction.new("ST_Disjoint", [self, rhs], [false, true, true])
      end

      def st_intersects(rhs)
        SpatialNamedFunction.new("ST_Intersects", [self, rhs], [false, true, true])
      end

      def st_touches(rhs)
        SpatialNamedFunction.new("ST_Touches", [self, rhs], [false, true, true])
      end

      def st_crosses(rhs)
        SpatialNamedFunction.new("ST_Crosses", [self, rhs], [false, true, true])
      end

      def st_within(rhs)
        SpatialNamedFunction.new("ST_Within", [self, rhs], [false, true, true])
      end

      def st_contains(rhs)
        SpatialNamedFunction.new("ST_Contains", [self, rhs], [false, true, true])
      end

      def st_overlaps(rhs)
        SpatialNamedFunction.new("ST_Overlaps", [self, rhs], [false, true, true])
      end

      def st_relate(rhs, matrix = nil)
        args = [self, rhs]
        args << matrix.to_s if matrix
        SpatialNamedFunction.new("ST_Relate", args, [false, true, true, false])
      end

      def st_distance(rhs, units = nil)
        args = [self, rhs]
        args << units.to_s if units
        SpatialNamedFunction.new("ST_Distance", args, [false, true, true, false])
      end

      def st_intersection(rhs)
        SpatialNamedFunction.new("ST_Intersection", [self, rhs], [true, true, true])
      end

      def st_difference(rhs)
        SpatialNamedFunction.new("ST_Difference", [self, rhs], [true, true, true])
      end

      def st_union(rhs)
        SpatialNamedFunction.new("ST_Union", [self, rhs], [true, true, true])
      end

      def st_symdifference(rhs)
        SpatialNamedFunction.new("ST_SymDifference", [self, rhs], [true, true, true])
      end

      def st_buffer(distance, units = nil)
        args = [self, distance.to_f]
        args << units.to_s if units
        SpatialNamedFunction.new("ST_Buffer", args, [true, true, false])
      end

      def st_convexhull
        SpatialNamedFunction.new("ST_ConvexHull", [self], [true, true])
      end

      #--
      # Point functions
      #++

      def st_x
        SpatialNamedFunction.new("ST_X", [self], [false, true])
      end

      def st_y
        SpatialNamedFunction.new("ST_Y", [self], [false, true])
      end

      def st_z
        SpatialNamedFunction.new("ST_Z", [self], [false, true])
      end

      def st_m
        SpatialNamedFunction.new("ST_M", [self], [false, true])
      end

      #--
      # Curve functions
      #++

      def st_startpoint
        SpatialNamedFunction.new("ST_StartPoint", [self], [true, true])
      end

      def st_endpoint
        SpatialNamedFunction.new("ST_EndPoint", [self], [true, true])
      end

      def st_isclosed
        SpatialNamedFunction.new("ST_IsClosed", [self], [false, true])
      end

      def st_isring
        SpatialNamedFunction.new("ST_IsRing", [self], [false, true])
      end

      def st_length(units = nil)
        args = [self]
        args << units.to_s if units
        SpatialNamedFunction.new("ST_Length", args, [false, true, false])
      end

      #--
      # LineString functions
      #++

      def st_numpoints
        SpatialNamedFunction.new("ST_NumPoints", [self], [false, true])
      end

      def st_pointn(n)
        SpatialNamedFunction.new("ST_PointN", [self, n.to_i], [true, true, false])
      end

      #--
      # Surface functions
      #++

      def st_area(units = nil)
        args = [self]
        args << units.to_s if units
        SpatialNamedFunction.new("ST_Area", args, [false, true, false])
      end

      def st_centroid
        SpatialNamedFunction.new("ST_Centroid", [self], [true, true])
      end

      def st_pointonsurface
        SpatialNamedFunction.new("ST_PointOnSurface", [self], [true, true])
      end

      #--
      # Polygon functions
      #++

      def st_exteriorring
        SpatialNamedFunction.new("ST_ExteriorRing", [self], [true, true])
      end

      def st_numinteriorrings
        # Note: the name difference is intentional. The standard
        # names this function incorrectly.
        SpatialNamedFunction.new("ST_NumInteriorRing", [self], [false, true])
      end

      def st_interiorringn(n)
        SpatialNamedFunction.new("ST_InteriorRingN", [self, n.to_i], [true, true, false])
      end

      #--
      # GeometryCollection functions
      #++

      def st_numgeometries
        SpatialNamedFunction.new("ST_NumGeometries", [self], [false, true])
      end

      def st_geometryn(n)
        SpatialNamedFunction.new("ST_GeometryN", [self, n.to_i], [true, true, false])
      end
    end
  end
end

# Add tools to build spatial structures in the AST.

# Allow chaining of spatial expressions from attributes
Arel::Attribute.send :include, RGeo::ActiveRecord::SpatialExpressions

module Arel
  # Create a spatial constant node.
  # This node wraps a spatial value (such as an RGeo feature or a text
  # string in WKT format). It supports chaining with the functions
  # defined by RGeo::ActiveRecord::SpatialExpressions.
  def self.spatial(arg)
    RGeo::ActiveRecord::SpatialConstantNode.new(arg)
  end
end
