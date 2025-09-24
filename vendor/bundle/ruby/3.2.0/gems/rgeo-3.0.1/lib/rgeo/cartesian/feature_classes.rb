# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Cartesian feature classes
#
# -----------------------------------------------------------------------------

require_relative "../impl_helper/validity_check"

module RGeo
  module Cartesian
    class PointImpl # :nodoc:
      include Feature::Point
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicPointMethods
      include ImplHelper::ValidOp
      include GeometryMethods
      include PointMethods
    end

    class LineStringImpl # :nodoc:
      include Feature::LineString
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicLineStringMethods
      include ImplHelper::ValidOp
      include GeometryMethods
      include LineStringMethods
    end

    class LineImpl # :nodoc:
      include Feature::Line
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicLineStringMethods
      include ImplHelper::BasicLineMethods
      include ImplHelper::ValidOp
      include GeometryMethods
      include LineStringMethods
    end

    class LinearRingImpl # :nodoc:
      include Feature::LinearRing
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicLineStringMethods
      include ImplHelper::BasicLinearRingMethods
      include ImplHelper::ValidOp
      include GeometryMethods
      include LineStringMethods
    end

    class PolygonImpl # :nodoc:
      include Feature::Polygon
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicPolygonMethods
      include ValidOp
      include GeometryMethods
    end

    class GeometryCollectionImpl # :nodoc:
      include Feature::GeometryCollection
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicGeometryCollectionMethods
      include ImplHelper::ValidOp
      include GeometryMethods
    end

    class MultiPointImpl # :nodoc:
      include Feature::MultiPoint
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicGeometryCollectionMethods
      include ImplHelper::BasicMultiPointMethods
      include ImplHelper::ValidOp
      include GeometryMethods
    end

    class MultiLineStringImpl # :nodoc:
      include Feature::MultiLineString
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicGeometryCollectionMethods
      include ImplHelper::BasicMultiLineStringMethods
      include ImplHelper::ValidOp
      include GeometryMethods
      include MultiLineStringMethods
    end

    class MultiPolygonImpl # :nodoc:
      include Feature::MultiPolygon
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicGeometryCollectionMethods
      include ImplHelper::BasicMultiPolygonMethods
      include ImplHelper::ValidOp
      include GeometryMethods
    end

    ImplHelper::ValidityCheck.override_classes
  end
end
