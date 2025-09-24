# frozen_string_literal: true

module RGeo
  module ActiveRecord
    # Return a feature type module given a string type.
    def self.geometric_type_from_name(name)
      case name.to_s
      when /^geometrycollection/i then Feature::GeometryCollection
      when /^geometry/i then Feature::Geometry
      when /^linestring/i then Feature::LineString
      when /^multilinestring/i then Feature::MultiLineString
      when /^multipoint/i then Feature::MultiPoint
      when /^multipolygon/i then Feature::MultiPolygon
      when /^point/i then Feature::Point
      when /^polygon/i then Feature::Polygon
      end
    end
  end
end
