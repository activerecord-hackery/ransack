# frozen_string_literal: true

# The Geographic module includes a suite of
# implementations with one common feature: they represent geographic
# latitude/longitude coordinates measured in degrees. The "x"
# coordinate corresponds to longitude, and the "y" coordinate to
# latitude. Thus, coordinates are often expressed in reverse
# (i.e. long-lat) order. e.g.
#
#  location = geographic_factory.point(long, lat)
#
# Some geographic implementations include a secondary factory that
# represents a projection. For these implementations, you can quickly
# transform data between lat/long coordinates and the projected
# coordinate system, and most calculations are done in the projected
# coordinate system. For implementations that do not include this
# secondary projection factory, calculations are done on the sphereoid.
# See the various class methods of Geographic for more information on
# the behaviors of the factories they generate.

require_relative "geographic/factory"
require_relative "geographic/projected_window"
require_relative "geographic/interface"
require_relative "geographic/spherical_math"
require_relative "geographic/spherical_feature_methods"
require_relative "geographic/spherical_feature_classes"
require_relative "geographic/projector"
require_relative "geographic/simple_mercator_projector"
require_relative "geographic/projected_feature_methods"
require_relative "geographic/projected_feature_classes"
