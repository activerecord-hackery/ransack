# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# LineString feature interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # == SFS 1.1 Description
    #
    # A LineString is a Curve with linear interpolation between Points.
    # Each consecutive pair of Points defines a Line segment.
    #
    # == Notes
    #
    # LineString is defined as a module and is provided primarily
    # for the sake of documentation. Implementations need not necessarily
    # include this module itself. Therefore, you should not depend on the
    # kind_of? method to check type. Instead, use the provided check_type
    # class method (or === operator) defined in the Type module.
    module LineString
      include Curve
      extend Type

      # === SFS 1.1 Description
      #
      # The number of Points in this LineString.
      #
      # === Notes
      #
      # Returns an integer.

      def num_points
        raise Error::UnsupportedOperation, "Method #{self.class}#num_points not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns the specified Point N in this LineString.
      #
      # === Notes
      #
      # Returns an object that supports the Point interface, or nil
      # if the given N is out of range. N is zero-based.
      # Does not support negative indexes.

      def point_n(_idx)
        raise Error::UnsupportedOperation, "Method #{self.class}#point_n not defined."
      end

      # Returns the constituent points as an array of objects that
      # support the Point interface.

      def points
        raise Error::UnsupportedOperation, "Method #{self.class}#points not defined."
      end
    end
  end
end
