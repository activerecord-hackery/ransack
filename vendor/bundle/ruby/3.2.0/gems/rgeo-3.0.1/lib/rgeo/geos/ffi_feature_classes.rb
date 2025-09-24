# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# FFI-GEOS geometry implementation
#
# -----------------------------------------------------------------------------

require_relative "../impl_helper/validity_check"

module RGeo
  module Geos
    class FFIGeometryImpl
      include Feature::Geometry
      include ImplHelper::ValidityCheck
      include FFIGeometryMethods
    end

    class FFIPointImpl
      include Feature::Point
      include ImplHelper::ValidityCheck
      include FFIGeometryMethods
      include FFIPointMethods
    end

    class FFILineStringImpl
      include Feature::LineString
      include ImplHelper::ValidityCheck
      include FFIGeometryMethods
      include FFILineStringMethods
    end

    class FFILinearRingImpl
      include Feature::LinearRing
      include ImplHelper::ValidityCheck
      include FFIGeometryMethods
      include FFILineStringMethods
      include FFILinearRingMethods
    end

    class FFILineImpl
      include Feature::Line
      include ImplHelper::ValidityCheck
      include FFIGeometryMethods
      include FFILineStringMethods
      include FFILineMethods
    end

    class FFIPolygonImpl
      include Feature::Polygon
      include ImplHelper::ValidityCheck
      include FFIGeometryMethods
      include FFIPolygonMethods
    end

    class FFIGeometryCollectionImpl
      include Feature::GeometryCollection
      include ImplHelper::ValidityCheck
      include FFIGeometryMethods
      include FFIGeometryCollectionMethods
    end

    class FFIMultiPointImpl
      include Feature::MultiPoint
      include ImplHelper::ValidityCheck
      include FFIGeometryMethods
      include FFIGeometryCollectionMethods
      include FFIMultiPointMethods
    end

    class FFIMultiLineStringImpl
      include Feature::MultiLineString
      include ImplHelper::ValidityCheck
      include FFIGeometryMethods
      include FFIGeometryCollectionMethods
      include FFIMultiLineStringMethods
    end

    class FFIMultiPolygonImpl
      include Feature::MultiPolygon
      include ImplHelper::ValidityCheck
      include FFIGeometryMethods
      include FFIGeometryCollectionMethods
      include FFIMultiPolygonMethods
    end

    ImplHelper::ValidityCheck.override_classes
  end
end
