module Ransack
  module Nodes
    class Node
      attr_reader :context
      delegate :contextualize, to: :context
      class_attribute :i18n_words
      class_attribute :i18n_aliases
      self.i18n_words = []
      self.i18n_aliases = {}

      class << self
        def i18n_word(*args)
          self.i18n_words += args.map(&:to_s)
        end

        def i18n_alias(opts = {})
          self.i18n_aliases.merge! Hash[opts.map { |k, v| [k.to_s, v.to_s] }]
        end
      end

      def initialize(context)
        @context = context
      end

      def translate(key, options = {})
        key = i18n_aliases[key.to_s] if i18n_aliases.has_key?(key.to_s)
        if i18n_words.include?(key.to_s)
          Translate.word(key)
        end
      end

      # Every way of supplying a combinator — a top-level `combinator`/`m`,
      # or an `m` inside any nested grouping or condition — ends up here, so
      # this is the one place that normalises the spelling and, when the search
      # is strict, rejects a value it does not recognise.
      def combinator=(val)
        normalised = val.to_s.downcase
        @combinator = Constants::AND_OR.detect { |v| v == normalised }

        if @combinator.nil? && !normalised.empty? && context&.strict_conditions?
          raise InvalidSearchError, "Invalid combinator #{val}"
        end
      end

      private

      # Search params usually come from the request, so a grouping, condition
      # or sort given as something other than a hash (`q[g]=x`) is a malformed
      # search, not a programming error, whether or not the search is strict.
      def indifferent_params(params, node_name)
        return params.with_indifferent_access if params.respond_to?(:with_indifferent_access)

        raise InvalidSearchError,
          "Invalid argument (#{params.class}) supplied for a #{node_name}"
      end

    end
  end
end
