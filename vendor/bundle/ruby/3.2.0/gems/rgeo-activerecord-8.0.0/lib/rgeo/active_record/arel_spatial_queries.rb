# frozen_string_literal: true

module RGeo
  module ActiveRecord
    # A set of common Arel visitor hacks for spatial ToSql visitors.
    # Generally, a spatial ActiveRecord adapter should provide a custom
    # ToSql Arel visitor that includes and customizes this module.
    # See the existing spatial adapters (i.e. postgis, spatialite,
    # mysqlspatial, and mysql2spatial) for usage examples.

    module SpatialToSql
      # Map a standard OGC SQL function name to the actual name used by
      # a particular database. This method should take a name and
      # return either the changed name or the original name.

      def st_func(standard_name)
        standard_name
      end

      # Visit the SpatialNamedFunction node. This operates similarly to
      # the standard NamedFunction node, but it performs function name
      # mapping for the database, and it also uses the type information
      # in the node to determine when to cast string arguments to WKT,

      def visit_RGeo_ActiveRecord_SpatialNamedFunction(node, collector)
        name = st_func(node.name)
        collector << name
        collector << "("
        collector << "DISTINCT " if node.distinct
        node.expressions.each_with_index do |expr, index|
          node.spatial_argument?(index) ? visit_in_spatial_context(expr, collector) : visit(expr, collector)
          collector << ", " unless index == node.expressions.size - 1
        end
        collector << ")"
        if node.alias
          collector << " AS "
          visit node.alias, collector
        end
        collector
      end

      # Generates SQL for a spatial node.
      # The node must be a string (in which case it is treated as WKT),
      # an RGeo feature, or a spatial attribute.
      def visit_in_spatial_context(node, collector)
        if node.is_a?(String)
          collector << "#{st_func('ST_GeomFromText')}(#{quote(node)})"
        elsif node.is_a?(RGeo::Feature::Instance)
          srid = node.srid
          collector << "#{st_func('ST_GeomFromText')}(#{quote(node.to_s)}, #{srid})"
        elsif node.is_a?(RGeo::Cartesian::BoundingBox)
          geom = node.to_geometry
          srid = geom.srid
          collector << "#{st_func('ST_GeomFromText')}(#{quote(geom.to_s)}, #{srid})"
        else
          visit(node, collector)
        end
      end
    end

    # This node wraps an RGeo feature and gives it spatial expression constructors.
    class SpatialConstantNode
      include SpatialExpressions

      # The delegate should be the RGeo feature.
      def initialize(delegate)
        @delegate = delegate
      end

      # Return the RGeo feature
      attr_reader :delegate
    end

    # :stopdoc:

    # Make sure the standard Arel visitors can handle RGeo feature objects by default.

    Arel::Visitors::Visitor.class_eval do
      def visit_RGeo_ActiveRecord_SpatialConstantNode(node, collector)
        if respond_to?(:visit_in_spatial_context)
          visit_in_spatial_context(node.delegate, collector)
        else
          visit(node.delegate, collector)
        end
      end
    end

    Arel::Visitors::Dot.class_eval do
      alias :visit_RGeo_Feature_Instance :visit_String
      alias :visit_RGeo_Cartesian_BoundingBox :visit_String
    end

    # A NamedFunction subclass that keeps track of the spatial-ness of
    # the arguments and return values, so that it can provide context to
    # visitors that want to interpret syntax differently when dealing with
    # spatial elements.
    class SpatialNamedFunction < Arel::Nodes::NamedFunction
      include SpatialExpressions

      def initialize(name, expr, spatial_flags = [], aliaz = nil)
        super(name, expr, aliaz)
        @spatial_flags = spatial_flags
      end

      def spatial_result?
        @spatial_flags.first
      end

      def spatial_argument?(index)
        @spatial_flags[index + 1]
      end
    end

    # :startdoc:
  end
end
