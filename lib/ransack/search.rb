require 'ransack/nodes/bindable'
require 'ransack/nodes/node'
require 'ransack/nodes/attribute'
require 'ransack/nodes/value'
require 'ransack/nodes/condition'
require 'ransack/nodes/sort'
require 'ransack/nodes/grouping'
require 'ransack/context'
require 'ransack/naming'
require 'ransack/invalid_search_error'

module Ransack
  class Search
    include Naming

    attr_reader :base, :context

    delegate :object, :klass, to: :context
    delegate :new_grouping, :new_condition,
             :build_grouping, :build_condition,
             :translate, to: :base

    def initialize(object, params = {}, options = {})
      strip_whitespace = options.fetch(:strip_whitespace, Ransack.options[:strip_whitespace])
      params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
      if params.is_a? Hash
        # deep_transform_values rebuilds every nested hash and array, which
        # also gives the pruning below a private copy to edit — the caller's
        # params come back untouched. Values nested inside `g:` groupings and
        # `c:` conditions are stripped too, not just the top level.
        params = params.deep_transform_values { |v| v.is_a?(String) && strip_whitespace ? v.strip : v }
        params.delete_if { |_k, v| blank_condition_value?(v) }
        prune_blank_advanced_conditions!(params)
      else
        params = {}
      end
      @context = options[:context] || Context.for(object, options)
      @context.auth_object = options[:auth_object]
      @context.ignore_unknown_conditions = options[:ignore_unknown_conditions]
      @context.null_sentinel = options[:null_sentinel]
      @base = Nodes::Grouping.new(
        @context, options[:grouping] || Constants::AND
        )
      @scope_args = {}
      @sorts ||= []
      @ignore_unknown_conditions = options[:ignore_unknown_conditions] == false ? false : true
      build(params.with_indifferent_access)
    end

    def result(opts = {})
      @context.evaluate(self, opts)
    end

    def build(params)
      collapse_multiparameter_attributes!(params).each do |key, value|
        if ['s'.freeze, 'sorts'.freeze].freeze.include?(key)
          send("#{key}=", value)
        elsif @context.ransackable_scope?(key, @context.object)
          add_scope(key, value)
        elsif base.attribute_method?(key)
          base.send("#{key}=", value)
        elsif !Ransack.options[:ignore_unknown_conditions] || !@ignore_unknown_conditions
          raise InvalidSearchError, "Invalid search term #{key}"
        end
      end
      self
    end

    # Replaces the sorts, so `search.sorts = []` clears them. Before 6.0 each
    # assignment appended (#994); use `build_sort` to add one.
    def sorts=(args)
      @sorts = [] unless args.is_a?(String)
      case args
      when Array
        args.each do |sort|
          if sort.kind_of? Hash
            sort = Nodes::Sort.new(@context).build(sort)
          else
            sort = Nodes::Sort.extract(@context, sort)
          end
          add_sort(sort) if sort
        end
      when Hash
        args.each do |index, attrs|
          add_sort(Nodes::Sort.new(@context).build(attrs))
        end
      when String
        self.sorts = [args]
      else
        raise InvalidSearchError,
        "Invalid argument (#{args.class}) supplied to sorts="
      end
    end
    alias :s= :sorts=

    def sorts
      @sorts
    end
    alias :s :sorts

    def build_sort(opts = {})
      new_sort(opts).tap do |sort|
        self.sorts << sort
      end
    end

    def new_sort(opts = {})
      Nodes::Sort.new(@context).build(opts)
    end

    # A scope wins over an attribute of the same name, as it does when the
    # params hash is built (#1472).
    def method_missing(method_id, *args)
      method_name = method_id.to_s
      getter_name = method_name.sub(/=$/, ''.freeze)
      if @context.ransackable_scope?(getter_name, @context.object)
        if method_name =~ /=$/
          add_scope getter_name, args.size == 1 ? args.first : args
        else
          @scope_args[method_name]
        end
      elsif base.attribute_method?(getter_name)
        base.send(method_id, *args)
      else
        super
      end
    end

    # Rails' form helpers only read a field's value back when the object
    # says it responds to the reader; `form_with` in particular checks
    # before calling. Mirror method_missing so a search_form_with field is
    # pre-filled the same way a search_form_for one is.
    def respond_to_missing?(method_id, include_private = false)
      getter_name = method_id.to_s.sub(/=$/, ''.freeze)
      base.attribute_method?(getter_name) ||
        @context.ransackable_scope?(getter_name, @context.object) ||
        super
    end

    def inspect
      details = [
        [:class, klass.name],
        ([:scope, @scope_args] if @scope_args.present?),
        [:base, base.inspect]
      ]
      .compact
      .map { |d| d.join(': '.freeze) }
      .join(', '.freeze)

      "Ransack::Search<#{details}>"
    end

    private

    # A sort that names neither a sortable attribute nor a `sort_by_<name>_<dir>`
    # scope produces no ORDER BY. Under a strict search that is an error, the
    # same as an unknown attribute in a condition (#1427); otherwise it is
    # dropped as before.
    def add_sort(sort)
      if @context.strict_conditions? && !sort.valid? && !sort_scope?(sort)
        raise InvalidSearchError, "Invalid sort term #{sort.name}"
      end

      self.sorts << sort
    end

    def sort_scope?(sort)
      @context.object.respond_to?(:"sort_by_#{sort.name}_#{sort.dir}")
    end

    def add_scope(key, args)
      sanitized_args = @context.sanitize_scope_args(key, args)

      if @context.scope_arity(key) == 1
        @scope_args[key] = args.is_a?(Array) ? args[0] : args
      else
        @scope_args[key] = args.is_a?(Array) ? sanitized_args : args
      end
      @context.chain_scope(key, sanitized_args)
    end

    # The largest position a multiparameter key (`created_at(1i)`) may carry.
    # Rails' date and time selects emit at most six, year to second. The
    # position indexes an array, so an unbounded one from a crafted query
    # string would allocate an array that size (GHSA-vxc9-rm8f-p56j).
    MULTIPARAMETER_POSITION_LIMIT = 16

    # Folds `created_at(1i)`, `created_at(2i)`, ... into `created_at` as an
    # array of cast values, the way Active Record does for form input. The
    # keys are untrusted, so a malformed one is dropped rather than raised
    # on: no position (`created_at(`), a position outside 1 to the limit,
    # or a fragment for an attribute that was also given as a plain value.
    def collapse_multiparameter_attributes!(attrs)
      attrs.keys.each do |k|
        if k.include?(Constants::LEFT_PARENTHESIS)
          real_attribute, position = k.split(/\(|\)/)
          value = attrs.delete(k)
          next if position.nil?

          cast = Constants::A_S_I.include?(position.last) ? position.last : nil
          position = position.to_i - 1
          next if position < 0 || position >= MULTIPARAMETER_POSITION_LIMIT

          attrs[real_attribute] ||= []
          next unless attrs[real_attribute].is_a?(Array)

          attrs[real_attribute][position] =
          if cast
            if value.blank? && cast == Constants::I
              nil
            else
              value.send("to_#{cast}")
            end
          else
            value
          end
        elsif Hash === attrs[k]
          collapse_multiparameter_attributes!(attrs[k])
        end
      end

      attrs
    end

    # True when a condition's value should be dropped before building. With
    # `ignore_blank_values` on (the default) a blank value means "this form
    # field was left empty"; with it off, only nil is treated that way and a
    # blank value is a value to search for. `false` is always a real value, and
    # an explicit nil inside an array is kept so `name_in: [nil]` still reaches
    # the query. The `c:` pruning below shares this, so it follows the option.
    def blank_condition_value?(value)
      if Ransack.options[:ignore_blank_values]
        [*value].all? { |i| i.blank? && i != false && !i.nil? }
      else
        value.nil? || (value.is_a?(Array) && !value.empty? && value.all?(&:nil?))
      end
    end

    # The low-level `c:` API nests its values a level deeper than the shorthand
    # form, so the filter above never sees them. Left in place, a condition with
    # an empty value still builds its attribute and contributes a join, giving a
    # LEFT OUTER JOIN with no WHERE clause to go with it.
    def prune_blank_advanced_conditions!(node)
      return unless node.is_a?(Hash)

      conditions = fetch_either(node, :c, :conditions)
      case conditions
      when Array then conditions.delete_if { |c| blank_advanced_condition?(c) }
      when Hash  then conditions.delete_if { |_k, c| blank_advanced_condition?(c) }
      end

      # Groupings nest to any depth and carry their own conditions, so descend
      # into each of them too.
      groupings = fetch_either(node, :g, :groupings)
      groupings = groupings.values if groupings.is_a?(Hash)
      Array(groupings).each { |grouping| prune_blank_advanced_conditions!(grouping) }
    end

    # Params are not yet indifferent-access here, so look under both spellings
    # of a key and both its short and long forms.
    def fetch_either(hash, short, long)
      hash[short] || hash[short.to_s] || hash[long] || hash[long.to_s]
    end

    def blank_advanced_condition?(condition)
      return false unless condition.is_a?(Hash)

      values = condition[:v] || condition['v']

      case values
      when Array then values.all? { |v| blank_condition_value?(unwrap_value(v)) }
      when Hash  then values.all? { |_k, v| blank_condition_value?(unwrap_value(v)) }
      end
    end

    # Values in the `c:` API may be given bare or wrapped in a `{ value: ... }`
    # envelope, the same two forms `Condition#values=` accepts.
    def unwrap_value(value)
      value.is_a?(Hash) ? (value[:value] || value['value']) : value
    end
  end
end
