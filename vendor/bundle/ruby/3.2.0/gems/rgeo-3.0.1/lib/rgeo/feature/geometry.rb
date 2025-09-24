# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Geometry feature interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # == SFS 1.1 Description
    #
    # Geometry is the root class of the hierarchy. Geometry is an abstract
    # (non-instantiable) class.
    #
    # The instantiable subclasses of Geometry defined in this International
    # Standard are restricted to 0, 1 and 2-dimensional geometric objects
    # that exist in 2-dimensional coordinate space (R2).
    #
    # All instantiable Geometry classes described in this part of ISO 19125
    # are defined so that valid instances of a Geometry class are
    # topologically closed, i.e. all defined geometries include their
    # boundary.
    #
    # == Notes
    #
    # Geometry is defined as a module and is provided primarily for the
    # sake of documentation. Implementations need not necessarily include
    # this module itself. Therefore, you should not depend on the result
    # of <tt>is_a?(Geometry)</tt> to check type. Instead, use the
    # provided check_type class method (or === operator) defined in the
    # Type module.
    #
    # Some implementations may support higher dimensional objects or
    # coordinate systems, despite the limits of the SFS.
    #
    # == Forms of equivalence
    #
    # The Geometry model defines three forms of equivalence.
    #
    # * <b>Spatial equivalence</b> is the weakest form of equivalence,
    #   indicating that the objects represent the same region of space,
    #   but may be different representations of that region. For example,
    #   POINT(0 0) and a MULTIPOINT(0 0) are spatially equivalent, as are
    #   LINESTRING(0 0, 10 10) and
    #   GEOMETRYCOLLECTION(POINT(0 0), LINESTRING(0 0, 10 10, 0 0)).
    #   As a general rule, objects must have factories that are
    #   Factory#eql? in order to be spatially equivalent.
    #
    # * <b>Representational equivalence</b> is a stronger form, indicating
    #   that the objects have the same representation, but may be
    #   different objects. All representationally equivalent objects are
    #   spatially equivalent, but not all spatially equivalent objects are
    #   representationally equivalent. For example, none of the examples
    #   in the spatial equivalence section above are representationally
    #   equivalent. However, two separate objects that both represent
    #   POINT(1 2) are representationally equivalent as well as spatially
    #   equivalent.
    #
    # * <b>Objective equivalence</b> is the strongest form, indicating
    #   that the references refer to the same object. Of course, all
    #   pairs of references with the same objective identity are also
    #   both representationally and spatially equivalent.
    #
    # Different methods test for different types of equivalence:
    #
    # * <tt>equals?</tt> and <tt>==</tt> test for spatial equivalence.
    # * <tt>rep_equals?</tt> and <tt>eql?</tt> test for representational
    #   equivalence.
    # * <tt>equal?</tt> tests for objective equivalence.
    #
    # All ruby objects must provide a suitable test for objective
    # equivalence. Normally, this is simply provided by the Ruby Object
    # base class. Geometry implementations should normally also provide
    # tests for representational and spatial equivalence, if possible.
    # The <tt>==</tt> operator and the <tt>eql?</tt> method are standard
    # Ruby methods that are often expected to be usable for every object.
    # Therefore, if an implementation cannot provide a suitable test for
    # their equivalence types, they must degrade to use a stronger form
    # of equivalence.
    module Geometry
      extend Type

      # Returns a factory for creating features related to this one.
      # This does not necessarily need to be the same factory that created
      # this object, but it should create objects that are "compatible"
      # with this one. (i.e. they should be in the same spatial reference
      # system by default, and it should be possible to perform relational
      # operations on them.)

      def factory
        raise Error::UnsupportedOperation, "Method #{self.class}#factory not defined."
      end

      # === SFS 1.1 Description
      #
      # The inherent dimension of this geometric object, which must be less
      # than or equal to the coordinate dimension. This specification is
      # restricted to geometries in 2-dimensional coordinate space.
      #
      # === Notes
      #
      # Returns an integer. This value is -1 for an empty geometry, 0 for
      # point geometries, 1 for curves, and 2 for surfaces.

      def dimension
        raise Error::UnsupportedOperation, "Method #{self.class}#dimension not defined."
      end

      # === SFS 1.2 Description
      #
      # The coordinate dimension is the dimension of direct positions (coordinate tuples) used in
      # the definition of this geometric object
      #
      # === Notes
      #
      # Difference between this and dimension is that this is the dimension of the coordinate
      # not the dimension of the geometry.
      #
      # @return [Integer]
      def coordinate_dimension
        raise Error::UnsupportedOperation, "Method #{self.class}#coordinate_dimension not defined."
      end

      # === SFS 1.2 Description
      #
      # The spatial dimension is the dimension of the spatial portion of the direct positions
      # (coordinate tuples) used in the definition of this geometric object. If the direct positions
      # do not carry a measure coordinate, this will be equal to the coordinate dimension.
      #
      # === Notes
      #
      # Similar to coordinate_dimension except it will ignore the M component always.
      #
      # @return [Integer]
      def spatial_dimension
        raise Error::UnsupportedOperation, "Method #{self.class}#spatial_dimension not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns the instantiable subtype of Geometry of which this
      # geometric object is an instantiable member.
      #
      # === Notes
      #
      # Returns one of the type modules in RGeo::Feature. e.g. a point
      # object would return RGeo::Feature::Point. Note that this is
      # different from the SFS specification, which stipulates that the
      # string name of the type is returned. To obtain the name string,
      # call the +type_name+ method of the returned module.

      def geometry_type
        raise Error::UnsupportedOperation, "Method #{self.class}#geometry_type not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns the Spatial Reference System ID for this geometric object.
      #
      # === Notes
      #
      # Returns an integer.
      #
      # This will normally be a foreign key to an index of reference systems
      # stored in either the same or some other datastore.

      def srid
        raise Error::UnsupportedOperation, "Method #{self.class}#srid not defined."
      end

      # === SFS 1.1 Description
      #
      # The minimum bounding box for this Geometry, returned as a Geometry.
      # The polygon is defined by the corner points of the bounding box
      # [(MINX, MINY), (MAXX, MINY), (MAXX, MAXY), (MINX, MAXY), (MINX, MINY)].
      #
      # === Notes
      #
      # Returns an object that supports the Geometry interface.

      def envelope
        raise Error::UnsupportedOperation, "Method #{self.class}#envelope not defined."
      end

      # === SFS 1.1 Description
      #
      # Exports this geometric object to a specific Well-known Text
      # Representation of Geometry.
      #
      # === Notes
      #
      # Returns an ASCII string.

      def as_text
        raise Error::UnsupportedOperation, "Method #{self.class}#as_text not defined."
      end

      # === SFS 1.1 Description
      #
      # Exports this geometric object to a specific Well-known Binary
      # Representation of Geometry.
      #
      # === Notes
      #
      # Returns a binary string.

      def as_binary
        raise Error::UnsupportedOperation, "Method #{self.class}#as_binary not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this geometric object is the empty Geometry. If true,
      # then this geometric object represents the empty point set for the
      # coordinate space.
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.

      def empty?
        raise Error::UnsupportedOperation, "Method #{self.class}#empty? not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this geometric object has no anomalous geometric
      # points, such as self intersection or self tangency. The description
      # of each instantiable geometric class will include the specific
      # conditions that cause an instance of that class to be classified as
      # not simple.
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.

      def simple?
        raise Error::UnsupportedOperation, "Method #{self.class}#simple? not defined."
      end

      # === SFS 1.2 Description
      #
      # Returns 1 (TRUE) if this geometric object has z coordinate values.
      #
      # === Notes
      #
      # @return [Boolean]
      def is_3d?
        raise Error::UnsupportedOperation, "Method #{self.class}#is_3d? not defined."
      end

      # === SFS 1.2 Description
      #
      # Returns 1 (TRUE) if this geometric object has m coordinate values.
      #
      # === Notes
      #
      # @return [Boolean]
      def measured?
        raise Error::UnsupportedOperation, "Method #{self.class}#measured? not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns the closure of the combinatorial boundary of this geometric
      # object. Because the result of this function is a closure, and hence
      # topologically closed, the resulting boundary can be represented using
      # representational Geometry primitives.
      #
      # === Notes
      #
      # Returns an object that supports the Geometry interface.

      def boundary
        raise Error::UnsupportedOperation, "Method #{self.class}#boundary not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this geometric object is "spatially equal" to
      # another_geometry.
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of comparing objects
      # from different factories is undefined.

      def equals?(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#equals? not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this geometric object is "spatially disjoint" from
      # another_geometry.
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of comparing objects
      # from different factories is undefined.

      def disjoint?(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#disjoint? not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this geometric object "spatially intersects"
      # another_geometry.
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of comparing objects
      # from different factories is undefined.

      def intersects?(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#intersects? not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this geometric object "spatially touches"
      # another_geometry.
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of comparing objects
      # from different factories is undefined.

      def touches?(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#touches? not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this geometric object "spatially crosses"
      # another_geometry.
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of comparing objects
      # from different factories is undefined.

      def crosses?(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#crosses? not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this geometric object is "spatially within"
      # another_geometry.
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of comparing objects
      # from different factories is undefined.

      def within?(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#within? not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this geometric object "spatially contains"
      # another_geometry.
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of comparing objects
      # from different factories is undefined.

      def contains?(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#contains? not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this geometric object "spatially overlaps"
      # another_geometry.
      #
      # === Notes
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of comparing objects
      # from different factories is undefined.

      def overlaps?(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#overlaps? not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns true if this geometric object is spatially related to
      # another_geometry by testing for intersections between the interior,
      # boundary and exterior of the two geometric objects as specified by
      # the values in the intersection_pattern_matrix.
      #
      # === Notes
      #
      # The intersection_pattern_matrix is provided as a nine-character
      # string in row-major order, representing the dimensionalities of
      # the different intersections in the DE-9IM. Supported characters
      # include T, F, *, 0, 1, and 2.
      #
      # Returns a boolean value. Note that this is different from the SFS
      # specification, which stipulates an integer return value.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of comparing objects
      # from different factories is undefined.

      def relate?(_another_geometry, _intersection_pattern_matrix_)
        raise Error::UnsupportedOperation, "Method #{self.class}#relate not defined."
      end

      # === SFS 1.2 Description
      #
      # Returns a derived geometry collection value that matches the
      # specified m coordinate value.
      #
      # === Notes
      #
      # @param m_value [Float] value to find matches for
      # @return [RGeo::Feature::GeometryCollection]
      def locate_along
        raise Error::UnsupportedOperation, "Method #{self.class}#locate_along not defined."
      end

      # === SFS 1.2 Description
      #
      # Returns a derived geometry collection value
      # that matches the specified range of m coordinate values inclusively
      #
      # === Notes
      #
      # @param m_start [Float] lower bound of value range
      # @param m_end [Float] upper bound of value range
      # @return [RGeo::Feature::GeometryCollection]
      def locate_between
        raise Error::UnsupportedOperation, "Method #{self.class}#locate_between not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns the shortest distance between any two Points in the two
      # geometric objects as calculated in the spatial reference system of
      # this geometric object.
      #
      # === Notes
      #
      # Returns a floating-point scalar value.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of measuring the
      # distance between objects from different factories is undefined.

      def distance(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#distance not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns a geometric object that represents all Points whose distance
      # from this geometric object is less than or equal to distance.
      # Calculations are in the spatial reference system of this geometric
      # object.
      #
      # === Notes
      #
      # Returns an object that supports the Geometry interface.

      def buffer(_distance_)
        raise Error::UnsupportedOperation, "Method #{self.class}#buffer not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns a geometric object that represents the convex hull of this
      # geometric object.
      #
      # === Notes
      #
      # Returns an object that supports the Geometry interface.

      def convex_hull
        raise Error::UnsupportedOperation, "Method #{self.class}#convex_hull not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns a geometric object that represents the Point set
      # intersection of this geometric object with another_geometry.
      #
      # === Notes
      #
      # Returns an object that supports the Geometry interface.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of performing
      # operations on objects from different factories is undefined.

      def intersection(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#intersection not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns a geometric object that represents the Point set
      # union of this geometric object with another_geometry.
      #
      # === Notes
      #
      # Returns an object that supports the Geometry interface.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of performing
      # operations on objects from different factories is undefined.

      def union(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#union not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns a geometric object that represents the Point set
      # difference of this geometric object with another_geometry.
      #
      # === Notes
      #
      # Returns an object that supports the Geometry interface.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of performing
      # operations on objects from different factories is undefined.

      def difference(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#difference not defined."
      end

      # === SFS 1.1 Description
      #
      # Returns a geometric object that represents the Point set symmetric
      # difference of this geometric object with another_geometry.
      #
      # === Notes
      #
      # Returns an object that supports the Geometry interface.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of performing
      # operations on objects from different factories is undefined.

      def sym_difference(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#sym_difference not defined."
      end

      # Returns true if this geometric object is representationally
      # equivalent to the given object.
      #
      # Although implementations are free to attempt to handle
      # another_geometry values that do not share the same factory as
      # this geometry, strictly speaking, the result of comparing objects
      # from different factories is undefined.

      def rep_equals?(_another_geometry)
        raise Error::UnsupportedOperation, "Method #{self.class}#rep_equals? not defined."
      end

      # Unions a collection of Geometry or a single Geometry
      # (which may be a collection) together. By using this
      # special-purpose operation over a collection of geometries
      # it is possible to take advantage of various optimizations
      # to improve performance. Heterogeneous GeometryCollections
      # are fully supported.
      #
      # This is not a standard SFS method, but when it is available
      # in GEOS, it is a very performant way to union all the
      # geometries in a collection. GEOS version 3.3 or greater
      # is required. If the feature is not available, unary_union
      # returns nil.
      #
      def unary_union
        raise Error::UnsupportedOperation, "Method #{self.class}#unary_union not defined."
      end

      # This method should behave almost the same as the rep_equals?
      # method, with two key differences.
      #
      # First, the <tt>eql?</tt> method is required to handle rhs values
      # that are not geometry objects (returning false in such cases) in
      # order to fulfill the standard Ruby contract for the method,
      # whereas the rep_equals? method may assume that any rhs is a
      # geometry.
      #
      # Second, the <tt>eql?</tt> method should always be defined. That
      # is, it should never raise Error::UnsupportedOperation. In cases
      # where the underlying implementation cannot provide a
      # representational equivalence test, this method must fall back on
      # objective equivalence.

      def eql?(other)
        if other.is_a?(RGeo::Feature::Instance)
          begin
            rep_equals?(other)
          rescue Error::UnsupportedOperation
            equal?(other)
          end
        else
          false
        end
      end

      # This operator should behave almost the same as the equals? method,
      # with two key differences.
      #
      # First, the == operator is required to handle rhs values that are
      # not geometry objects (returning false in such cases) in order to
      # fulfill the standard Ruby contract for the == operator, whereas
      # the equals? method may assume that any rhs is a geometry.
      #
      # Second, the == operator should always be defined. That is, it
      # should never raise Error::UnsupportedOperation. In cases where
      # the underlying implementation cannot provide a spatial equivalence
      # test, the == operator must fall back on representational or
      # objective equivalence.

      def ==(other)
        if other.is_a?(RGeo::Feature::Instance)
          begin
            equals?(other)
          rescue Error::UnsupportedOperation
            eql?(other)
          end
        else
          false
        end
      end

      # If the given rhs is a geometry object, this operator must behave
      # the same as the difference method. The behavior for other rhs
      # types is not specified; an implementation may choose to provide
      # additional capabilities as appropriate.

      def -(other)
        difference(other)
      end

      # If the given rhs is a geometry object, this operator must behave
      # the same as the union method. The behavior for other rhs types
      # is not specified; an implementation may choose to provide
      # additional capabilities as appropriate.

      def +(other)
        union(other)
      end

      # If the given rhs is a geometry object, this operator must behave
      # the same as the intersection method. The behavior for other rhs
      # types is not specified; an implementation may choose to provide
      # additional capabilities as appropriate.

      def *(other)
        intersection(other)
      end

      # Convenience method to transform/project a geometry
      # to a different coordinate system from the geometry itself
      # instead of the cast method.
      #
      # @note: Not an OGC SFS method
      #
      # @param [RGeo::Feature::Factory] other_factory
      # @return [RGeo::Feature::Geometry]
      def transform(other_factory)
        Feature.cast(self, factory: other_factory, project: true)
      end
    end
  end
end
