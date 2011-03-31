module Ransack
  class Predicate
    attr_reader :name, :arel_predicate, :type, :formatter, :validator, :compound

    class << self
      def named(name)
        Configuration.predicates[name.to_s]
      end

      def for_attribute_name(attribute_name)
        self.named(Configuration.predicate_keys.detect {|p| attribute_name.to_s.match(/_#{p}$/)})
      end

      def collection
        Configuration.predicates.map {|k, v| [k, Translate.predicate(k)]}
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

    def format(vals)
      if formatter
        vals.select {|v| validator ? validator.call(v.value_before_cast) : !v.blank?}.
             map {|v| formatter.call(v.value)}
      else
        vals.select {|v| validator ? validator.call(v.value_before_cast) : !v.blank?}.
             map {|v| v.value}
      end
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
        vals.select {|v| validator.call(v.value_before_cast)}.any?
      else
        vals.select {|v| !v.blank?}.any?
      end
    end

  end
end