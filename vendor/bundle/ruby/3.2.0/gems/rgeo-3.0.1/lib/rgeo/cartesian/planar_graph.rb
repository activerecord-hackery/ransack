# frozen_string_literal: true

module RGeo
  module Cartesian
    # A Doubly Connected Edge List (DCEL) implementation of a Planar Graph.
    # It represents geometries as vertices and half-edges.
    #
    # It includes an incident_edges hash that maps vertices to an array
    # of half-edges whose origins are that vertex.
    #
    # Upon instantiation, the graph will compute the intersections using
    # the SweeplineIntersector, populate the incident_edges map, and
    # link all cyclic edges.
    class PlanarGraph
      # HalfEdge represents an edge as 2 directed edges.
      # One half-edge will have it's origin at edge.s, the other
      # at edge.e. Both half-edges will be linked as each other's twins.
      #
      # HalfEdges also contain references to the next and prev half-edges,
      # where next's origin is this half-edges destination. Prev's destination
      # is this half-edge's origin.
      class HalfEdge
        include Comparable

        # Creates 2 half edges from an edge.
        # They will be assigned as each other's twins.
        # The Half Edges will be returned in the order of points
        # of the edge (start, end).
        #
        # @param edge [RGeo::Cartesian::Segment]
        #
        # @return [Array]
        def self.from_edge(edge)
          e1 = new(edge.s)
          e2 = new(edge.e)

          e1.twin = e2
          e2.twin = e1
          [e1, e2]
        end

        def initialize(origin)
          @origin = origin
          @twin = nil
          @next = nil
          @prev = nil
        end
        attr_reader :origin
        attr_accessor :twin, :next, :prev

        # HalfEdges will be sorted around their shared vertex
        # in a CW fashion. This means that face interiors will be
        # a CCW.
        def <=>(other)
          angle <=> other.angle
        end

        # Will find attempt to find a cycle starting at this
        # HalfEdge. Will end upon finding the first repeated HalfEdge
        # or a HalfEdge where +next+ is nil.
        #
        # If a block is given, each HalfEdge seen will be yielded to the block.
        #
        # @return [Enumerator]
        def and_connected
          return to_enum(__method__) unless block_given?

          hedges = Set.new
          yield(self)
          hedges << self

          n = self.next
          until hedges.include?(n) || n.nil?
            yield(n)
            hedges << n
            n = n.next
          end
        end

        # Return the destination of the half edge
        #
        # @return [RGeo::Feature::Point]
        def destination
          twin&.origin
        end

        # Compute the angle from the positive x-axis.
        # Used for sorting at each node.
        #
        # @return [Float]
        def angle
          @angle ||= Math.atan2(destination.y - origin.y, destination.x - origin.x)
        end

        def inspect
          "#<#{self.class}:0x#{object_id.to_s(16)} #{self}>"
        end

        def to_s
          dst = destination
          pr = prev&.origin
          n = @next&.origin
          "HalfEdge(#{origin}, #{dst}), Prev: #{pr},  Next: #{n}"
        end
      end

      # Create a new PlanarGraph
      #
      # @param edges [Array<RGeo::Cartesian::Segment>] of Segments
      def initialize(edges = [])
        @edges = []
        @incident_edges = {}

        add_edges(edges)
      end
      attr_reader :edges, :incident_edges

      # Insert an edge into the graph. This will automatically
      # calculate intersections and add new vertices if necessary.
      #
      # @param edge [RGeo::Cartesian::Segment]
      def add_edge(edge)
        @edges << edge
        create_half_edge(edge)

        # Check if a new intersection was made and handle it.
        intersection_map.each do |seg, ints|
          compute_split_edges(seg, ints)
        end

        link_half_edges
      end

      # Insert multiple edges into the graph. Like +add_edge+, this automatically
      # calculates intersections and adds new vertices.
      #
      # @param new_edges [Array<RGeo::Cartesian::Segment>]
      def add_edges(new_edges)
        @edges.concat(new_edges)
        new_edges.each do |edge|
          create_half_edge(edge)
        end

        intersection_map.each do |seg, ints|
          compute_split_edges(seg, ints)
        end

        link_half_edges
      end

      private

      # Creates a map of +proper_intersections+ for each segment
      # from a sweepline intersector.
      #
      # Can be used to determine which edges need to be split
      # after adding edges.
      def intersection_map
        intersector = SweeplineIntersector.new(edges)
        intersections = intersector.proper_intersections

        intersection_map = {}
        intersections.each do |int|
          # check the int_point against each edge.
          # if it is not on the boundary of the edge, add it to the
          # list of intersections for that edge.
          s1_intersects = int.point != int.s1.s && int.point != int.s1.e
          if s1_intersects
            intersection_map[int.s1] ||= []
            intersection_map[int.s1] << int.point
          end

          s2_intersects = int.point != int.s2.s && int.point != int.s2.e

          next unless s2_intersects

          intersection_map[int.s2] ||= []
          intersection_map[int.s2] << int.point
        end
        intersection_map
      end

      def create_half_edges
        @edges.each do |edge|
          create_half_edge(edge)
        end
      end

      def create_half_edge(edge)
        e1, e2 = HalfEdge.from_edge(edge)
        insert_half_edge(e1)
        insert_half_edge(e2)
      end

      def insert_half_edge(half_edge)
        @incident_edges[half_edge.origin.coordinates] ||= []
        @incident_edges[half_edge.origin.coordinates] << half_edge
      end

      # Links all half-edges where possible.
      # Defines +next+ and +prev+ for every half-edge by rotating
      # through all half-edges originating at a vertex.
      #
      # Assuming half-edges are sorted CCW, every sequential pair of
      # half-edges (e1, e2) can be linked by saying e1.prev = e2.twin
      # and e2.twin.next = e1.
      def link_half_edges
        incident_edges.each_value do |hedges|
          hedges.sort!
          [*hedges, hedges.first].each_cons(2) do |e1, e2|
            e1.prev = e2.twin
            e2.twin.next = e1
          end
        end
      end

      # It is possible that intersections occur when new edges are added.
      # This will split those edges into more half-edges while preserving
      # the existing half-edges when possible since geometries may reference
      # them.
      def compute_split_edges(seg, ints)
        points = ints.uniq.sort do |a, b|
          a.distance(seg.s) <=> b.distance(seg.s)
        end
        points = [seg.s] + points + [seg.e]

        he_start = incident_edges[points.first.coordinates].find { |he| he.destination == points.last }
        he_end = incident_edges[points.last.coordinates].find { |he| he.destination == points.first }

        points.each_cons(2) do |s, e|
          edge = Segment.new(s, e)
          if s == he_start.origin
            he = HalfEdge.new(e)
            he_start.twin = he
            he.twin = he_start
            insert_half_edge(he)
          elsif e == he_end.origin
            he = HalfEdge.new(s)
            he_end.twin = he
            he.twin = he_end
            insert_half_edge(he)
          else
            create_half_edge(edge)
          end
          @edges << edge
        end
        @edges.delete(seg)
      end
    end

    # GeometryGraph is a PlanarGraph that is built by adding
    # geometries instead of edges. The GeometryGraph will
    # hold a reference to an arbitrary HalfEdge on the
    # interior of the geometry for every boundary in the geometry.
    # For example, a polygon will have a reference to a HalfEdge for its
    # exterior shell and one for every hole.
    class GeometryGraph < PlanarGraph
      # GeomEdge will be used to store the references to the HalfEdges
      GeomEdge = Struct.new(:exterior_edge, :interior_edges)

      def initialize(geom)
        super()
        @parent_geometry = geom
        @geom_edges = []
        add_geometry(geom)
      end
      attr_reader :parent_geometry, :geom_edges

      private

      # Adds a geometry to the graph and finds its
      # reference HalfEdge(s).
      #
      # @param geom [RGeo::Feature::Instance]
      def add_geometry(geom)
        case geom
        when Feature::Point
          # Can't handle points yet, so just add an empty entry for them
          @geom_edges << GeomEdge.new
        when Feature::LineString, Feature::LinearRing
          add_line_string(geom)
        when Feature::Polygon
          add_polygon(geom)
        when Feature::GeometryCollection
          add_collection(geom)
        else
          raise Error::RGeoError, "Invalid Geometry Type: #{geom.class}"
        end
      end

      # Adds a LineString or LinearRing
      # to the graph.
      #
      # @param geom [RGeo::Feature::LineString]
      def add_line_string(geom)
        add_edges(geom.segments)

        hedge = @incident_edges[geom.start_point.coordinates].first unless geom.empty?

        @geom_edges << GeomEdge.new(hedge, nil)
      end

      # Adds a Polygon to the graph.
      #
      # Will add each shell seperately and find a CCW half-edge
      # for the exterior ring and a CW half-edge for interior rings
      # since these are designated as being on the interior of the polygon.
      #
      # It is possible that the half-edge will be nil if a suitable one cannot
      # be found. This indicates the polygon is likely invalid.
      #
      # @param geom [RGeo::Feature::Polygon]
      def add_polygon(geom)
        exterior = geom.exterior_ring
        add_edges(exterior.segments)

        hedge = find_hedge(exterior)

        interior_hedges = []
        geom.interior_rings.each do |interior|
          add_edges(interior.segments)
          interior_hedges << find_hedge(interior, ccw: false)
        end

        @geom_edges << GeomEdge.new(hedge, interior_hedges)
      end

      # Adds a GeometryCollection to the graph.
      #
      # @param col [RGeo::Feature::GeometryCollection]
      def add_collection(col)
        col.each do |geom|
          add_geometry(geom)
        end
      end

      # Finds a Half-Edge that is part of a CCW or CW rotation
      # from the input ring. Returns nil if none found.
      #
      # Will only consider half-edges that are colinear with
      # the first or last segments of the ring.
      #
      # @param ring [RGeo::Feature::LinearRing]
      # @param ccw [Boolean] true for CCW, false for CW
      # @return [HalfEdge, nil]
      def find_hedge(ring, ccw: true)
        return nil if ring.num_points == 0
        ccw_target = ccw ? 1 : -1

        coords = ring.start_point.coordinates
        hedges = incident_edges[coords]

        # find half-edges that are colinear to the start or end
        # segment of the ring.
        start_seg = Segment.new(ring.start_point, ring.point_n(1))
        end_seg = Segment.new(ring.point_n(ring.num_points - 2), ring.end_point)
        colinear_hedges = hedges.select do |he|
          start_seg.side(he.destination) == 0 || end_seg.side(he.destination) == 0
        end

        colinear_hedges.find do |hedge|
          pts = []
          hedge.and_connected do |he|
            pts << he.origin
          end
          pts << hedge.origin
          lr = parent_geometry.factory.line_string(pts)
          Analysis.ring_direction(lr) == ccw_target
        end
      end
    end
  end
end
