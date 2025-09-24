# frozen_string_literal: true

module RGeo
  module ActiveRecord
    # This module is mixed into all geometry objects. It provides an
    # as_json method so that ActiveRecord knows how to generate JSON
    # for a geometry-valued field.

    module GeometryMixin
      # The default JSON generator Proc. Renders geometry fields as WKT.
      DEFAULT_JSON_GENERATOR = Proc.new(&:to_s)

      @json_generator = DEFAULT_JSON_GENERATOR

      # Set the style of JSON generation used for geometry fields in an
      # ActiveRecord model by default. You may pass nil to use
      # DEFAULT_JSON_GENERATOR, a proc that takes a geometry as the
      # argument and returns an object that can be converted to JSON
      # (i.e. usually a hash or string), or one of the following symbolic
      # values:
      #
      # <tt>:wkt</tt>::
      #   Well-known text format. (Same as DEFAULT_JSON_GENERATOR.)
      # <tt>:geojson</tt>::
      #   GeoJSON format. Requires the rgeo-geojson gem.

      def self.set_json_generator(value = nil, &block)
        if block && !value
          value = block
        elsif value == :geojson
          require "rgeo/geo_json"
          value = proc { |geom| GeoJSON.encode(geom) }
        end
        @json_generator = value.is_a?(Proc) ? value : DEFAULT_JSON_GENERATOR
      end

      # Given a feature, returns an object that can be serialized as JSON
      # (i.e. usually a hash or string), using the current json_generator.
      # This is used to generate JSON for geometry-valued ActiveRecord
      # fields by default.

      def self.generate_json(geom)
        @json_generator.call(geom)
      end

      # Serializes this object as JSON for ActiveRecord.

      def as_json(opts = nil)
        GeometryMixin.generate_json(self)
      end
    end

    # include this module in every RGeo feature type
    [
      Geographic::ProjectedGeometryCollectionImpl,
      Geographic::ProjectedLinearRingImpl,
      Geographic::ProjectedLineImpl,
      Geographic::ProjectedLineStringImpl,
      Geographic::ProjectedMultiLineStringImpl,
      Geographic::ProjectedMultiPointImpl,
      Geographic::ProjectedMultiPolygonImpl,
      Geographic::ProjectedPointImpl,
      Geographic::ProjectedPolygonImpl,

      Geographic::SphericalGeometryCollectionImpl,
      Geographic::SphericalLinearRingImpl,
      Geographic::SphericalLineImpl,
      Geographic::SphericalLineStringImpl,
      Geographic::SphericalMultiLineStringImpl,
      Geographic::SphericalMultiPointImpl,
      Geographic::SphericalMultiPolygonImpl,
      Geographic::SphericalPointImpl,
      Geographic::SphericalPolygonImpl,

      Geos::ZMGeometryCollectionImpl,
      Geos::ZMGeometryImpl,
      Geos::ZMLinearRingImpl,
      Geos::ZMLineImpl,
      Geos::ZMLineStringImpl,
      Geos::ZMMultiLineStringImpl,
      Geos::ZMMultiPointImpl,
      Geos::ZMMultiPolygonImpl,
      Geos::ZMPointImpl,
      Geos::ZMPolygonImpl,

      Cartesian::GeometryCollectionImpl,
      Cartesian::LinearRingImpl,
      Cartesian::LineImpl,
      Cartesian::LineStringImpl,
      Cartesian::MultiLineStringImpl,
      Cartesian::MultiPointImpl,
      Cartesian::MultiPolygonImpl,
      Cartesian::PointImpl,
      Cartesian::PolygonImpl
    ].each { |klass| klass.include(GeometryMixin) }

    if RGeo::Geos.capi_supported?
      [
        Geos::CAPIGeometryCollectionImpl,
        Geos::CAPIGeometryImpl,
        Geos::CAPILinearRingImpl,
        Geos::CAPILineImpl,
        Geos::CAPILineStringImpl,
        Geos::CAPIMultiLineStringImpl,
        Geos::CAPIMultiPointImpl,
        Geos::CAPIMultiPolygonImpl,
        Geos::CAPIPointImpl,
        Geos::CAPIPolygonImpl,
      ].each { |klass| klass.include(GeometryMixin) }
    end

    if RGeo::Geos.ffi_supported?
      [
        Geos::FFIGeometryCollectionImpl,
        Geos::FFIGeometryImpl,
        Geos::FFILinearRingImpl,
        Geos::FFILineImpl,
        Geos::FFILineStringImpl,
        Geos::FFIMultiLineStringImpl,
        Geos::FFIMultiPointImpl,
        Geos::FFIMultiPolygonImpl,
        Geos::FFIPointImpl,
        Geos::FFIPolygonImpl,
      ].each { |klass| klass.include(GeometryMixin) }
    end
  end
end
