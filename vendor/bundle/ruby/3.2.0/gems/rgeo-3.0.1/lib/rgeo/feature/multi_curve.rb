# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# MultiCurve feature interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # == SFS 1.1 Description
    #
    # A MultiCurve is a 1-dimensional GeometryCollection whose elements are
    # Curves.
    #
    # MultiCurve is a non-instantiable class in this specification; it
    # defines a set of methods for its subclasses and is included for
    # reasons of extensibility.
    #
    # A MultiCurve is simple if and only if all of its elements are simple
    # and the only intersections between any two elements occur at Points
    # that are on the boundaries of both elements.
    #
    # The boundary of a MultiCurve is obtained by applying the "mod 2"
    # union rule: A Point is in the boundary of a MultiCurve if it is in
    # the boundaries of an odd number of elements of the MultiCurve.
    #
    # A MultiCurve is closed if all of its elements are closed. The
    # boundary of a closed MultiCurve is always empty.
    #
    # A MultiCurve is defined as topologically closed.
    #
    # == Notes
    #
    # MultiCurve is defined as a module and is provided primarily
    # for the sake of documentation. Implementations need not necessarily
    # include this module itself. Therefore, you should not depend on the
    # kind_of? method to check type. Instead, use the provided check_type
    # class method (or === operator) defined in the Type module.
    module MultiCurve
      include GeometryCollection
      extend Type

      # === SFS 1.1 Description
      #
      # The Length of this MultiCurve which is equal to the sum of the
      # lengths of the element Curves.
      #
      # === Notes
      #
      # Returns a floating-point scalar value.

      def length
        raise Error::UnsupportedOperation, "Method MultiCurve#length not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this MultiCurve is closed [StartPoint() = EndPoint()
      # for each Curve in this MultiCurve].
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.

      def closed?
        raise Error::UnsupportedOperation, "Method MultiCurve#closed? not defined."
      end
    end
  end
end
