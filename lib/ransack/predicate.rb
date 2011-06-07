module Ransack
  class Predicate
    attr_reader :name, :arel_predicate, :type, :formatter, :validator, :compound

    class << self

      def names
        Ransack.predicates.keys
      end

      def names_by_decreasing_length
        names.sort {|a,b| b.length <=> a.length}
      end

      def named(name)
        Ransack.predicates[name.to_s]
      end

      def detect_and_strip_from_string!(str)
        names_by_decreasing_length.detect {|p| str.sub!(/_#{p}$/, '')}
      end

      def detect_from_string(str)
        names_by_decreasing_length.detect {|p| str.match(/_#{p}$/)}
      end

      def name_from_attribute_name(attribute_name)
        names_by_decreasing_length.detect {|p| attribute_name.to_s.match(/_#{p}$/)}
      end

      def for_attribute_name(attribute_name)
        self.named(detect_from_string(attribute_name.to_s))
      end

    end

    def initialize(opts = {})
      @name = opts[:name]
      @arel_predicate = opts[:arel_predicate]
      @type = opts[:type]
      @formatter = opts[:formatter]
      @validator = opts[:validator]
      @compound = opts[:compound]
    end

    def eql?(other)
      self.class == other.class &&
      self.name == other.name
    end
    alias :== :eql?

    def hash
      name.hash
    end

    def format(val)
      if formatter
        formatter.call(val)
      else
        val
      end
    end

    def validate(vals)
      if validator
        vals.select {|v| validator.call(v.value)}.any?
      else
        vals.select {|v| v.present?}.any?
      end
    end

  end
end