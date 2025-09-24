# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# GeometryCollection feature interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # == SFS 1.1 Description
    #
    # A GeometryCollection is a geometric object that is a collection of 1
    # or more geometric objects.
    #
    # All the elements in a GeometryCollection shall be in the same Spatial
    # Reference. This is also the Spatial Reference for the GeometryCollection.
    #
    # GeometryCollection places no other constraints on its elements.
    # Subclasses of GeometryCollection may restrict membership based on
    # dimension and may also place other constraints on the degree of spatial
    # overlap between elements.
    #
    # == Notes
    #
    # GeometryCollection is defined as a module and is provided primarily
    # for the sake of documentation. Implementations need not necessarily
    # include this module itself. Therefore, you should not depend on the
    # kind_of? method to check type. Instead, use the provided check_type
    # class method (or === operator) defined in the Type module.
    module GeometryCollection
      include Geometry
      extend Type

      include Enumerable

      # === SFS 1.1 Description
      #
      # Returns the number of geometries in this GeometryCollection.
      #
      # === Notes
      #
      # Returns an integer.

      def num_geometries
        raise Error::UnsupportedOperation, "Method #{self.class}#num_geometries not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns the Nth geometry in this GeometryCollection.
      #
      # === Notes
      #
      # Returns an object that supports the Geometry interface, or nil
      # if the given N is out of range. N is zero-based.
      # Also note that this method is different from GeometryCollection#[]
      # in that it does not support negative indexes.

      def geometry_n(_idx)
        raise Error::UnsupportedOperation, "Method #{self.class}#geometry_n not defined."
      end

      # Alias of the num_geometries method.

      def size
        num_geometries
      end

      # Returns the Nth geometry in this GeometryCollection, or nil if the
      # given N is out of range. N is zero-based.
      #
      # This behaves slightly different from GeometryCollection#geometry_n.
      # GeometryCollection#geometry_n accepts only nonnegative indexes,
      # as specified by the SFS. However, GeometryCollection#[] also accepts
      # negative indexes counting backwards from the end of the collection,
      # the same way Ruby's array indexing works. Hence, geometry_n(-1)
      # returns nil, where [-1] returns the last element of the collection.

      def [](_idx)
        raise Error::UnsupportedOperation, "Method #{self.class}#[] not defined."
      end

      # Nodes the linework in a list of Geometries
      #
      def node
        raise Error::UnsupportedOperation, "Method #{self.class}#node not defined."
      end

      # Iterates over the geometries of this GeometryCollection.
      #
      # This is not a standard SFS method, but is provided so that a
      # GeometryCollection can behave as a Ruby enumerable.
      # Note that all GeometryCollection implementations must also
      # include the Enumerable mixin.

      def each(&_block)
        raise Error::UnsupportedOperation, "Method #{self.class}#each not defined."
      end

      # Gives a point that is guaranteed to be within the geometry.
      #
      # Extends OGC SFS 1.1 and follows PostGIS standards.
      # @see https://postgis.net/docs/ST_PointOnSurface.html
      def point_on_surface
        raise Error::UnsupportedOperation, "Method #{self.class}#each not defined."
      end
    end
  end
end
