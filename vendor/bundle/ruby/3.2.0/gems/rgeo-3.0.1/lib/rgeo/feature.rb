# frozen_string_literal: true

# The Feature module contains interfaces and general tools for
# implementations of the Open Geospatial Consortium Simple Features
# Specification (SFS), version 1.1.0.
#
# Each interface is defined as a module, and is provided primarily for
# the sake of documentation. Implementations do not necessarily include
# the modules themselves. Therefore, you should not depend on the
# kind_of? method to check type. Instead, each interface module will
# provide a check_type class method (and a corresponding === operator
# to support case-when constructs).
#
# In addition, a Factory interface is defined here. A factory is an
# object that knows how to construct geometry instances for a given
# implementation. Each implementation's front-end consists of a way to
# create factories. Those factories, in turn, provide the api for
# building the features themselves. Note that, like the geometry
# modules, the Factory module itself may not actually be included in a
# factory implementation.
#
# Any particular implementation may extend these interfaces to provide
# implementation-specific features beyond what is stated in the SFS
# itself. The implementation should separately document any such
# extensions that it may provide.

require_relative "feature/factory"
require_relative "feature/types"
require_relative "feature/geometry"
require_relative "feature/point"
require_relative "feature/curve"
require_relative "feature/line_string"
require_relative "feature/linear_ring"
require_relative "feature/line"
require_relative "feature/surface"
require_relative "feature/polygon"
require_relative "feature/geometry_collection"
require_relative "feature/multi_point"
require_relative "feature/multi_curve"
require_relative "feature/multi_line_string"
require_relative "feature/multi_surface"
require_relative "feature/multi_polygon"
require_relative "feature/factory_generator"
