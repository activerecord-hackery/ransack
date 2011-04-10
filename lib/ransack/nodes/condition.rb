module Ransack
  module Nodes
    class Condition < Node
      i18n_word :attribute, :predicate, :combinator, :value
      i18n_alias :a => :attribute, :p => :predicate, :m => :combinator, :v => :value

      attr_reader :predicate

      class << self
        def extract(context, key, values)
          attributes, predicate = extract_attributes_and_predicate(key)
          if attributes.size > 0
            combinator = key.match(/_(or|and)_/) ? $1 : nil
            condition = self.new(context)
            condition.build(
              :a => attributes,
              :p => predicate.name,
              :m => combinator,
              :v => [values]
            )
            predicate.validate(condition.values) ? condition : nil
          end
        end

        private

        def extract_attributes_and_predicate(key)
          str = key.dup
          name = Ransack::Configuration.predicate_keys.detect {|p| str.sub!(/_#{p}$/, '')}
          predicate = Predicate.named(name)
          raise ArgumentError, "No valid predicate for #{key}" unless predicate
          attributes = str.split(/_and_|_or_/)
          [attributes, predicate]
        end
      end

      def valid?
        attributes.detect(&:valid?) && predicate && valid_arity? && predicate.validate(values) && valid_combinator?
      end

      def valid_arity?
        values.size <= 1 || predicate.compound || %w(in not_in).include?(predicate.name)
      end

      def attributes
        @attributes ||= []
      end
      alias :a :attributes

      def attributes=(args)
        case args
        when Array
          args.each do |attr|
            attr = Attribute.new(@context, attr)
            self.attributes << attr if attr.valid?
          end
        when Hash
          args.each do |index, attrs|
            attr = Attribute.new(@context, attrs[:name])
            self.attributes << attr if attr.valid?
          end
        else
          raise ArgumentError, "Invalid argument (#{args.class}) supplied to attributes="
        end
      end
      alias :a= :attributes=

      def values
        @values ||= []
      end
      alias :v :values

      def values=(args)
        case args
        when Array
          args.each do |val|
            val = Value.new(@context, val, current_type)
            self.values << val
          end
        when Hash
          args.each do |index, attrs|
            val = Value.new(@context, attrs[:value], current_type)
            self.values << val
          end
        else
          raise ArgumentError, "Invalid argument (#{args.class}) supplied to values="
        end
      end
      alias :v= :values=

      def combinator
        @attributes.size > 1 ? @combinator : nil
      end

      def combinator=(val)
        @combinator = ['and', 'or'].detect {|v| v == val.to_s} || nil
      end
      alias :m= :combinator=
      alias :m :combinator

      def build_attribute(name = nil)
        Attribute.new(@context, name).tap do |attribute|
          self.attributes << attribute
        end
      end

      def build_value(val = nil)
        Value.new(@context, val, current_type).tap do |value|
          self.values << value
        end
      end

      def value
        predicate.compound ? values.map(&:value) : values.first.value
      end

      def build(params)
        params.with_indifferent_access.each do |key, value|
          if key.match(/^(a|v|p|m)$/)
            self.send("#{key}=", value)
          end
        end

        set_value_types!

        self
      end

      def persisted?
        false
      end

      def key
        @key ||= attributes.map(&:name).join("_#{combinator}_") + "_#{predicate.name}"
      end

      def eql?(other)
        self.class == other.class &&
        self.attributes == other.attributes &&
        self.predicate == other.predicate &&
        self.values == other.values &&
        self.combinator == other.combinator
      end
      alias :== :eql?

      def hash
        [attributes, predicate, values, combinator].hash
      end

      def predicate_name=(name)
        self.predicate = Predicate.named(name)
      end
      alias :p= :predicate_name=

      def predicate=(predicate)
        @predicate = predicate
        predicate
      end

      def predicate_name
        predicate.name if predicate
      end
      alias :p :predicate_name

      def apply_predicate
        attributes = arel_attributes.compact

        if attributes.size > 1
          case combinator
          when 'and'
            Arel::Nodes::Grouping.new(Arel::Nodes::And.new(
              attributes.map {|a| a.send(predicate.arel_predicate, predicate.format(values))}
            ))
          when 'or'
            attributes.inject(attributes.shift.send(predicate.arel_predicate, predicate.format(values))) do |memo, a|
              memo.or(a.send(predicate.arel_predicate, predicate.format(values)))
            end
          end
        else
          attributes.first.send(predicate.arel_predicate, predicate.format(values))
        end
      end

      private

      def set_value_types!
        self.values.each {|v| v.type = current_type}
      end

      def current_type
        if predicate && predicate.type
          predicate.type
        elsif attributes.size > 0
          attributes.first.type
        end
      end

      def valid_combinator?
        attributes.size < 2 ||
        ['and', 'or'].include?(combinator)
      end

      def arel_attributes
        attributes.map(&:attr)
      end

    end
  end
end