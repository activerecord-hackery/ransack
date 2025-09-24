# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# GEOS implementation additions written in Ruby
#
# -----------------------------------------------------------------------------

require_relative "../impl_helper/validity_check"

module RGeo
  module Geos
    module CAPIGeometryMethods
      include Feature::Instance

      def coordinate_dimension
        dim = 2
        dim += 1 if factory.supports_z?
        dim += 1 if factory.supports_m?
        dim
      end

      def spatial_dimension
        factory.supports_z? ? 3 : 2
      end

      def is_3d?
        factory.supports_z?
      end

      def measured?
        factory.supports_m?
      end

      def inspect
        "#<#{self.class}:0x#{object_id.to_s(16)} #{as_text.inspect}>"
      end

      # Marshal support

      def marshal_dump # :nodoc:
        my_factory = factory
        [my_factory, my_factory.write_for_marshal(self)]
      end

      def marshal_load(data_) # :nodoc:
        obj = data_[0].read_for_marshal(data_[1])
        _steal(obj)
      end

      # Psych support

      def encode_with(coder) # :nodoc:
        my_factory = factory
        coder["factory"] = my_factory
        str = my_factory.write_for_psych(self)
        str = str.encode("US-ASCII") if str.respond_to?(:encode)
        coder["wkt"] = str
      end

      def init_with(coder) # :nodoc:
        obj = coder["factory"].read_for_psych(coder["wkt"])
        _steal(obj)
      end

      def as_text
        str = _as_text
        str.force_encoding("US-ASCII") if str.respond_to?(:force_encoding)
        str
      end
      alias to_s as_text
    end

    module CAPIGeometryCollectionMethods # :nodoc:
      include Enumerable
    end

    class CAPIGeometryImpl
      include Feature::Geometry
      include ImplHelper::ValidityCheck
      include CAPIGeometryMethods
    end

    class CAPIPointImpl
      include Feature::Point
      include ImplHelper::ValidityCheck
      include CAPIGeometryMethods
      include CAPIPointMethods
    end

    class CAPILineStringImpl
      include Feature::LineString
      include ImplHelper::ValidityCheck
      include CAPIGeometryMethods
      include CAPILineStringMethods
    end

    class CAPILinearRingImpl
      include Feature::LinearRing
      include ImplHelper::ValidityCheck
      include CAPIGeometryMethods
      include CAPILineStringMethods
      include CAPILinearRingMethods

      def ccw?
        RGeo::Cartesian::Analysis.ccw?(self)
      end
    end

    class CAPILineImpl
      include Feature::Line
      include ImplHelper::ValidityCheck
      include CAPIGeometryMethods
      include CAPILineStringMethods
      include CAPILineMethods
    end

    class CAPIPolygonImpl
      include Feature::Polygon
      include ImplHelper::ValidityCheck
      include CAPIGeometryMethods
      include CAPIPolygonMethods
    end

    class CAPIGeometryCollectionImpl
      include Feature::GeometryCollection
      include ImplHelper::ValidityCheck
      include CAPIGeometryMethods
      include CAPIGeometryCollectionMethods
    end

    class CAPIMultiPointImpl
      include Feature::MultiPoint
      include ImplHelper::ValidityCheck
      include CAPIGeometryMethods
      include CAPIGeometryCollectionMethods
      include CAPIMultiPointMethods
    end

    class CAPIMultiLineStringImpl
      include Feature::MultiLineString
      include ImplHelper::ValidityCheck
      include CAPIGeometryMethods
      include CAPIGeometryCollectionMethods
      include CAPIMultiLineStringMethods
    end

    class CAPIMultiPolygonImpl
      include Feature::MultiPolygon
      include ImplHelper::ValidityCheck
      include CAPIGeometryMethods
      include CAPIGeometryCollectionMethods
      include CAPIMultiPolygonMethods
    end

    ImplHelper::ValidityCheck.override_classes
  end
end
