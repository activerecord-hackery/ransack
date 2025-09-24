# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Simple Sweepline Intersector Class
#
# -----------------------------------------------------------------------------

module RGeo
  module Cartesian
    # Implements a Sweepline intersector to find all intersections
    # in a group of segments. The idea is to use a horizontal line starting
    # at y = +Infinity that sweeps down to y = -Infinity and every time it hits
    # a new line, it will check if it intersects with any of the segments
    # the line currently intersects at that y value.
    # This is a more simplistic implementation that uses an array to hold
    # observed segments instead of a sorted BST, so performance may be significantly
    # worse in the case of lots of segments overlapping in y-ranges.
    class SweeplineIntersector
      Event = Struct.new(:point, :segment, :is_start)
      Intersection = Struct.new(:point, :s1, :s2)

      def initialize(segments)
        @segments = segments
      end
      attr_reader :segments

      # Returns the "proper" intersections from the list of segments.
      #
      # This will only return intersections that are not the start/end or
      # end/start of the 2 segments. This could be useful for finding intersections
      # in a ring for example, because knowing that segments are connected in a linestring
      # is not always helpful, but those are reported by default.
      #
      # Note: This is not the true definition of a proper intersection. A
      # truly proper intersection does not include colinear intersections and
      # the intersection must lie in the interior of both segments.
      #
      # @return [Array<RGeo::Cartesian::SweeplineIntersector::Intersection>]
      def proper_intersections
        return @proper_intersections if defined?(@proper_intersections)

        @proper_intersections = []
        intersections.each do |intersection|
          s1 = intersection.s1
          s2 = intersection.s2
          pt = intersection.point

          @proper_intersections << intersection unless (pt == s1.s && pt == s2.e) || (pt == s1.e && pt == s2.s)
        end
        @proper_intersections
      end

      # Computes the intersections of the input segments.
      #
      # Creates an event queue from the +events+ and adds segments to the
      # +observed_segments+ array while their ending event has not been popped
      # from the queue.
      #
      # Compares the new segment from the +is_start+ event to each observed segment
      # then adds it to +observed_segments+. Records any intersections in to the
      # returned array.
      #
      # @return [Array<RGeo::Cartesian::SweeplineIntersector::Intersection>]
      def intersections
        return @intersections if defined?(@intersections)

        @intersections = []
        observed_segments = Set.new
        events.each do |e|
          seg = e.segment

          if e.is_start
            observed_segments.each do |oseg|
              int_pt = seg.segment_intersection(oseg)
              if int_pt
                intersect = Intersection.new(int_pt, seg, oseg)
                @intersections << intersect
              end
            end
            observed_segments << seg
          else
            observed_segments.delete(seg)
          end
        end
        @intersections
      end

      # Returns an ordered array of events from the input segments. Events
      # are the start and endpoints of each segment with an is_start tag to
      # indicate if this is the starting or ending event for that segment.
      #
      # Ordering is done by greatest-y -> smallest-x -> is_start = true.
      #
      # @return [Array]
      def events
        return @events if defined?(@events)

        @events = []
        segments.each do |segment|
          event_pair = create_event_pair(segment)
          @events.concat(event_pair)
        end

        @events.sort! do |a, b|
          if a.point == b.point
            if a.is_start
              -1
            else
              1
            end
          elsif a.point.y == b.point.y
            a.point.x <=> b.point.x
          else
            b.point.y <=> a.point.y
          end
        end
        @events
      end

      private

      # Creates a pair of events from a segment
      #
      # @param segment [Segment]
      #
      # @return [Array]
      def create_event_pair(segment)
        s = segment.s
        e = segment.e

        s_event = Event.new(s, segment)
        e_event = Event.new(e, segment)

        if s.y > e.y || (s.y == e.y && s.x < e.x)
          s_event.is_start = true
          e_event.is_start = false
        else
          s_event.is_start = false
          e_event.is_start = true
        end

        [s_event, e_event]
      end
    end
  end
end
