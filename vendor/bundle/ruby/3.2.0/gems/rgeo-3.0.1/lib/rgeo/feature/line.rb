# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Line feature interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # == SFS 1.1 Description
    #
    # A Line is a LineString with exactly 2 Points.
    #
    # == Notes
    #
    # Line is defined as a module and is provided primarily
    # for the sake of documentation. Implementations need not necessarily
    # include this module itself. Therefore, you should not depend on the
    # kind_of? method to check type. Instead, use the provided check_type
    # class method (or === operator) defined in the Type module.

    module Line
      include LineString
      extend Type
    end
  end
end
