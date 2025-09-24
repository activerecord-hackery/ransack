# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Feature factory interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # This is a standard interface for factories of features.
    # Generally, each Feature implementation will implement these
    # methods as a standard way to create features.
    #
    # If the implementation is unable to create the given feature,
    # it should generally return nil. Implementations may also choose to
    # raise an exception on failure.
    #
    # Some implementations may extend this interface to provide facilities
    # for creating additional objects according to the capabilities
    # provided by that implementation. Examples might include
    # higher-dimensional coordinates or additional subclasses not
    # explicitly required by the Simple Features Specification.
    #
    # Factory is defined as a module and is provided primarily for the
    # sake of documentation. Implementations need not necessarily include
    # this module itself. Therefore, you should not depend on the result
    # of <tt>is_a?(Factory)</tt> to check type. However, to support
    # testing for factory-ness, the <tt>Factory::Instance</tt> submodule
    # is provided. All factory implementation classes MUST include
    # <tt>Factory::Instance</tt>, and you may use it in <tt>is_a?</tt>,
    # <tt>===</tt>, and case-when constructs.
    module Factory
      # All factory implementations MUST include this submodule.
      # This serves as a marker that may be used to test an object for
      # factory-ness.
      module Instance
      end

      # Returns meta-information about this factory, by key. This
      # information may involve support for optional functionality,
      # properties of the coordinate system, or other characteristics.
      #
      # Each property has a symbolic name. Names that have no periods are
      # considered well-known names and are reserved for use by RGeo. If
      # you want to define your own properties, use a name that is
      # namespaced with periods, such as <tt>:'mycompany.myprop'</tt>.
      #
      # Property values are dependent on the individual property.
      # Generally, properties that involve testing for functionality
      # should return true if the functionality is support, or false or
      # nil if not. A property value could also invlove different values
      # indicating different levels of support. In any case, the factory
      # should return nil for property names it does not recognize. This
      # value is considered the "default" or "no value" value.
      #
      # Currently defined well-known properties are:
      #
      # [<tt>:has_z_coordinate</tt>]
      #   Set to true if geometries created by this factory include a Z
      #   coordinate, and the Point#z method is available.
      # [<tt>:has_m_coordinate</tt>]
      #   Set to true if geometries created by this factory include a M
      #   coordinate, and the Point#m method is available.
      # [<tt>:is_cartesian</tt>]
      #   Set to true if this Factory guarantees that it operates in
      #   Cartesian geometry. If false or nil, no such guarantee is made,
      #   though it is possible the geometries may still be Cartesian.
      # [<tt>:is_geographic</tt>]
      #   Set to true if this Factory's coordinate system is meant to be
      #   interpreted as x=longitude and y=latitude. If false or nil, no
      #   information is present about whether the coordinate system is
      #   meant to be so interpreted.

      def property(_name)
        raise Error::UnsupportedOperation, "Method #{self.class}##{__method__} not defined."
      end

      # Parse the given string in well-known-text format and return the
      # resulting feature. Returns nil if the string couldn't be parsed.

      def parse_wkt(_str)
        raise Error::UnsupportedOperation, "Method #{self.class}##{__method__} not defined."
      end

      # Parse the given string in well-known-binary format and return the
      # resulting feature. Returns nil if the string couldn't be parsed.

      def parse_wkb(_str)
        raise Error::UnsupportedOperation, "Method #{self.class}##{__method__} not defined."
      end

      # Create a feature of type Point.
      # The x and y parameters should be Float values.
      #
      # The extra parameters should be the Z and/or M coordinates, if
      # supported. If both Z and M coordinates are supported, Z should
      # be passed first.

      def point(_x, _y, *_extra)
        raise Error::UnsupportedOperation, "Method #{self.class}##{__method__} not defined."
      end

      # Create a feature of type LineString.
      # The given points argument should be an Enumerable of Point
      # objects, or objects that can be cast to Point.
      #
      # Although implementations are free to attempt to handle input
      # objects that are not of this factory, strictly speaking, the
      # result of building geometries from objects of the wrong factory
      # is undefined.

      def line_string(_points)
        raise Error::UnsupportedOperation, "Method #{self.class}##{__method__} not defined."
      end

      # Create a feature of type Line.
      # The given point arguments should be Point objects, or objects
      # that can be cast to Point.
      #
      # Although implementations are free to attempt to handle input
      # objects that are not of this factory, strictly speaking, the
      # result of building geometries from objects of the wrong factory
      # is undefined.

      def line(_start, _stop)
        raise Error::UnsupportedOperation, "Method #{self.class}##{__method__} not defined."
      end

      # Create a feature of type LinearRing.
      # The given points argument should be an Enumerable of Point
      # objects, or objects that can be cast to Point.
      # If the first and last points are not equal, the ring is
      # automatically closed by appending the first point to the end of the
      # string.
      #
      # Although implementations are free to attempt to handle input
      # objects that are not of this factory, strictly speaking, the
      # result of building geometries from objects of the wrong factory
      # is undefined.

      def linear_ring(_points)
        raise Error::UnsupportedOperation, "Method #{self.class}##{__method__} not defined."
      end

      # Create a feature of type Polygon.
      # The outer_ring should be a LinearRing, or an object that can be
      # cast to LinearRing.
      # The inner_rings should be a possibly empty Enumerable of
      # LinearRing (or objects that can be casted to LinearRing).
      # You may also pass nil to indicate no inner rings.
      #
      # Although implementations are free to attempt to handle input
      # objects that are not of this factory, strictly speaking, the
      # result of building geometries from objects of the wrong factory
      # is undefined.

      def polygon(_outer_ring, _inner_rings = nil)
        raise Error::UnsupportedOperation, "Method #{self.class}##{__method__} not defined."
      end

      # Create a feature of type GeometryCollection.
      # The elems should be an Enumerable of Geometry objects.
      #
      # Although implementations are free to attempt to handle input
      # objects that are not of this factory, strictly speaking, the
      # result of building geometries from objects of the wrong factory
      # is undefined.

      def collection(_elems)
        raise Error::UnsupportedOperation, "Method #{self.class}##{__method__} not defined."
      end

      # Create a feature of type MultiPoint.
      # The elems should be an Enumerable of Point objects, or objects
      # that can be cast to Point.
      # Returns nil if any of the contained geometries is not a Point,
      # which would break the MultiPoint contract.
      #
      # Although implementations are free to attempt to handle input
      # objects that are not of this factory, strictly speaking, the
      # result of building geometries from objects of the wrong factory
      # is undefined.

      def multi_point(_elems)
        raise Error::UnsupportedOperation, "Method #{self.class}##{__method__} not defined."
      end

      # Create a feature of type MultiLineString.
      # The elems should be an Enumerable of objects that are or can be
      # cast to LineString or any of its subclasses.
      # Returns nil if any of the contained geometries is not a
      # LineString, which would break the MultiLineString contract.
      #
      # Although implementations are free to attempt to handle input
      # objects that are not of this factory, strictly speaking, the
      # result of building geometries from objects of the wrong factory
      # is undefined.

      def multi_line_string(_elems)
        raise Error::UnsupportedOperation, "Method #{self.class}##{__method__} not defined."
      end

      # Create a feature of type MultiPolygon.
      # The elems should be an Enumerable of objects that are or can be
      # cast to Polygon or any of its subclasses.
      # Returns nil if any of the contained geometries is not a Polygon,
      # which would break the MultiPolygon contract.
      # Also returns nil if any of the other assertions for MultiPolygon
      # are not met, e.g. if any of the polygons overlap.
      #
      # Although implementations are free to attempt to handle input
      # objects that are not of this factory, strictly speaking, the
      # result of building geometries from objects of the wrong factory
      # is undefined.

      def multi_polygon(_elems)
        raise Error::UnsupportedOperation, "Method #{self.class}##{__method__} not defined."
      end

      # Returns the coordinate system specification for the features
      # created by this factory, or nil if there is no such coordinate
      # system.
      #
      # NOTE: This is a required method of the factory interface, but the
      # coordinate system classes themselves are not yet available, so
      # implementations should just return nil for now.

      def coord_sys
        nil
      end

      # This is an optional method that may be implemented to customize
      # casting for this factory. Basically, RGeo defines standard ways
      # to cast certain types of objects from one factory to another and
      # one SFS type to another. However, a factory may choose to
      # override how things are casted TO its implementation using this
      # method. It can do this to optimize certain casting cases, or
      # implement special cases particular to this factory.
      #
      # This method will be called (if defined) on the destination
      # factory, and will be passed the original object (which may or may
      # not already be created by this factory), the SFS feature type
      # (which again may or may not already be the type of the original
      # object), and a hash of additional flags. These flags are:
      #
      # [<tt>:keep_subtype</tt>]
      #   indicates whether to keep the subtype if casting to a supertype
      #   of the current type
      # [<tt>:force_new</tt>]
      #   indicates whether to force the creation of a new object even if
      #   the original is already of the desired factory and type
      # [<tt>:project</tt>]
      #   indicates whether to project the coordinates from the source to
      #   the destination coordinate system, if available
      #
      # It should return either a casted result object, false, or nil.
      # A nil return value indicates that casting should be forced to
      # fail (and RGeo::Feature.cast will return nil).
      # A false return value indicates that this method declines to
      # override the casting algorithm, and RGeo should use its default
      # algorithm to cast the object. Therefore, by default, you should
      # return false.

      def override_cast(_original, _type, _flags)
        false
      end
    end
  end
end
