require 'ransack/invalid_search_error'

module Ransack
  module Nodes
    class Condition < Node
      i18n_word :attribute, :predicate, :combinator, :value
      i18n_alias a: :attribute, p: :predicate,
                 m: :combinator, v: :value

      attr_accessor :predicate

      class << self
        def extract(context, key, values)
          attributes, predicate, combinator =
            extract_values_for_condition(key, context)

          if attributes.size > 0 && predicate
            condition = self.new(context)
            condition.build(
              a: attributes,
              p: predicate.name,
              m: combinator,
              v: predicate.wants_array ? Array(values) : [values]
            )
            # TODO: Figure out what to do with multiple types of attributes,
            # if anything. Tempted to go with "garbage in, garbage out" here.
            if predicate.validate(condition.values, condition.default_type)
              condition
            else
              nil
            end
          end
        end

        private

          def extract_values_for_condition(key, context = nil)
            str = key.dup
            name = Predicate.detect_and_strip_from_string!(str)
            predicate = Predicate.named(name)

            unless predicate || Ransack.options[:ignore_unknown_conditions]
              raise InvalidSearchError, "No valid predicate for #{key}"
            end

            if context.present?
              str = context.ransackable_alias(str)
            end

            combinator =
            if str.match(/_(or|and)_/)
              $1
            else
              nil
            end

            if context.present? && context.attribute_method?(str)
              attributes = [str]
            else
              attributes = str.split(/_and_|_or_/)
            end

            [attributes, predicate, combinator]
          end
      end

      def valid?
        attributes.detect(&:valid?) && predicate && valid_arity? &&
          predicate.validate(values, default_type) && valid_combinator?
      end

      def valid_arity?
        values.size <= 1 || predicate.wants_array
      end

      def attributes
        @attributes ||= []
      end
      alias :a :attributes

      def attributes=(args)
        case args
        when Array
          args.each do |attr|
            if attr.is_a?(Hash) && (attr.key?(:name) || attr.key?("name"))
              attr = attr.with_indifferent_access
              build_attribute(attr[:name], attr[:ransacker_args])
            else
              build_attribute(attr)
            end
          end
        when Hash
          args.each do |index, attrs|
            build_attribute(attrs[:name], attrs[:ransacker_args])
          end
        else
          raise ArgumentError,
            "Invalid argument (#{args.class}) supplied to attributes="
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
            if val.is_a?(Hash) && (val.key?(:value) || val.key?("value"))
              val = val.with_indifferent_access[:value]
            end
            self.values << Value.new(@context, val)
          end
        when Hash
          args.each do |index, attrs|
            val = Value.new(@context, attrs[:value])
            self.values << val
          end
        else
          raise ArgumentError,
            "Invalid argument (#{args.class}) supplied to values="
        end
      end
      alias :v= :values=

      def combinator
        @attributes.size > 1 ? @combinator : nil
      end

      def combinator=(val)
        super
      end

      alias :m= :combinator=
      alias :m :combinator

      # == build_attribute
      #
      #  This method was originally called from Nodes::Grouping#new_condition
      #  only, without arguments, without #valid? checking, to build a new
      #  grouping condition.
      #
      #  After refactoring in 235eae3, it is now called from 2 places:
      #
      #  1. Nodes::Condition#attributes=, with +name+ argument passed or +name+
      #     and +ransacker_args+. Attributes are included only if #valid?.
      #
      #  2. Nodes::Grouping#new_condition without arguments. In this case, the
      #     #valid? conditional needs to be bypassed, otherwise nothing is
      #     built. The `name.nil?` conditional below currently does this.
      #
      #  TODO: Add test coverage for this behavior and ensure that `name.nil?`
      #  isn't fixing issue #701 by introducing untested regressions.
      #
      def build_attribute(name = nil, ransacker_args = [])
        Attribute.new(@context, name, ransacker_args).tap do |attribute|
          @context.bind(attribute, attribute.name)
          self.attributes << attribute if name.nil? || attribute.valid?
          if predicate && !negative?
            @context.lock_association(attribute.parent)
          end
        end
      end

      def build_value(val = nil)
        Value.new(@context, val).tap do |value|
          self.values << value
        end
      end

      def value
        if predicate.wants_array
          values.map { |v| v.cast(default_type) }
        else
          values.first.cast(default_type)
        end
      end

      # The long spellings route through the short setters: `p=` resolves a
      # Predicate object, whereas the `predicate=` attribute writer would store
      # the bare name.
      LONG_KEYS = {
        'attributes' => 'a', 'values' => 'v', 'predicate' => 'p', 'combinator' => 'm'
      }.freeze

      def build(params)
        params.with_indifferent_access.each do |key, value|
          if key.match(/^(a|v|p|m|attributes|values|predicate|combinator)$/)
            self.send("#{LONG_KEYS.fetch(key, key)}=", value)
          end
        end

        self
      end

      def persisted?
        false
      end

      def key
        @key ||= attributes.map(&:name).join("_#{combinator}_") +
          "_#{predicate.name}"
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
        unless negative?
          attributes.each { |a| context.lock_association(a.parent) }
        end
        @predicate
      end
      alias :p= :predicate_name=

      def predicate_name
        predicate.name if predicate
      end
      alias :p :predicate_name

      def validated_values
        values.select { |v| predicate.validator.call(v.value) }
      end

      def casted_values_for_attribute(attr)
        validated_values.map { |v| v.cast(predicate.type || attr.type) }
      end

      def formatted_values_for_attribute(attr)
        formatted = casted_values_for_attribute(attr).map do |val|
          if attr.ransacker && attr.ransacker.formatter
            val = attr.ransacker.formatter.call(val)
          end
          val = predicate.format(val)
          if val.is_a?(String) && val.include?('%')
            val = Arel::Nodes::Quoted.new(val)
          end
          val
        end
        if predicate.wants_array
          formatted
        else
          formatted.first
        end
      end

      def arel_predicate_for_attribute(attr)
        if predicate.arel_predicate === Proc
          values = casted_values_for_attribute(attr)
          unless predicate.wants_array
            values = values.first
          end
          predicate.arel_predicate.call(values)
        else
          predicate.arel_predicate
        end
      end

      def attr_value_for_attribute(attr)
        return attr.attr if ActiveRecord::Base.adapter_class::ADAPTER_NAME == "PostgreSQL"

        predicate.case_insensitive ? attr.attr.lower : attr.attr
      rescue
        attr.attr
      end

      def default_type
        predicate.type || (attributes.first && attributes.first.type)
      end

      def inspect
        data = [
          ['attributes'.freeze, a.try(:map, &:name)],
          ['predicate'.freeze, p],
          [Constants::COMBINATOR, m],
          ['values'.freeze, v.try(:map, &:value)]
        ]
        .reject { |e| e[1].blank? }
        .map { |v| "#{v[0]}: #{v[1]}" }
        .join(', '.freeze)
        "Condition <#{data}>"
      end

      def negative?
        predicate.negative?
      end

      def arel_predicate
        attributes.map { |attribute|
          association = attribute.parent
          parent_table = association.table

          predicate = if negative? && attribute.associated_collection? && not_nested_condition(attribute, parent_table)
            query = context.build_correlated_subquery(association)
            context.remove_association(association)

            case self.predicate_name
            when 'not_null'
              if self.value
                query.where(format_predicate(attribute))
                Arel::Nodes::In.new(context.primary_key, Arel.sql(query.to_sql))
              else
                query.where(format_predicate(attribute).not)
                Arel::Nodes::NotIn.new(context.primary_key, Arel.sql(query.to_sql))
              end
            when 'not_cont'
              query.where(attribute.attr.matches(formatted_values_for_attribute(attribute)))
              Arel::Nodes::NotIn.new(context.primary_key, Arel.sql(query.to_sql))
            else
              query.where(format_predicate(attribute).not)
              Arel::Nodes::NotIn.new(context.primary_key, Arel.sql(query.to_sql))
            end
          else
            format_predicate(attribute)
          end

          # Applied per attribute rather than to the reduced node: once several
          # attributes are combined, the result is an And/Or whose `right` is
          # another predicate node rather than a Casted value, so
          # replace_right_node? returns false and nothing is unwrapped at all.
          if replace_right_node?(predicate)
            # Replace right node object to plain integer value in order to avoid
            # ActiveModel::RangeError from Arel::Node::Casted.
            # The error can be ignored here because RDBMSs accept large numbers
            # in condition clauses.
            plain_value = predicate.right.value
            predicate.right = plain_value
          end

          predicate
        }.reduce(combinator_method)
      end

      def not_nested_condition(attribute, parent_table)
        parent_table.class != Arel::Nodes::TableAlias && attribute.name.starts_with?(parent_table.name)
      end

      private

      def combinator_method
        combinator === Constants::OR ? :or : :and
      end

      def format_predicate(attribute)
        arel_pred = arel_predicate_for_attribute(attribute)
        arel_values = formatted_values_for_attribute(attribute)

        # The `present` / `blank` predicate formatters produce `[nil, '']` regardless
        # of column type. The empty-string half has no meaning on non-string columns:
        # ActiveRecord casts `''` to NULL for those types, producing the
        # always-UNKNOWN `column != NULL` (or `column = NULL`) clause. Strip the
        # empty string when the attribute is not a string-like column.
        if arel_values.is_a?(Array) && arel_values.include?(''.freeze) && !string_like_attribute?(attribute)
          arel_values = arel_values.reject { |v| v == ''.freeze }
        end

        # For LIKE predicates, wrap the value in Arel::Nodes.build_quoted to prevent
        # ActiveRecord normalization from affecting wildcard patterns, and pass
        # the escape character so the escaping done by `escape_wildcards` is
        # actually honoured. Without an explicit ESCAPE clause, SQLite treats a
        # backslash as a literal character rather than an escape.
        # See https://github.com/activerecord-hackery/ransack/issues/1581
        # A length predicate compares LENGTH(column) rather than the column.
        attr_value = length_predicate? ? length_function_for_attribute(attribute) : attr_value_for_attribute(attribute)

        if like_predicate?(arel_pred)
          # The compound forms (matches_any / matches_all and their negations)
          # iterate over an Array of patterns, so each element is quoted on its
          # own; wrapping the whole Array in one node would hand them a single
          # Quoted to iterate over.
          arel_values = if arel_values.is_a?(Array)
            arel_values.map { |v| Arel::Nodes.build_quoted(v) }
          else
            Arel::Nodes.build_quoted(arel_values)
          end
          predicate = attr_value.public_send(arel_pred, arel_values, Constants::LIKE_ESCAPE_CHARACTER)
        else
          predicate = attr_value.public_send(arel_pred, arel_values)
        end

        if in_predicate?(predicate)
          predicate.right = predicate.right.map do |pr|
            casted_array?(pr) ? format_values_for(pr) : pr
          end
        end

        predicate
      end

      def in_predicate?(predicate)
        return unless defined?(Arel::Nodes::Casted)
        predicate.class == Arel::Nodes::In || predicate.class == Arel::Nodes::NotIn
      end

      LIKE_PREDICATES = %w[
        matches matches_any matches_all
        does_not_match does_not_match_any does_not_match_all
      ].freeze

      def like_predicate?(arel_predicate)
        LIKE_PREDICATES.include?(arel_predicate)
      end

      STRING_LIKE_TYPES = %i[string text citext].freeze

      def string_like_attribute?(attribute)
        type = attribute.type
        # Treat unknown types as string-like (conservative: keep the existing
        # empty-string comparison rather than silently dropping it).
        type.nil? || STRING_LIKE_TYPES.include?(type.to_sym)
      end

      def casted_array?(predicate)
        predicate.is_a?(Arel::Nodes::Casted) && predicate.value.is_a?(Array)
      end

      def format_values_for(predicate)
        predicate.value.map do |val|
          val.is_a?(String) ? Arel::Nodes.build_quoted(val) : val
        end
      end

      def replace_right_node?(predicate)
        return false unless predicate.is_a?(Arel::Nodes::Binary)

        arel_node = predicate.right
        return false unless arel_node.is_a?(Arel::Nodes::Casted)

        relation, name = arel_node.attribute.values
        attribute_type = relation.type_for_attribute(name).type
        attribute_type == :integer && arel_node.value.is_a?(Integer)
      end

      def length_predicate?
        predicate_name.to_s.start_with?('length_')
      end

      # CHAR_LENGTH counts characters and is the SQL standard spelling; SQLite
      # has no CHAR_LENGTH and its LENGTH already counts characters for text.
      CHAR_LENGTH_ADAPTERS = %w[PostgreSQL PostGIS Mysql2 Trilogy].freeze

      def length_function_for_attribute(attribute)
        function_name =
          if CHAR_LENGTH_ADAPTERS.include?(ActiveRecord::Base.adapter_class::ADAPTER_NAME)
            'CHAR_LENGTH'.freeze
          else
            'LENGTH'.freeze
          end

        Arel::Nodes::NamedFunction.new(
          function_name,
          [attr_value_for_attribute(attribute)]
        )
      end

      def valid_combinator?
        attributes.size < 2 || Constants::AND_OR.include?(combinator)
      end
    end
  end
end
