# frozen_string_literal: true

# The Geos module provides general tools for creating and manipulating
# a GEOS-backed implementation of the SFS. This is a full implementation
# of the SFS using a Cartesian coordinate system. It uses the GEOS C++
# library to perform most operations, and hence is available only if
# GEOS version 3.2 or later is installed and accessible when the rgeo
# gem is installed. RGeo feature calls are translated into appropriate
# GEOS calls and directed to the library's C api. RGeo also corrects a
# few cases of missing or non-standard behavior in GEOS.
#
# This module also provides a namespace for the implementation classes
# themselves; however, those classes are meant to be opaque and are
# therefore not documented.
#
# To use the Geos implementation, first obtain a factory using the
# RGeo::Geos.factory method. You may then call any of the standard
# factory methods on the resulting object.

# :stopdoc:

module RGeo
  module Geos
    require_relative "geos/utils"
    require_relative "geos/interface"
    begin
      require_relative "geos/geos_c_impl"
    rescue LoadError
      # continue
    end
    CAPI_SUPPORTED = RGeo::Geos.const_defined?(:CAPIGeometryMethods)
    if CAPI_SUPPORTED
      require_relative "geos/capi_feature_classes"
      require_relative "geos/capi_factory"
    end
    require_relative "geos/zm_feature_methods"
    require_relative "geos/zm_feature_classes"
    require_relative "geos/zm_factory"

    # Determine ffi support.
    begin
      require "ffi-geos"
      # An additional check to make sure FFI loaded okay. This can fail on
      # some versions of ffi-geos and some versions of Rubinius.
      raise "Problem loading FFI" unless ::FFI::AutoPointer
      FFI_SUPPORTED = true
      FFI_SUPPORT_EXCEPTION = nil
    rescue LoadError, StandardError => e
      FFI_SUPPORTED = false
      FFI_SUPPORT_EXCEPTION = e
    end

    if FFI_SUPPORTED
      require_relative "geos/ffi_feature_methods"
      require_relative "geos/ffi_feature_classes"
      require_relative "geos/ffi_factory"
    end

    # Default preferred native interface
    if CAPI_SUPPORTED
      self.preferred_native_interface = :capi
    elsif FFI_SUPPORTED
      self.preferred_native_interface = :ffi
    end

    CAP_ROUND  = 1
    CAP_FLAT   = 2
    CAP_SQUARE = 3

    JOIN_ROUND = 1
    JOIN_MITRE = 2
    JOIN_BEVEL = 3
  end
end

# :startdoc:
