# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Feature type management and casting
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # All geometry implementations MUST include this submodule.
    # This serves as a marker that may be used to test an object for
    # feature-ness.
    module Instance
    end

    # This module provides the API for geometry type objects. Technically
    # these objects are modules (such as RGeo::Feature::Point), but as
    # objects they respond to the methods documented here.
    #
    # For example, you may determine whether a feature object is a
    # point by calling:
    #
    #   RGeo::Feature::Point.check_type(object)
    #
    # A corresponding === operator is provided so you can use the type
    # modules in a case-when clause:
    #
    #   case object
    #   when RGeo::Feature::Point
    #     # do stuff here...
    #
    # However, a feature object may not actually include the point module
    # itself; hence, the following will *not* work:
    #
    #   object.is_a?(RGeo::Feature::Point)  # DON'T DO THIS-- DOES NOT WORK
    #
    # You may obtain the type of a feature object by calling its
    # geometry_type method. You may then use the methods in this module to
    # interrogate that type.
    #
    #   # supppose object is a Point
    #   type = object.geometry_type  # RGeo::Feature::Point
    #   type.type_name               # "Point"
    #   type.supertype               # RGeo::Feature::Geometry
    #
    # You may also use the presence of this module to determine whether
    # a particular object is a feature type:
    #
    #   RGeo::Feature::Type === object.geometry_type  # true
    module Type
      # Returns true if the given object is this type or a subtype
      # thereof, or if it is a feature object whose geometry_type is
      # this type or a subtype thereof.
      #
      # Note that feature objects need not actually include this module.
      # Therefore, the is_a? method will generally not work.

      def check_type(rhs)
        rhs = rhs.geometry_type if rhs.is_a?(Feature::Instance)
        rhs.is_a?(Type) && (rhs == self || rhs.include?(self))
      end
      alias === check_type

      # Returns true if this type is the same type or a subtype of the
      # given type.

      def subtype_of?(type)
        self == type || include?(type)
      end

      # Returns the supertype of this type. The supertype of Geometry
      # is nil.

      def supertype
        @supertype
      end

      # Iterates over the known immediate subtypes of this type.

      def each_immediate_subtype(&block)
        @subtypes&.each(&block)
      end

      # Returns the OpenGIS type name of this type. For example:
      #
      #   RGeo::Feature::Point.type_name  # "Point"

      def type_name
        name.sub("RGeo::Feature::", "")
      end
      alias to_s type_name

      def add_subtype(type) # :nodoc:
        (@subtypes ||= []) << type
      end

      def self.extended(type) # :nodoc:
        supertype = type.included_modules.find { |m| m.is_a?(self) }
        type.instance_variable_set(:@supertype, supertype)
        supertype&.add_subtype(type)
      end
    end

    class << self
      # Cast the given object according to the given parameters, if
      # possible, and return the resulting object. If the requested cast
      # is not possible, nil is returned.
      #
      # Parameters may be provided as a hash, or as separate arguments.
      # Hash keys are as follows:
      #
      # [<tt>:factory</tt>]
      #   Set the factory to the given factory. If this argument is not
      #   given, the original object's factory is kept.
      # [<tt>:type</tt>]
      #   Cast to the given type, which must be a module in the
      #   RGeo::Feature namespace. If this argument is not given, the
      #   result keeps the same type as the original.
      # [<tt>:project</tt>]
      #   If this is set to true, and both the original and new factories
      #   support proj4 projections, then the cast will also cause the
      #   coordinates to be transformed between those two projections.
      #   If set to false, the coordinates are not modified. Default is
      #   false.
      # [<tt>:keep_subtype</tt>]
      #   Value must be a boolean indicating whether to keep the subtype
      #   of the original. If set to false, casting to a particular type
      #   always casts strictly to that type, even if the old type is a
      #   subtype of the new type. If set to true, the cast retains the
      #   subtype in that case. For example, casting a LinearRing to a
      #   LineString will normally yield a LineString, even though
      #   LinearRing is already a more specific subtype. If you set this
      #   value to true, the casted object will remain a LinearRing.
      #   Default is false.
      # [<tt>:force_new</tt>]
      #   Always return a newly-created object, even if neither the type
      #   nor factory is modified. Normally, if this is set to false, and
      #   a cast is not set to modify either the factory or type, the
      #   original object itself is returned. Setting this flag to true
      #   causes cast to return a clone in that case. Default is false.
      #
      # You may also pass the new factory, the new type, and the flags
      # as separate arguments. In this case, the flag names must be
      # passed as symbols, and their effect is the same as setting their
      # values to true. You can even combine separate arguments and hash
      # arguments. For example, the following three calls are equivalent:
      #
      #  RGeo::Feature.cast(geom, :type => RGeo::Feature::Point, :project => true)
      #  RGeo::Feature.cast(geom, RGeo::Feature::Point, :project => true)
      #  RGeo::Feature.cast(geom, RGeo::Feature::Point, :project)
      #
      # RGeo provides a default casting algorithm. Individual feature
      # implementation factories may override this and customize the
      # casting behavior by defining the override_cast method. See
      # RGeo::Feature::Factory#override_cast for more details.

      def cast(obj, *params)
        # Interpret params
        factory = obj.factory
        type = obj.geometry_type
        opts = {}
        params.each do |param|
          case param
          when Factory::Instance
            opts[:factory] = param
          when Type
            opts[:type] = param
          when Symbol
            opts[param] = true
          when Hash
            opts.merge!(param)
          end
        end
        force_new = opts[:force_new]
        keep_subtype = opts[:keep_subtype]
        project = opts[:project]
        nfactory = opts.delete(:factory) || factory
        ntype = opts.delete(:type) || type

        # Let the factory override
        if nfactory.respond_to?(:override_cast)
          override = nfactory.override_cast(obj, ntype, opts)
          return override unless override == false
        end

        # Default algorithm
        ntype = type if keep_subtype && type.include?(ntype)
        if ntype == type
          # Types are the same
          if nfactory == factory
            force_new ? obj.dup : obj
          elsif type == Point
            z = factory.property(:has_z_coordinate) ? obj.z : nil
            coords = if project && (cs = factory.coord_sys) && (ncs = nfactory.coord_sys)
                       cs.transform_coords(ncs, obj.x, obj.y, z)
                     else
                       [obj.x, obj.y]
                     end
            coords << (z || 0.0) if nfactory.property(:has_z_coordinate) && coords.size < 3
            m = factory.property(:has_m_coordinate) ? obj.m : nil
            coords << (m || 0.0) if nfactory.property(:has_m_coordinate)
            nfactory.point(*coords)
          elsif type == Line
            nfactory.line(cast(obj.start_point, nfactory, opts), cast(obj.end_point, nfactory, opts))
          elsif type == LinearRing
            nfactory.linear_ring(obj.points.map { |p| cast(p, nfactory, opts) })
          elsif type == LineString
            nfactory.line_string(obj.points.map { |p| cast(p, nfactory, opts) })
          elsif type == Polygon
            nfactory.polygon(
              cast(obj.exterior_ring, nfactory, opts),
              obj.interior_rings.map { |r| cast(r, nfactory, opts) }
            )
          elsif type == MultiPoint
            nfactory.multi_point(obj.map { |g| cast(g, nfactory, opts) })
          elsif type == MultiLineString
            nfactory.multi_line_string(obj.map { |g| cast(g, nfactory, opts) })
          elsif type == MultiPolygon
            nfactory.multi_polygon(obj.map { |g| cast(g, nfactory, opts) })
          elsif type == GeometryCollection
            nfactory.collection(obj.map { |g| cast(g, nfactory, opts) })
          end
        # Types are different
        elsif ntype == Point && [MultiPoint, GeometryCollection].include?(type) ||
            [Line, LineString, LinearRing].include?(ntype) && [MultiLineString, GeometryCollection].include?(type) ||
            ntype == Polygon && [MultiPolygon, GeometryCollection].include?(type)
          cast(obj.geometry_n(0), nfactory, ntype, opts) if obj.num_geometries == 1
        elsif ntype == Point
          raise(Error::InvalidGeometry, "Cannot cast to Point")
        elsif ntype == Line
          if type == LineString && obj.num_points == 2
            nfactory.line(cast(obj.point_n(0), nfactory, opts), cast(obj.point_n(1), nfactory, opts))
          end
        elsif ntype == LinearRing
          nfactory.linear_ring(obj.points.map { |p| cast(p, nfactory, opts) }) if type == LineString
        elsif ntype == LineString
          nfactory.line_string(obj.points.map { |p| cast(p, nfactory, opts) }) if [Line, LinearRing].include?(type)
        elsif ntype == MultiPoint
          if type == Point
            nfactory.multi_point([cast(obj, nfactory, opts)])
          elsif type == GeometryCollection
            nfactory.multi_point(obj.map { |p| cast(p, nfactory, opts) })
          end
        elsif ntype == MultiLineString
          if [Line, LinearRing, LineString].include?(type)
            nfactory.multi_line_string([cast(obj, nfactory, opts)])
          elsif type == GeometryCollection
            nfactory.multi_line_string(obj.map { |p| cast(p, nfactory, opts) })
          end
        elsif ntype == MultiPolygon
          if type == Polygon
            nfactory.multi_polygon([cast(obj, nfactory, opts)])
          elsif type == GeometryCollection
            nfactory.multi_polygon(obj.map { |p| cast(p, nfactory, opts) })
          end
        elsif ntype == GeometryCollection
          if [MultiPoint, MultiLineString, MultiPolygon].include?(type)
            nfactory.collection(obj.map { |p| cast(p, nfactory, opts) })
          else
            nfactory.collection([cast(obj, nfactory, opts)])
          end
        else
          raise(RGeo::Error::InvalidGeometry, "Undefined type cast from #{type.name} to #{ntype.name}")
        end
      end
    end
  end
end
