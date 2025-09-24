# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Projtected geographic feature classes
#
# -----------------------------------------------------------------------------

module RGeo
  module Geographic
    class ProjectedPointImpl
      include Feature::Point
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicPointMethods
      include ProjectedGeometryMethods
      include ProjectedPointMethods
    end

    class ProjectedLineStringImpl
      include Feature::LineString
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicLineStringMethods
      include ProjectedGeometryMethods
      include ProjectedNCurveMethods
      include ProjectedLineStringMethods
    end

    class ProjectedLinearRingImpl
      include Feature::LinearRing
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicLineStringMethods
      include ImplHelper::BasicLinearRingMethods
      include ProjectedGeometryMethods
      include ProjectedNCurveMethods
      include ProjectedLineStringMethods
      include ProjectedLinearRingMethods
    end

    class ProjectedLineImpl
      include Feature::Line
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicLineStringMethods
      include ImplHelper::BasicLineMethods
      include ProjectedGeometryMethods
      include ProjectedNCurveMethods
      include ProjectedLineStringMethods
    end

    class ProjectedPolygonImpl
      include Feature::Polygon
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicPolygonMethods
      include ProjectedGeometryMethods
      include ProjectedNSurfaceMethods
      include ProjectedPolygonMethods
    end

    class ProjectedGeometryCollectionImpl
      include Feature::GeometryCollection
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicGeometryCollectionMethods
      include ProjectedGeometryMethods
    end

    class ProjectedMultiPointImpl
      include Feature::MultiPoint
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicGeometryCollectionMethods
      include ImplHelper::BasicMultiPointMethods
      include ProjectedGeometryMethods
    end

    class ProjectedMultiLineStringImpl
      include Feature::MultiLineString
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicGeometryCollectionMethods
      include ImplHelper::BasicMultiLineStringMethods
      include ProjectedGeometryMethods
      include ProjectedNCurveMethods
    end

    class ProjectedMultiPolygonImpl
      include Feature::MultiPolygon
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicGeometryCollectionMethods
      include ImplHelper::BasicMultiPolygonMethods
      include ProjectedGeometryMethods
      include ProjectedNSurfaceMethods
      include ProjectedMultiPolygonMethods
    end

    ImplHelper::ValidityCheck.override_classes
  end
end
