# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Various Geos-related internal utilities
#
# -----------------------------------------------------------------------------

module RGeo
  module Geos
    module Utils # :nodoc:
      class << self
        def ffi_coord_seqs_equal?(cs1, cs2, check_z)
          len1 = cs1.length
          len2 = cs2.length
          if len1 == len2
            (0...len1).each do |i|
              return false unless cs1.get_x(i) == cs2.get_x(i) &&
                cs1.get_y(i) == cs2.get_y(i) &&
                (!check_z || cs1.get_z(i) == cs2.get_z(i))
            end
            true
          else
            false
          end
        end

        def ffi_compute_dimension(geom)
          result = -1
          case geom.type_id
          when ::Geos::GeomTypes::GEOS_POINT
            result = 0
          when ::Geos::GeomTypes::GEOS_MULTIPOINT
            result = 0 unless geom.empty?
          when ::Geos::GeomTypes::GEOS_LINESTRING, ::Geos::GeomTypes::GEOS_LINEARRING
            result = 1
          when ::Geos::GeomTypes::GEOS_MULTILINESTRING
            result = 1 unless geom.empty?
          when ::Geos::GeomTypes::GEOS_POLYGON
            result = 2
          when ::Geos::GeomTypes::GEOS_MULTIPOLYGON
            result = 2 unless geom.empty?
          when ::Geos::GeomTypes::GEOS_GEOMETRYCOLLECTION
            geom.each do |g|
              dim = ffi_compute_dimension(g)
              result = dim if result < dim
            end
          end
          result
        end

        def ffi_coord_seq_hash(coord_seq, init_hash = 0)
          (0...coord_seq.length).inject(init_hash) do |hash, i|
            [hash, coord_seq.get_x(i), coord_seq.get_y(i), coord_seq.get_z(i)].hash
          end
        end

        def ffi_supports_prepared_level1
          FFI_SUPPORTED && ::Geos::FFIGeos.respond_to?(:GEOSPreparedContains_r)
        end

        def ffi_supports_prepared_level2
          FFI_SUPPORTED && ::Geos::FFIGeos.respond_to?(:GEOSPreparedDisjoint_r)
        end

        def ffi_supports_set_output_dimension
          FFI_SUPPORTED && ::Geos::FFIGeos.respond_to?(:GEOSWKTWriter_setOutputDimension_r)
        end

        def ffi_supports_unary_union
          FFI_SUPPORTED && ::Geos::FFIGeos.respond_to?(:GEOSUnaryUnion_r)
        end

        def psych_wkt_generator
          WKRep::WKTGenerator.new(convert_case: :upper)
        end

        def marshal_wkb_generator
          WKRep::WKBGenerator.new
        end
      end
    end
  end
end
