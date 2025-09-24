# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Utility module
#
# -----------------------------------------------------------------------------

module RGeo
  module ImplHelper # :nodoc:
    module Utils # :nodoc:
      # Helper function to create coord_sys from
      # common options in most factories. Returns
      # a hash with finalized coord sys info after processing.
      #
      # The reason we return the data as a hash instead of assigning
      # instance variables is because some classes need to do this
      # multiple times with different values and others pass the data
      # to a CAPI or FFI.
      def self.setup_coord_sys(srid, coord_sys, coord_sys_class)
        coord_sys_class = CoordSys::CONFIG.default_coord_sys_class unless coord_sys_class.is_a?(Class)

        coord_sys = coord_sys_class.create_from_wkt(coord_sys) if coord_sys.is_a?(String)

        srid ||= coord_sys.authority_code if coord_sys
        srid = srid.to_i
        # Create a coord sys based on the SRID if one was not given
        coord_sys = coord_sys_class.create(srid) if coord_sys.nil? && srid != 0

        { coord_sys: coord_sys, srid: srid }
      end

      private

      def symbolize_hash(hash)
        nhash = {}
        hash.each do |k, v|
          nhash[k.to_sym] = v.is_a?(String) ? v.to_sym : v
        end
        nhash
      end
    end
  end
end
