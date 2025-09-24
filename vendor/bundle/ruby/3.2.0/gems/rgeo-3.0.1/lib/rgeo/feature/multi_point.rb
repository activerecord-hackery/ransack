# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# MultiPoint feature interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # == SFS 1.1 Description
    #
    # A MultiPoint is a 0-dimensional GeometryCollection. The elements of
    # a MultiPoint are restricted to Points. The Points are not connected
    # or ordered.
    #
    # A MultiPoint is simple if no two Points in the MultiPoint are equal
    # (have identical coordinate values).
    #
    # The boundary of a MultiPoint is the empty set.
    #
    # == Notes
    #
    # MultiPoint is defined as a module and is provided primarily
    # for the sake of documentation. Implementations need not necessarily
    # include this module itself. Therefore, you should not depend on the
    # kind_of? method to check type. Instead, use the provided check_type
    # class method (or === operator) defined in the Type module.

    module MultiPoint
      include GeometryCollection
      extend Type
    end
  end
end
