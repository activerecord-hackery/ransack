module Ransack
  module Nodes
    class Value < Node
      attr_reader :value_before_cast, :type
      delegate :blank?, :to => :value_before_cast

      def initialize(context, value = nil, type = nil)
        super(context)
        @value_before_cast = value
        self.type = type if type
      end

      def value=(val)
        @value_before_cast = value
        @value = nil
      end

      def value
        @value ||= cast_to_type(@value_before_cast, @type)
      end

      def persisted?
        false
      end

      def eql?(other)
        self.class == other.class &&
        self.value_before_cast == other.value_before_cast
      end
      alias :== :eql?

      def hash
        value_before_cast.hash
      end

      def type=(type)
        @value = nil
        @type = type
      end

      def cast_to_type(val, type)
        case type
        when :date
          cast_to_date(val)
        when :datetime, :timestamp, :time
          cast_to_time(val)
        when :boolean
          cast_to_boolean(val)
        when :integer
          cast_to_integer(val)
        when :float
          cast_to_float(val)
        when :decimal
          cast_to_decimal(val)
        else
          cast_to_string(val)
        end
      end

      def cast_to_date(val)
        if val.respond_to?(:to_date)
          val.to_date rescue nil
        else
          y, m, d = *[val].flatten
          m ||= 1
          d ||= 1
          Date.new(y,m,d) rescue nil
        end
      end

      # FIXME: doesn't seem to be casting, even with Time.zone.local
      def cast_to_time(val)
        if val.is_a?(Array)
          Time.zone.local(*val) rescue nil
        else
          unless val.acts_like?(:time)
            val = val.is_a?(String) ? Time.zone.parse(val) : val.to_time rescue val
          end
          val.in_time_zone
        end
      end

      def cast_to_boolean(val)
        if val.is_a?(String) && val.blank?
          nil
        else
          Constants::TRUE_VALUES.include?(val)
        end
      end

      def cast_to_string(val)
        val.respond_to?(:to_s) ? val.to_s : String.new(val)
      end

      def cast_to_integer(val)
        val.blank? ? nil : val.to_i
      end

      def cast_to_float(val)
        val.blank? ? nil : val.to_f
      end

      def cast_to_decimal(val)
        if val.blank?
          nil
        elsif val.class == BigDecimal
          val
        elsif val.respond_to?(:to_d)
          val.to_d
        else
          val.to_s.to_d
        end
      end

      def array_of_arrays?(val)
        Array === val && Array === val.first
      end
    end
  end
end