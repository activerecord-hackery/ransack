# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Common methods for GeometryCollection features
#
# -----------------------------------------------------------------------------

module RGeo
  module ImplHelper # :nodoc:
    module BasicGeometryCollectionMethods # :nodoc:
      include Enumerable

      attr_reader :elements

      def initialize(factory, elements)
        self.factory = factory
        @elements = elements.map do |elem|
          elem = Feature.cast(elem, factory)
          raise Error::InvalidGeometry, "Could not cast #{elem}" unless elem
          elem
        end
        init_geometry
      end

      def num_geometries
        @elements.size
      end

      def geometry_n(idx)
        idx < 0 ? nil : @elements[idx]
      end

      def [](idx)
        @elements[idx]
      end

      def each(&block)
        @elements.each(&block)
      end

      def geometries
        @elements
      end

      def dimension
        @dimension ||= @elements.map(&:dimension).max || -1
      end

      def geometry_type
        Feature::GeometryCollection
      end

      def empty?
        @elements.size == 0
      end

      def rep_equals?(rhs)
        if rhs.is_a?(self.class) && rhs.factory.eql?(@factory) && @elements.size == rhs.num_geometries
          rhs.each_with_index { |p, i| return false unless @elements[i].rep_equals?(p) }
        else
          false
        end
      end

      def hash
        @hash ||= [factory, geometry_type, *@elements].hash
      end

      private

      def copy_state_from(obj)
        super
        @elements = obj.elements
      end
    end

    module BasicMultiLineStringMethods # :nodoc:
      def initialize(factory, elements)
        self.factory = factory
        @elements = elements.map do |elem|
          elem = Feature.cast(elem, factory, Feature::LineString, :keep_subtype)
          raise Error::InvalidGeometry, "Could not cast #{elem}" unless elem
          elem
        end
        init_geometry
      end

      def geometry_type
        Feature::MultiLineString
      end

      def closed?
        all?(&:closed?)
      end

      def length
        @elements.inject(0.0) { |sum, obj| sum + obj.length }
      end

      def boundary
        hash = {}
        @elements.each do |line|
          if !line.empty? && !line.closed?
            add_boundary(hash, line.start_point)
            add_boundary(hash, line.end_point)
          end
        end
        array = []
        hash.each do |_hval, data_|
          array << data_[0] if data_[1].odd?
        end
        factory.multipoint([array])
      end

      def coordinates
        @elements.map(&:coordinates)
      end

      def contains?(rhs)
        return super unless Feature::Point === rhs

        @elements.any? { |line| line.contains?(rhs) }
      end

      private

      def add_boundary(hash, point)
        hval = [point.x, point.y].hash
        (hash[hval] ||= [point, 0])[1] += 1
      end
    end

    module BasicMultiPointMethods # :nodoc:
      def initialize(factory, elements)
        self.factory = factory
        @elements = elements.map do |elem|
          elem = Feature.cast(elem, factory, Feature::Point, :keep_subtype)
          raise Error::InvalidGeometry, "Could not cast #{elem}" unless elem
          elem
        end
        init_geometry
      end

      def geometry_type
        Feature::MultiPoint
      end

      def boundary
        factory.collection([])
      end

      def coordinates
        @elements.map(&:coordinates)
      end
    end

    module BasicMultiPolygonMethods # :nodoc:
      def initialize(factory, elements)
        self.factory = factory
        @elements = elements.map do |elem|
          elem = Feature.cast(elem, factory, Feature::Polygon, :keep_subtype)
          raise Error::InvalidGeometry, "Could not cast #{elem}" unless elem
          elem
        end
        init_geometry
      end

      def geometry_type
        Feature::MultiPolygon
      end

      def area
        @elements.inject(0.0) { |sum, obj| sum + obj.area }
      end

      def boundary
        array = []
        @elements.each do |poly|
          array << poly.exterior_ring unless poly.empty?
          array.concat(poly.interior_rings)
        end
        factory.multi_line_string(array)
      end

      def coordinates
        @elements.map(&:coordinates)
      end

      def contains?(rhs)
        return super unless Feature::Point === rhs

        @elements.any? { |poly| poly.contains?(rhs) }
      end
    end
  end
end
