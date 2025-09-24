# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# OGC CS wkt parser for RGeo
#
# -----------------------------------------------------------------------------

module RGeo
  module CoordSys
    module CS
      class WKTParser # :nodoc:
        def initialize(str)
          @scanner = StringScanner.new(str)
          next_token
        end

        def parse(containing_type = nil) # :nodoc:
          if @cur_token.is_a?(QuotedString) ||
            @cur_token.is_a?(Numeric) ||
            (containing_type == "AXIS" && @cur_token.is_a?(TypeString))
            value = @cur_token
            next_token
            return value
          end

          unless @cur_token.is_a?(TypeString)
            raise Error::ParseError, "Found token #{@cur_token} when we expected a value"
          end

          type = @cur_token
          next_token
          consume_tokentype(:begin)
          args = ArgumentList.new
          args << parse(type)
          loop do
            break unless @cur_token == :comma
            next_token
            args << parse(type)
          end
          consume_tokentype(:end)
          obj = nil
          case type
          when "AUTHORITY"
            obj = AuthorityClause.new(args.shift(QuotedString), args.shift(QuotedString))
          when "EXTENSION"
            obj = ExtensionClause.new(args.shift(QuotedString), args.shift(QuotedString))
          when "AXIS"
            obj = AxisInfo.create(args.shift(QuotedString), args.shift(TypeString))
          when "TOWGS84"
            bursa_wolf_params = args.find_all(Numeric)

            unless bursa_wolf_params.size == 7
              raise Error::ParseError, "Expected 7 Bursa Wolf parameters but found #{bursa_wolf_params.size}"
            end

            obj = WGS84ConversionInfo.create(*bursa_wolf_params)
          when "UNIT"
            klass = case containing_type
                    when "GEOCCS", "VERT_CS", "PROJCS", "SPHEROID"
                      LinearUnit
                    when "GEOGCS"
                      AngularUnit
                    else
                      Unit
                    end
            obj = klass.create(args.shift(QuotedString), args.shift(Numeric), *args.create_optionals)
          when "PARAMETER"
            obj = ProjectionParameter.create(args.shift(QuotedString), args.shift(Numeric))
          when "PRIMEM"
            obj = PrimeMeridian.create(args.shift(QuotedString), nil, args.shift(Numeric), *args.create_optionals)
          when "SPHEROID"
            obj = Ellipsoid.create_flattened_sphere(
              args.shift(QuotedString),
              args.shift(Numeric),
              args.shift(Numeric),
              args.find_first(LinearUnit),
              *args.create_optionals
            )
          when "PROJECTION"
            name = args.shift(QuotedString)
            obj = Projection.create(name, name, args.find_all(ProjectionParameter), *args.create_optionals)
          when "DATUM"
            name = args.shift(QuotedString)
            ellipsoid = args.find_first(Ellipsoid)
            to_wgs84 = args.find_first(WGS84ConversionInfo)
            obj = HorizontalDatum.create(name, HD_GEOCENTRIC, ellipsoid, to_wgs84, *args.create_optionals)
          when "VERT_DATUM"
            obj = VerticalDatum.create(args.shift(QuotedString), args.shift(Numeric), *args.create_optionals)
          when "LOCAL_DATUM"
            obj = LocalDatum.create(args.shift(QuotedString), args.shift(Numeric), *args.create_optionals)
          when "CS"
            # Not actually valid WKT, but necessary to load and dump factories
            # with placeholder coord_sys objects
            defn = args.shift(QuotedString)
            dim = args.shift(Float).to_i
            optionals = args.create_optionals
            obj = CoordinateSystem.create(defn, dim, *optionals)
          when "COMPD_CS"
            obj = CompoundCoordinateSystem.create(
              args.shift(QuotedString),
              args.shift(CoordinateSystem),
              args.shift(CoordinateSystem),
              *args.create_optionals
            )
          when "LOCAL_CS"
            name = args.shift(QuotedString)
            local_datum = args.find_first(LocalDatum)
            unit = args.find_first(Unit)
            axes = args.find_all(AxisInfo)
            raise Error::ParseError, "Expected at least one AXIS in a LOCAL_CS" unless axes.size > 0
            obj = LocalCoordinateSystem.create(name, local_datum, unit, axes, *args.create_optionals)
          when "GEOCCS"
            name = args.shift(QuotedString)
            horizontal_datum = args.find_first(HorizontalDatum)
            prime_meridian = args.find_first(PrimeMeridian)
            linear_unit = args.find_first(LinearUnit)
            axes = args.find_all(AxisInfo)

            unless axes.size == 0 || axes.size == 3
              raise Error::ParseError, "GEOCCS must contain either 0 or 3 AXIS parameters"
            end

            obj = GeocentricCoordinateSystem.create(
              name,
              horizontal_datum,
              prime_meridian,
              linear_unit,
              axes[0],
              axes[1],
              axes[2],
              *args.create_optionals
            )
          when "VERT_CS"
            name = args.shift(QuotedString)
            vertical_datum = args.find_first(VerticalDatum)
            linear_unit = args.find_first(LinearUnit)
            axis = args.find_first(AxisInfo)
            obj = VerticalCoordinateSystem.create(name, vertical_datum, linear_unit, axis, *args.create_optionals)
          when "GEOGCS"
            name = args.shift(QuotedString)
            horizontal_datum = args.find_first(HorizontalDatum)
            prime_meridian = args.find_first(PrimeMeridian)
            angular_unit = args.find_first(AngularUnit)
            axes = args.find_all(AxisInfo)

            unless axes.size == 0 || axes.size == 2
              raise Error::ParseError, "GEOGCS must contain either 0 or 2 AXIS parameters"
            end

            obj = GeographicCoordinateSystem.create(
              name,
              angular_unit,
              horizontal_datum,
              prime_meridian,
              axes[0],
              axes[1],
              *args.create_optionals
            )
          when "PROJCS"
            name = args.shift(QuotedString)
            geographic_coordinate_system = args.find_first(GeographicCoordinateSystem)
            projection = args.find_first(Projection)
            parameters = args.find_all(ProjectionParameter)
            projection.instance_variable_get(:@parameters).concat(parameters)
            linear_unit = args.find_first(LinearUnit)
            axes = args.find_all(AxisInfo)

            unless axes.size == 0 || axes.size == 2
              raise Error::ParseError, "PROJCS must contain either 0 or 2 AXIS parameters"
            end

            obj = ProjectedCoordinateSystem.create(
              name,
              geographic_coordinate_system,
              projection,
              linear_unit,
              axes[0],
              axes[1],
              *args.create_optionals
            )
          else
            raise Error::ParseError, "Unrecognized type: #{type}"
          end
          args.assert_empty
          obj
        end

        def consume_tokentype(type) # :nodoc:
          expect_tokentype(type)
          tok = @cur_token
          next_token
          tok
        end

        def expect_tokentype(type) # :nodoc:
          return if type === @cur_token

          raise Error::ParseError, "#{type.inspect} expected but #{@cur_token.inspect} found."
        end

        def next_token # :nodoc:
          @scanner.skip(/\s+/)
          case @scanner.peek(1)
          when '"'
            @scanner.getch
            @cur_token = QuotedString.new(@scanner.scan(/[^"]*/))
            @scanner.getch
          when ","
            @scanner.getch
            @cur_token = :comma
          when "(", "["
            @scanner.getch
            @cur_token = :begin
          when "]", ")"
            @scanner.getch
            @cur_token = :end
          when /[a-zA-Z]/
            @cur_token = TypeString.new(@scanner.scan(/[a-zA-Z]\w*/))
          when "", nil
            @cur_token = nil
          else
            @scanner.scan_until(/[^\s()\[\],"]+/)
            token = @scanner.matched

            unless token =~ /^[-+]?(\d+(\.\d*)?|\.\d+)(e[-+]?\d+)?$/
              raise Error::ParseError, "Bad token: #{token.inspect}"
            end

            @cur_token = token.to_f
          end
          @cur_token
        end

        attr_reader :cur_token

        class QuotedString < String # :nodoc:
        end

        class TypeString < String # :nodoc:
        end

        class AuthorityClause # :nodoc:
          def initialize(name, code) # :nodoc:
            @name = name
            @code = code
          end

          def to_a # :nodoc:
            [@name, @code]
          end
        end

        class ExtensionClause # :nodoc:
          attr_reader :key, :value

          def initialize(key, value) # :nodoc:
            @key = key
            @value = value
          end
        end

        class ArgumentList # :nodoc:
          def initialize # :nodoc:
            @values = []
          end

          def <<(value) # :nodoc:
            @values << value
          end

          def assert_empty # :nodoc:
            return if @values.empty?

            names = @values.map do |val|
              val.is_a?(Base) ? val.wkt_typename : val.inspect
            end

            raise Error::ParseError, "#{@values.size} unexpected arguments: #{names.join(', ')}"
          end

          def find_first(klass) # :nodoc:
            @values.each_with_index do |val, index|
              if val.is_a?(klass)
                @values.slice!(index)
                return val
              end
            end
            nil
          end

          def find_all(klass) # :nodoc:
            results = []
            nvalues = []
            @values.each do |val|
              if val.is_a?(klass)
                results << val
              else
                nvalues << val
              end
            end
            @values = nvalues
            results
          end

          def create_optionals # :nodoc:
            hash = {}
            find_all(ExtensionClause).each { |ec| hash[ec.key] = ec.value }
            (find_first(AuthorityClause) || [nil, nil]).to_a + [nil, nil, nil, hash]
          end

          def shift(klass = nil) # :nodoc:
            val = @values.shift
            raise Error::ParseError, "No arguments left... expected #{klass}" unless val
            raise Error::ParseError, "Expected #{klass} but got #{val.class}" if klass && !val.is_a?(klass)
            val
          end
        end
      end
    end
  end
end
