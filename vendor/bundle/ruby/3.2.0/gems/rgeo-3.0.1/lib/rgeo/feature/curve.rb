# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Curve feature interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # == SFS 1.1 Description
    #
    # A Curve is a 1-dimensional geometric object usually stored as a
    # sequence of Points, with the subtype of Curve specifying the form of
    # the interpolation between Points. This part of ISO 19125 defines only
    # one subclass of Curve, LineString, which uses linear interpolation
    # between Points.
    #
    # A Curve is a 1-dimensional geometric object that is the homeomorphic
    # image of a real, closed interval D=[a,b] under a mapping f:[a,b]->R2.
    #
    # A Curve is simple if it does not pass through the same Point twice.
    #
    # A Curve is closed if its start Point is equal to its end Point.
    #
    # The boundary of a closed Curve is empty.
    #
    # A Curve that is simple and closed is a Ring.
    #
    # The boundary of a non-closed Curve consists of its two end Points.
    #
    # A Curve is defined as topologically closed.
    #
    # == Notes
    #
    # Curve is defined as a module and is provided primarily
    # for the sake of documentation. Implementations need not necessarily
    # include this module itself. Therefore, you should not depend on the
    # kind_of? method to check type. Instead, use the provided check_type
    # class method (or === operator) defined in the Type module.
    #
    # Some implementations may support higher dimensional points.
    module Curve
      include Geometry
      extend Type

      # === SFS 1.1 Description
      #
      # The length of this Curve in its associated spatial reference.
      #
      # === Notes
      #
      # Returns a floating-point scalar value.

      def length
        raise Error::UnsupportedOperation, "Method Curve#length not defined."
      end

      # === SFS 1.1 Description
      #
      # The start Point of this Curve.
      #
      # === Notes
      #
      # Returns an object that supports the Point interface.

      def start_point
        raise Error::UnsupportedOperation, "Method Curve#start_point not defined."
      end

      # === SFS 1.1 Description
      #
      # The end Point of this Curve.
      #
      # === Notes
      #
      # Returns an object that supports the Point interface.

      def end_point
        raise Error::UnsupportedOperation, "Method Curve#end_point not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this Curve is closed [StartPoint() = EndPoint()].
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.

      def closed?
        raise Error::UnsupportedOperation, "Method Curve#closed? not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this Curve is closed [StartPoint() = EndPoint()]
      # and this Curve is simple (does not pass through the same Point
      # more than once).
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.

      def ring?
        raise Error::UnsupportedOperation, "Method Curve#ring? not defined."
      end
    end
  end
end
