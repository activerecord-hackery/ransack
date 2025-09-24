# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Well-known binary parser for RGeo
#
# -----------------------------------------------------------------------------

module RGeo
  module WKRep
    # This class provides the functionality of parsing a geometry from
    # WKB (well-known binary) format. You may also customize the parser
    # to recognize PostGIS EWKB extensions to the input, or Simple
    # Features Specification 1.2 extensions for Z and M coordinates.
    #
    # To use this class, create an instance with the desired settings and
    # customizations, and call the parse method.
    #
    # === Configuration options
    #
    # You must provide each parser with an RGeo::Feature::FactoryGenerator.
    # It should understand the configuration options <tt>:srid</tt>,
    # <tt>:has_z_coordinate</tt>, and <tt>:has_m_coordinate</tt>.
    # You may also pass a specific RGeo::Feature::Factory, or nil to
    # specify the default Cartesian FactoryGenerator.
    #
    # The following additional options are recognized. These can be passed
    # to the constructor, or set on the object afterwards.
    #
    # [<tt>:support_ewkb</tt>]
    #   Activate support for PostGIS EWKB type codes, which use high
    #   order bits in the type code to signal the presence of Z, M, and
    #   SRID values in the data. Default is false.
    # [<tt>:support_wkb12</tt>]
    #   Activate support for SFS 1.2 extensions to the type codes, which
    #   use values greater than 1000 to signal the presence of Z and M
    #   values in the data. SFS 1.2 types such as triangle, tin, and
    #   polyhedralsurface are NOT yet supported. Default is false.
    # [<tt>:ignore_extra_bytes</tt>]
    #   If true, extra bytes at the end of the data are ignored. If
    #   false (the default), extra bytes will trigger a parse error.
    # [<tt>:default_srid</tt>]
    #   A SRID to pass to the factory generator if no SRID is present in
    #   the input. Defaults to nil (i.e. don't specify a SRID).
    class WKBParser
      # Create and configure a WKB parser. See the WKBParser
      # documentation for the options that can be passed.

      def initialize(factory_generator = nil, opts = {})
        if factory_generator.is_a?(Feature::Factory::Instance)
          @factory_generator = Feature::FactoryGenerator.single(factory_generator)
          @exact_factory = factory_generator
        elsif factory_generator.respond_to?(:call)
          @factory_generator = factory_generator
          @exact_factory = nil
        else
          @factory_generator = Cartesian.method(:preferred_factory)
          @exact_factory = nil
        end
        @support_ewkb = opts[:support_ewkb] ? true : false
        @support_wkb12 = opts[:support_wkb12] ? true : false
        @ignore_extra_bytes = opts[:ignore_extra_bytes] ? true : false
        @default_srid = opts[:default_srid]
        @mutex = Mutex.new
      end

      # Returns the factory generator. See WKBParser for details.
      attr_reader :factory_generator

      # If this parser was given an exact factory, returns it; otherwise
      # returns nil.
      attr_reader :exact_factory

      # Returns true if this parser supports EWKB.
      # See WKBParser for details.
      def support_ewkb?
        @support_ewkb
      end

      # Returns true if this parser supports SFS 1.2 extensions.
      # See WKBParser for details.
      def support_wkb12?
        @support_wkb12
      end

      # Returns true if this parser ignores extra bytes.
      # See WKBParser for details.
      def ignore_extra_bytes?
        @ignore_extra_bytes
      end

      def properties
        {
          "support_ewkb" => @support_ewkb,
          "support_wkb12" => @support_wkb12,
          "ignore_extra_bytes" => @ignore_extra_bytes,
          "default_srid" => @default_srid
        }
      end

      # Parse the given binary data or hexadecimal string, and return a
      # geometry object.
      #
      # The #parse_hex method is a synonym, present for historical
      # reasons but deprecated. Use #parse instead.

      def parse(data)
        @mutex.synchronize do
          data = [data].pack("H*") if data[0, 1] =~ /[0-9a-fA-F]/
          @cur_has_z = nil
          @cur_has_m = nil
          @cur_srid = nil
          @cur_dims = 2
          @cur_factory = nil
          begin
            start_scanner(data)
            obj = parse_object(false)
            unless @ignore_extra_bytes
              bytes = bytes_remaining
              raise Error::ParseError, "Found #{bytes} extra bytes at the end of the stream." if bytes > 0
            end
          ensure
            @data = nil
          end
          obj
        end
      end
      alias parse_hex parse

      private

      def parse_object(contained)
        endian_value = byte
        case endian_value
        when 0
          little_endian = false
        when 1
          little_endian = true
        else
          raise Error::ParseError, "Bad endian byte value: #{endian_value}"
        end
        type_code = get_integer(little_endian)
        has_z = false
        has_m = false
        srid = contained ? nil : @default_srid
        if @support_ewkb
          has_z ||= type_code & 0x80000000 != 0
          has_m ||= type_code & 0x40000000 != 0
          srid = get_integer(little_endian) if type_code & 0x20000000 != 0
          type_code &= 0x0fffffff
        end
        if @support_wkb12
          has_z ||= (type_code / 1000) & 1 != 0
          has_m ||= (type_code / 1000) & 2 != 0
          type_code %= 1000
        end
        if contained
          if contained != true && contained != type_code
            raise Error::ParseError, "Enclosed type=#{type_code} is different from container constraint #{contained}"
          end

          if has_z != @cur_has_z
            raise Error::ParseError, "Enclosed hasZ=#{has_z} is different from toplevel hasZ=#{@cur_has_z}"
          end

          if has_m != @cur_has_m
            raise Error::ParseError, "Enclosed hasM=#{has_m} is different from toplevel hasM=#{@cur_has_m}"
          end

          if srid && srid != @cur_srid
            raise(
              Error::ParseError,
              "Enclosed SRID #{srid} is different from toplevel srid #{@cur_srid || '(unspecified)'}"
            )
          end
        else
          @cur_has_z = has_z
          @cur_has_m = has_m
          @cur_dims = 2 + (@cur_has_z ? 1 : 0) + (@cur_has_m ? 1 : 0)
          @cur_srid = srid
          @cur_factory = @factory_generator.call(srid: @cur_srid, has_z_coordinate: has_z, has_m_coordinate: has_m)

          if @cur_has_z && !@cur_factory.property(:has_z_coordinate)
            raise Error::ParseError, "Data has Z coordinates but the factory doesn't have Z coordinates"
          end

          if @cur_has_m && !@cur_factory.property(:has_m_coordinate)
            raise Error::ParseError, "Data has M coordinates but the factory doesn't have M coordinates"
          end
        end
        case type_code
        when 1
          coords = get_doubles(little_endian, @cur_dims)
          @cur_factory.point(*coords)
        when 2
          parse_line_string(little_endian)
        when 3
          interior_rings = (1..get_integer(little_endian)).map { parse_line_string(little_endian) }
          exterior_ring = interior_rings.shift || @cur_factory.linear_ring([])
          @cur_factory.polygon(exterior_ring, interior_rings)
        when 4
          @cur_factory.multi_point((1..get_integer(little_endian)).map { parse_object(1) })
        when 5
          @cur_factory.multi_line_string((1..get_integer(little_endian)).map { parse_object(2) })
        when 6
          @cur_factory.multi_polygon((1..get_integer(little_endian)).map { parse_object(3) })
        when 7
          @cur_factory.collection((1..get_integer(little_endian)).map { parse_object(true) })
        else
          raise Error::ParseError, "Unknown type value: #{type_code}."
        end
      end

      def parse_line_string(little_endian)
        count = get_integer(little_endian)
        coords = get_doubles(little_endian, @cur_dims * count)
        @cur_factory.line_string((0...count).map { |i| @cur_factory.point(*coords[@cur_dims * i, @cur_dims]) })
      end

      def start_scanner(data)
        @data = data
        @len = data.length
        @pos = 0
      end

      def bytes_remaining
        @len - @pos
      end

      def byte
        raise Error::ParseError, "Not enough bytes left to fulfill 1 byte" if @pos + 1 > @len
        str = @data[@pos, 1]
        @pos += 1
        str.unpack1("C")
      end

      def get_integer(little_endian)
        raise Error::ParseError, "Not enough bytes left to fulfill 1 integer" if @pos + 4 > @len
        str = @data[@pos, 4]
        @pos += 4
        str.unpack1(little_endian ? "V" : "N")
      end

      def get_doubles(little_endian, count)
        len = 8 * count
        raise Error::ParseError, "Not enough bytes left to fulfill #{count} doubles" if @pos + len > @len
        str = @data[@pos, len]
        @pos += len
        str.unpack("#{little_endian ? 'E' : 'G'}*")
      end
    end
  end
end
