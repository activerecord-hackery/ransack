module Ransack
  module Nodes
    class Grouping < Node
      attr_reader :conditions
      i18n_word :condition, :and, :or
      i18n_alias :c => :condition, :n => :and, :o => :or

      delegate :each, :to => :values

      def persisted?
        false
      end

      def translate(key, options = {})
        super or Translate.attribute(key.to_s, options.merge(:context => context))
      end

      def conditions
        @conditions ||= []
      end
      alias :c :conditions

      def conditions=(conditions)
        case conditions
        when Array
          conditions.each do |attrs|
            condition = Condition.new(@context).build(attrs)
            self.conditions << condition if condition.valid?
          end
        when Hash
          conditions.each do |index, attrs|
            condition = Condition.new(@context).build(attrs)
            self.conditions << condition if condition.valid?
          end
        end

        self.conditions.uniq!
      end
      alias :c= :conditions=

      def [](key)
        if condition = conditions.detect {|c| c.key == key.to_s}
          condition
        else
          nil
        end
      end

      def []=(key, value)
        conditions.reject! {|c| c.key == key.to_s}
        self.conditions << value
      end

      def values
        conditions + ors + ands
      end

      def respond_to?(method_id)
        super or begin
          method_name = method_id.to_s
          writer = method_name.sub!(/\=$/, '')
          attribute_method?(method_name) ? true : false
        end
      end

      def build_condition(opts = {})
        new_condition(opts).tap do |condition|
          self.conditions << condition
        end
      end

      def new_condition(opts = {})
        attrs = opts[:attributes] || 1
        vals = opts[:values] || 1
        condition = Condition.new(@context)
        condition.predicate = Predicate.named('eq')
        attrs.times { condition.build_attribute }
        vals.times { condition.build_value }
        condition
      end

      def ands
        @ands ||= []
      end
      alias :n :ands

      def ands=(ands)
        case ands
        when Array
          ands.each do |attrs|
            and_object = And.new(@context).build(attrs)
            self.ands << and_object if and_object.values.any?
          end
        when Hash
          ands.each do |index, attrs|
            and_object = And.new(@context).build(attrs)
            self.ands << and_object if and_object.values.any?
          end
        else
          raise ArgumentError, "Invalid argument (#{ands.class}) supplied to ands="
        end
      end
      alias :n= :ands=

      def ors
        @ors ||= []
      end
      alias :o :ors

      def ors=(ors)
        case ors
        when Array
          ors.each do |attrs|
            or_object = Or.new(@context).build(attrs)
            self.ors << or_object if or_object.values.any?
          end
        when Hash
          ors.each do |index, attrs|
            or_object = Or.new(@context).build(attrs)
            self.ors << or_object if or_object.values.any?
          end
        else
          raise ArgumentError, "Invalid argument (#{ors.class}) supplied to ors="
        end
      end
      alias :o= :ors=

      def method_missing(method_id, *args)
        method_name = method_id.to_s
        writer = method_name.sub!(/\=$/, '')
        if attribute_method?(method_name)
          writer ? write_attribute(method_name, *args) : read_attribute(method_name)
        else
          super
        end
      end

      def attribute_method?(name)
        name = strip_predicate_and_index(name)
        case name
        when /^(n|o|c|ands|ors|conditions)=?$/
          true
        else
          name.split(/_and_|_or_/).select {|n| !@context.attribute_method?(n)}.empty?
        end
      end

      def build_and(params = {})
        params ||= {}
        new_and(params).tap do |new_and|
          self.ands << new_and
        end
      end

      def new_and(params = {})
        And.new(@context).build(params)
      end

      def build_or(params = {})
        params ||= {}
        new_or(params).tap do |new_or|
          self.ors << new_or
        end
      end

      def new_or(params = {})
        Or.new(@context).build(params)
      end

      def build(params)
        params.with_indifferent_access.each do |key, value|
          case key
          when /^(n|o|c)$/
            self.send("#{key}=", value)
          else
            write_attribute(key.to_s, value)
          end
        end
        self
      end

      private

      def write_attribute(name, val)
        # TODO: Methods
        if condition = Condition.extract(@context, name, val)
          self[name] = condition
        end
      end

      def read_attribute(name)
        if self[name].respond_to?(:value)
          self[name].value
        else
          self[name]
        end
      end

      def strip_predicate_and_index(str)
        string = str.split(/\(/).first
        Ransack.predicate_keys.detect {|p| string.sub!(/_#{p}$/, '')}
        string
      end

    end
  end
end