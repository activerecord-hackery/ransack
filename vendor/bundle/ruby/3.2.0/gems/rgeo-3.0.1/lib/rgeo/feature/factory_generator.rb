# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Feature factory interface
#
# -----------------------------------------------------------------------------

module RGeo
  module Feature
    # A FactoryGenerator is a callable object (usually a Proc) that
    # takes a configuration as a hash and returns a factory. These are
    # often used, e.g., by parsers to determine what factory the parsed
    # geometry should have.
    #
    # See the call method for a list of common configuration parameters.
    # Different generators will support different parameters. There is
    # no mechanism defined to reflect on the parameters understood by a
    # factory generator.
    #
    # Many of the implementations provide a factory method for creating
    # factories. For example, RGeo::Cartesian.preferred_factory can be
    # called to create a factory using the preferred Cartesian
    # implementation. Thus, to get a corresponding factory generator,
    # you can use the <tt>method</tt> method. e.g.
    #
    #  factory_generator = RGeo::Cartesian.method(:preferred_factory)
    #
    # FactoryGenerator is defined as a module and is provided
    # primarily for the sake of documentation. Implementations need not
    # necessarily include this module itself. Therefore, you should not
    # depend on the kind_of? method to determine if an object is a
    # factory generator.
    module FactoryGenerator
      # Generate a factory given a configuration as a hash.
      #
      # If the generator does not recognize or does not support a given
      # configuration value, the behavior is usually determined by the
      # <tt>:strict</tt> configuration element. If <tt>strict</tt> is
      # set to true, the generator should fail fast by returning nil or
      # raising an exception. If it is set to false, the generator should
      # attempt to do the best it can, even if it means returning a
      # factory that does not match the requested configuration.
      #
      # Common parameters are as follows. These are intended as a
      # recommendation only. There is no hard requirement for any
      # particular factory generator to support them.
      #
      # [<tt>:strict</tt>]
      #   If true, return nil or raise an exception if any configuration
      #   was not recognized or not supportable. Otherwise, if false,
      #   the generator should attempt to do its best to return some
      #   viable factory, even if it does not strictly match the
      #   requested configuration. Default is usually false.
      # [<tt>:srid</tt>]
      #   The SRID for the factory and objects it creates.
      #   Default is usually 0.
      # [<tt>:coord_sys</tt>]
      #   The coordinate system in OGC form, either as a subclass of
      #   CoordSys::CS::CoordinateSystem, or as a string in WKT format.
      #   Optional. If no coord_sys is given, but an SRID is the factory
      #   will try to create one using the CoordSys::CONFIG.default_coord_sys_class
      #   or the given :coord_sys_class option. The option is usually nil.
      # [<tt>:has_z_coordinate</tt>]
      #   Support Z coordinates. Default is usually false.
      # [<tt>:has_m_coordinate</tt>]
      #   Support M coordinates. Default is usually false.

      def call(_config = {})
        nil
      end

      # Return a new FactoryGenerator that always returns the given
      # factory.

      def self.single(factory)
        proc { |_c| factory }
      end

      # Return a new FactoryGenerator that calls the given delegate, but
      # modifies the configuration passed to it. You can provide defaults
      # for configuration values not explicitly specified, and you can
      # force certain values to override the given configuration.

      def self.decorate(delegate, default_config = {}, force_config = {})
        proc { |c| delegate.call(default_config.merge(c).merge(force_config)) }
      end
    end
  end
end
