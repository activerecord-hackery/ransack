module Ransack
  class Predicate
    attr_reader :name, :arel_predicate, :type, :formatter, :validator, :compound

    class << self
      def named(name)
        Ransack.predicates[name.to_s]
      end

      def for_attribute_name(attribute_name)
        self.named(Ransack.predicate_keys.detect {|p| attribute_name.to_s.match(/_#{p}$/)})
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

    def validate(vals)
      if validator
        vals.select {|v| validator.call(v.value)}.any?
      else
        vals.select {|v| !v.blank?}.any?
      end
    end

  end
end