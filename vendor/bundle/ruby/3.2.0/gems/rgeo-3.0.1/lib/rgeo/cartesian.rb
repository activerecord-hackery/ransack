# frozen_string_literal: true

# The Cartesian module is a gateway to implementations that use the
# Cartesian (i.e. flat) coordinate system. It provides convenient
# access to Cartesian factories such as the Geos implementation and
# the simple Cartesian implementation. It also provides a namespace
# for Cartesian-specific analysis tools.

require_relative "cartesian/calculations"
require_relative "cartesian/feature_methods"
require_relative "cartesian/valid_op"
require_relative "cartesian/feature_classes"
require_relative "cartesian/factory"
require_relative "cartesian/interface"
require_relative "cartesian/bounding_box"
require_relative "cartesian/analysis"
require_relative "cartesian/sweepline_intersector"
require_relative "cartesian/planar_graph"
