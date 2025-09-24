# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# GEOS toplevel interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Geos
    class << self
      # Returns true if the CAPI GEOS implementation is supported.

      def capi_supported?
        CAPI_SUPPORTED
      end

      # Returns true if the FFI GEOS implementation is supported.

      def ffi_supported?
        FFI_SUPPORTED
      end

      # Returns true if any GEOS implementation is supported.
      # If this returns false, GEOS features are not available at all.

      def supported?
        FFI_SUPPORTED || CAPI_SUPPORTED
      end

      # Returns true if the given feature is a CAPI GEOS feature, or if
      # the given factory is a CAPI GEOS factory.

      def capi_geos?(object)
        CAPI_SUPPORTED &&
          (CAPIFactory === object || CAPIGeometryMethods === object ||
          ZMFactory === object && CAPIFactory === object.z_factory ||
          ZMGeometryMethods === object && CAPIGeometryMethods === object.z_geometry)
      end

      # Returns true if the given feature is an FFI GEOS feature, or if
      # the given factory is an FFI GEOS factory.

      def ffi_geos?(object)
        FFI_SUPPORTED &&
          (FFIFactory === object || FFIGeometryMethods === object ||
          ZMFactory === object && FFIFactory === object.z_factory ||
          ZMGeometryMethods === object && FFIGeometryMethods === object.z_geometry)
      end

      # Returns true if the given feature is a GEOS feature, or if the given
      # factory is a GEOS factory. Does not distinguish between CAPI and FFI.

      def geos?(object)
        CAPI_SUPPORTED && (CAPIFactory === object || CAPIGeometryMethods === object) ||
          FFI_SUPPORTED && (FFIFactory === object || FFIGeometryMethods === object) ||
          ZMFactory === object || ZMGeometryMethods === object
      end

      # Returns the GEOS library version as a string of the format "x.y.z".
      # Returns nil if GEOS is not available.

      def version
        unless defined?(@version)
          @version =
            if RGeo::Geos::CAPI_SUPPORTED
              RGeo::Geos::CAPIFactory._geos_version.freeze
            elsif RGeo::Geos::FFI_SUPPORTED
              ::Geos::FFIGeos.GEOSversion.sub(/-CAPI-.*$/, "").freeze
            end
        end
        @version
      end

      # The preferred native interface. This is the native interface
      # used by default when a factory is created.
      # Supported values are <tt>:capi</tt> and <tt>:ffi</tt>.
      #
      # This is set automatically when RGeo loads, to <tt>:capi</tt>
      # if the CAPI interface is available, otheriwse to <tt>:ffi</tt>
      # if FFI is available, otherwise to nil if no GEOS interface is
      # available. You can override this setting if you want to prefer
      # FFI over CAPI.

      attr_accessor :preferred_native_interface

      # Returns a factory for the GEOS implementation.
      # Returns nil if the GEOS implementation is not supported.
      #
      # Note that GEOS does not natively support 4-dimensional data
      # (i.e. both z and m values). However, RGeo's GEOS wrapper does
      # provide a 4-dimensional factory that utilizes an extra native
      # GEOS object to handle the extra coordinate. Hence, a factory
      # configured with both Z and M support will work, but will be
      # slower than a 2-dimensional or 3-dimensional factory.
      #
      # Options include:
      #
      # [<tt>:native_interface</tt>]
      #   Specifies which native interface to use. Possible values are
      #   <tt>:capi</tt> and <tt>:ffi</tt>. The default is the value
      #   of the preferred_native_interface.
      # [<tt>:buffer_resolution</tt>]
      #   The resolution of buffers around geometries created by this
      #   factory. This controls the number of line segments used to
      #   approximate curves. The default is 1, which causes, for
      #   example, the buffer around a point to be approximated by a
      #   4-sided polygon. A resolution of 2 would cause that buffer
      #   to be approximated by an 8-sided polygon. The exact behavior
      #   for different kinds of buffers is defined by GEOS.
      # [<tt>:srid</tt>]
      #   Set the SRID returned by geometries created by this factory.
      #   Default is 0.
      # [<tt>:coord_sys</tt>]
      #   The coordinate system in OGC form, either as a subclass of
      #   CoordSys::CS::CoordinateSystem, or as a string in WKT format.
      #   Optional. If not provided, but <tt>:srid</tt> is, a coord_sys
      #   will be created using the CS::CONFIG.default_coord_sys_class.
      #  [<tt>:coord_sys_class</tt>]
      #    The coordinate system implementation to use if you do not want to
      #    use the CS::CONFIG.default_coord_sys_class. Optional.
      # [<tt>:has_z_coordinate</tt>]
      #   Support <tt>z_coordinate</tt>. Default is false.
      # [<tt>:has_m_coordinate</tt>]
      #   Support <tt>m_coordinate</tt>. Default is false.
      # [<tt>:wkt_parser</tt>]
      #   Configure the parser for WKT. You may either pass a hash of
      #   configuration parameters for WKRep::WKTParser.new, or the
      #   special value <tt>:geos</tt>, indicating to use the native
      #   GEOS parser. Default is the empty hash, indicating the default
      #   configuration for WKRep::WKTParser.
      #   Note that the special <tt>:geos</tt> value is not supported for
      #   ZM factories, since GEOS currently can't handle ZM natively.
      # [<tt>:wkb_parser</tt>]
      #   Configure the parser for WKB. You may either pass a hash of
      #   configuration parameters for WKRep::WKBParser.new, or the
      #   special value <tt>:geos</tt>, indicating to use the native
      #   GEOS parser. Default is the empty hash, indicating the default
      #   configuration for WKRep::WKBParser.
      #   Note that the special <tt>:geos</tt> value is not supported for
      #   ZM factories, since GEOS currently can't handle ZM natively.
      # [<tt>:wkt_generator</tt>]
      #   Configure the generator for WKT. You may either pass a hash of
      #   configuration parameters for WKRep::WKTGenerator.new, or the
      #   special value <tt>:geos</tt>, indicating to use the native
      #   GEOS generator. Default is <tt>{:convert_case => :upper}</tt>.
      #   Note that the special <tt>:geos</tt> value is not supported for
      #   ZM factories, since GEOS currently can't handle ZM natively.
      # [<tt>:wkb_generator</tt>]
      #   Configure the generator for WKB. You may either pass a hash of
      #   configuration parameters for WKRep::WKBGenerator.new, or the
      #   special value <tt>:geos</tt>, indicating to use the native
      #   GEOS generator. Default is the empty hash, indicating the
      #   default configuration for WKRep::WKBGenerator.
      #   Note that the special <tt>:geos</tt> value is not supported for
      #   ZM factories, since GEOS currently can't handle ZM natively.
      # [<tt>:auto_prepare</tt>]
      #   Request an auto-prepare strategy. Supported values are
      #   <tt>:simple</tt> and <tt>:disabled</tt>. The former (which is
      #   the default) generates a prepared geometry the second time an
      #   operation that would benefit from it is called. The latter
      #   never automatically generates a prepared geometry (unless you
      #   generate one explicitly using the <tt>prepare!</tt> method).
      def factory(opts = {})
        return unless supported?

        native_interface = opts[:native_interface] || Geos.preferred_native_interface

        if opts[:has_z_coordinate] && opts[:has_m_coordinate]
          ZMFactory.new(opts)
        elsif native_interface == :ffi
          FFIFactory.new(opts)
        else
          CAPIFactory.create(opts)
        end
      end
    end
  end
end
