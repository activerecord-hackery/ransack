# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# MultiLineString feature interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # == SFS 1.1 Description
    #
    # A MultiLineString is a MultiCurve whose elements are LineStrings.
    #
    # == Notes
    #
    # MultiLineString is defined as a module and is provided primarily
    # for the sake of documentation. Implementations need not necessarily
    # include this module itself. Therefore, you should not depend on the
    # kind_of? method to check type. Instead, use the provided check_type
    # class method (or === operator) defined in the Type module.

    module MultiLineString
      include MultiCurve
      extend Type
    end
  end
end
