# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# GEOS implementation additions written in Ruby
#
# -----------------------------------------------------------------------------

module RGeo
  module Geos
    class ZMPointImpl # :nodoc:
      include ZMGeometryMethods
      include ZMPointMethods
    end

    class ZMLineStringImpl  # :nodoc:
      include ZMGeometryMethods
      include ZMLineStringMethods
    end

    class ZMLinearRingImpl  # :nodoc:
      include ZMGeometryMethods
      include ZMLineStringMethods
    end

    class ZMLineImpl # :nodoc:
      include ZMGeometryMethods
      include ZMLineStringMethods
    end

    class ZMPolygonImpl # :nodoc:
      include ZMGeometryMethods
      include ZMPolygonMethods
    end

    class ZMGeometryCollectionImpl # :nodoc:
      include ZMGeometryMethods
      include ZMGeometryCollectionMethods
    end

    class ZMMultiPointImpl # :nodoc:
      include ZMGeometryMethods
      include ZMGeometryCollectionMethods
    end

    class ZMMultiLineStringImpl # :nodoc:
      include ZMGeometryMethods
      include ZMGeometryCollectionMethods
      include ZMMultiLineStringMethods
    end

    class ZMMultiPolygonImpl # :nodoc:
      include ZMGeometryMethods
      include ZMGeometryCollectionMethods
      include ZMMultiPolygonMethods
    end

    class ZMGeometryImpl # :nodoc:
      include ZMGeometryMethods
    end
  end
end
