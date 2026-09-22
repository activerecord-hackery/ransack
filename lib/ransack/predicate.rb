module Ransack
  class Predicate
    attr_reader :name, :arel_predicate, :type, :formatter, :validator,
                :compound, :wants_array, :case_insensitive

    # Consulted at search time rather than captured at predicate-definition
    # time, so that `Ransack.options[:ignore_blank_values]` set in an
    # initializer applies to the predicates registered before it ran.
    DEFAULT_VALIDATOR = lambda do |v|
      if Ransack.options[:ignore_blank_values]
        v.respond_to?(:empty?) ? !v.empty? : !v.nil?
      else
        !v.nil?
      end
    end

    class << self

      def names
        Ransack.predicates.keys
      end

      def named(name)
        Ransack.predicates[(name || Ransack.options[:default_predicate]).to_s]
      end

      def detect_and_strip_from_string!(str)
        detect_from_string str, chomp: true
      end

      def detect_from_string(str, chomp: false)
        return unless str

        Ransack.predicates.sorted_names_with_underscores.each do |predicate, underscored|
          if str.end_with? underscored
            str.chomp! underscored if chomp
            return predicate
          end
        end

        nil
      end

    end

    def initialize(opts = {})
      @name = opts[:name]
      @arel_predicate = opts[:arel_predicate]
      @type = opts[:type]
      @formatter = opts[:formatter]
      @validator = opts[:validator] || DEFAULT_VALIDATOR
      @compound = opts[:compound]
      @wants_array = opts.fetch(:wants_array,
        @compound || Constants::IN_NOT_IN.include?(@arel_predicate))
      @case_insensitive = opts[:case_insensitive]
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

    def validate(vals, type = @type)
      # An explicitly empty array is a meaningful filter (matching nothing)
      # rather than an absent one, but only when blank values are not ignored.
      return true if vals.empty? && wants_array &&
                     !Ransack.options[:ignore_blank_values]

      # The null sentinel is a marker compared by identity, never cast to
      # the column's type. Casting it here would be the only place it is
      # cast at all: a cast to :date or :integer turns most strings into
      # nil, which the validator then rejects, dropping the whole condition
      # when the sentinel is the only value submitted (#940).
      return true if Constants.null_sentinel_requested?(name, vals)

      # When blank values are meaningful, validate the value as given. Casting
      # first would turn '' into nil for an integer or boolean column and the
      # explicit blank would be dropped — leaving no condition at all.
      vals.any? do |v|
        value = type && Ransack.options[:ignore_blank_values] ? v.cast(type) : v.value
        validator.call(value)
      end
    end

    def negative?
      @name.include?("not_".freeze)
    end

  end
end
