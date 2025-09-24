# frozen_string_literal: true

module RGeo
  module ActiveRecord
    class SpatialFactoryStore
      include Singleton
      Entry = Struct.new(:attrs, :factory)

      attr_accessor :registry

      def initialize
        @registry = []
        @default = nil
      end

      def register(factory, attrs = {})
        registry.push(Entry.new(filter_attrs(attrs), factory))
      end

      def default(attrs = {})
        @default || default_for_attrs(attrs)
      end

      def default=(factory)
        @default = factory
      end

      def factory(attrs)
        closest_factory(attrs) || default(attrs)
      end

      def clear
        @registry = []
      end

      private

      def default_for_attrs(attrs)
        if attrs[:sql_type] =~ /geography/
          Geographic.spherical_factory(to_factory_attrs(attrs))
        else
          Cartesian.preferred_factory(to_factory_attrs(attrs))
        end
      end

      def to_factory_attrs(attrs)
        {
          has_m_coordinate: attrs[:has_m],
          has_z_coordinate: attrs[:has_z],
          srid:             (attrs[:srid] || 0),
        }
      end

      def filter_attrs(attrs)
        attrs.slice(:geo_type, :has_m, :has_z, :sql_type, :srid)
      end

      ##
      # Match attrs to the closest equal to or less specific factory
      #
      # That means that attrs can at most be matched to an Entry with the same
      # number of keys as it. But could match with a factory with only 1 key
      # in its attrs.
      #
      # Examples:
      #   attrs = {sql_type: "geometry" }, entry_attrs = {sql_type: "geometry", geo_type: "point"}
      #   is not a match because the entry is more specific than attrs
      #
      #   attrs = {sql_type: "geometry", geo_type: "point"}, entry_attrs = {sql_type: "geometry"}
      #   is a match because the entry is less specific than attrs and would be the fallback for all "geometry" types
      #
      #   attrs = {sql_type: "geometry", geo_type: "point"}, entry_attrs = {sql_type: "geometry", geo_type: "linestring"}
      #   is not a match because there are mismatched keys
      #
      # If there is no match, nil is returned
      def closest_factory(attrs)
        max_matches = 0
        registry.reduce(nil) do |selected_fac, entry|
          cmp = cmp_attrs(attrs, entry.attrs)
          if cmp > max_matches
            max_matches = cmp
            entry.factory
          else
            selected_fac
          end
        end
      end

      ##
      # Returns number of common key/values
      # or -1 if oth is bigger than attrs, or they have a mismatched key/value pair
      def cmp_attrs(attrs, oth)
        return -1 if oth.size > attrs.size
        matches = 0
        attrs.each do |k, v|
          next if oth[k].nil?
          return -1 unless v == oth[k]
          matches += 1
        end
        matches
      end
    end
  end
end
