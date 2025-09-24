# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Spherical geographic feature classes
#
# -----------------------------------------------------------------------------

module RGeo
  module Geographic
    class SphericalPointImpl
      include Feature::Point
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicPointMethods
      include ImplHelper::ValidOp
      include SphericalGeometryMethods
      include SphericalPointMethods
    end

    class SphericalLineStringImpl
      include Feature::LineString
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicLineStringMethods
      include ImplHelper::ValidOp
      include SphericalGeometryMethods
      include SphericalLineStringMethods
    end

    class SphericalLineImpl
      include Feature::Line
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicLineStringMethods
      include ImplHelper::BasicLineMethods
      include ImplHelper::ValidOp
      include SphericalGeometryMethods
      include SphericalLineStringMethods
    end

    class SphericalLinearRingImpl
      include Feature::LinearRing
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicLineStringMethods
      include ImplHelper::BasicLinearRingMethods
      include ImplHelper::ValidOp
      include SphericalGeometryMethods
      include SphericalLineStringMethods
    end

    class SphericalPolygonImpl
      include Feature::Polygon
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicPolygonMethods
      include ImplHelper::ValidOp
      include SphericalGeometryMethods
      include SphericalPolygonMethods
    end

    class SphericalGeometryCollectionImpl
      include Feature::GeometryCollection
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicGeometryCollectionMethods
      include ImplHelper::ValidOp
      include SphericalGeometryMethods
    end

    class SphericalMultiPointImpl
      include Feature::MultiPoint
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicGeometryCollectionMethods
      include ImplHelper::BasicMultiPointMethods
      include ImplHelper::ValidOp
      include SphericalGeometryMethods
    end

    class SphericalMultiLineStringImpl
      include Feature::MultiLineString
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicGeometryCollectionMethods
      include ImplHelper::BasicMultiLineStringMethods
      include ImplHelper::ValidOp
      include SphericalGeometryMethods
      include SphericalMultiLineStringMethods
    end

    class SphericalMultiPolygonImpl
      include Feature::MultiPolygon
      include ImplHelper::ValidityCheck
      include ImplHelper::BasicGeometryMethods
      include ImplHelper::BasicGeometryCollectionMethods
      include ImplHelper::BasicMultiPolygonMethods
      include ImplHelper::ValidOp
      include SphericalGeometryMethods
    end

    ImplHelper::ValidityCheck.override_classes
  end
end
