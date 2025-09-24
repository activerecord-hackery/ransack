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

    attr_reader :base, :context, :scope_args

    delegate :object, :klass, to: :context
    delegate :new_grouping, :new_condition,
             :build_grouping, :build_condition,
             :translate, to: :base

    def initialize(object, params = {}, options = {})
      strip_whitespace = options.fetch(:strip_whitespace, Ransack.options[:strip_whitespace])
      params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
      if params.is_a? Hash
        params = params.dup
        params = params.transform_values { |v| v.is_a?(String) && strip_whitespace ? v.strip : v }
        params.delete_if { |k, v| [*v].all?{ |i| i.blank? && i != false } }
      else
        params = {}
      end
      @context = options[:context] || Context.for(object, options)
      @context.auth_object = options[:auth_object]
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

    def sorts=(args)
      case args
      when Array
        args.each do |sort|
          if sort.kind_of? Hash
            sort = Nodes::Sort.new(@context).build(sort)
          else
            sort = Nodes::Sort.extract(@context, sort)
          end
          self.sorts << sort if sort
        end
      when Hash
        args.each do |index, attrs|
          sort = Nodes::Sort.new(@context).build(attrs)
          self.sorts << sort
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

    def method_missing(method_id, *args)
      method_name = method_id.to_s
      getter_name = method_name.sub(/=$/, ''.freeze)
      if base.attribute_method?(getter_name)
        base.send(method_id, *args)
      elsif @context.ransackable_scope?(getter_name, @context.object)
        if method_name =~ /=$/
          add_scope getter_name, args
        else
          @scope_args[method_name]
        end
      else
        super
      end
    end

    def and(other_search)
      ChainedSearch.new(self, other_search, :and)
    end

    def or(other_search) 
      ChainedSearch.new(self, other_search, :or)
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

    def add_scope(key, args)
      sanitized_args = if Ransack.options[:sanitize_scope_args] && !@context.ransackable_scope_skip_sanitize_args?(key, @context.object)
        sanitized_scope_args(args)
      else
        args
      end

      if @context.scope_arity(key) == 1
        @scope_args[key] = args.is_a?(Array) ? args[0] : args
      else
        @scope_args[key] = args.is_a?(Array) ? sanitized_args : args
      end
      @context.chain_scope(key, sanitized_args)
    end

    def sanitized_scope_args(args)
      if args.is_a?(Array)
        args = args.map(&method(:sanitized_scope_args))
      end

      if Constants::TRUE_VALUES.include? args
        true
      elsif Constants::FALSE_VALUES.include? args
        false
      else
        args
      end
    end

    def collapse_multiparameter_attributes!(attrs)
      attrs.keys.each do |k|
        if k.include?(Constants::LEFT_PARENTHESIS)
          real_attribute, position = k.split(/\(|\)/)
          cast =
          if Constants::A_S_I.include?(position.last)
            position.last
          else
            nil
          end
          position = position.to_i - 1
          value = attrs.delete(k)
          attrs[real_attribute] ||= []
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

  end

  # ChainedSearch represents a combination of two searches with AND or OR logic
  class ChainedSearch
    include Naming

    attr_reader :left_search, :right_search, :combinator, :context

    delegate :object, :klass, to: :context

    def initialize(left_search, right_search, combinator = :and)
      @left_search = left_search
      @right_search = right_search
      @combinator = combinator.to_s
      
      # Use the left search's context, but ensure both searches can use the same context
      @context = ensure_shared_context(left_search, right_search)
    end

    def result(opts = {})
      # Create a virtual grouping that represents the combination of both searches
      combined_grouping = create_combined_grouping
      
      # Create a temporary search with the combined grouping
      temp_search = create_temp_search_with_grouping(combined_grouping)
      
      # Use the context's evaluation method to properly handle joins and conditions
      @context.evaluate(temp_search, opts)
    end

    def and(other_search)
      ChainedSearch.new(self, other_search, :and)
    end

    def or(other_search)
      ChainedSearch.new(self, other_search, :or)
    end

    def inspect
      "Ransack::ChainedSearch<left: #{@left_search.inspect}, right: #{@right_search.inspect}, combinator: #{@combinator}>"
    end

    # Delegate scope_args for compatibility
    def scope_args
      combined_args = {}
      
      if @left_search.respond_to?(:scope_args)
        combined_args.merge!(@left_search.scope_args)
      end
      
      if @right_search.respond_to?(:scope_args)
        combined_args.merge!(@right_search.scope_args)
      end
      
      combined_args
    end

    private

    def create_combined_grouping
      # Create a new grouping with the appropriate combinator
      grouping = Nodes::Grouping.new(@context, @combinator)
      
      # Add the base groupings from both searches
      left_base = get_base_from_search(@left_search)
      right_base = get_base_from_search(@right_search)
      
      # Add the bases as child groupings
      grouping.groupings << left_base if left_base
      grouping.groupings << right_base if right_base
      
      grouping
    end
    
    def create_temp_search_with_grouping(grouping)
      # Create a minimal search object that can be used with context.evaluate
      temp_search = Object.new
      temp_search.define_singleton_method(:base) { grouping }
      temp_search.define_singleton_method(:sorts) { [] }
      temp_search
    end
    
    def get_base_from_search(search)
      if search.is_a?(ChainedSearch)
        # For ChainedSearch, create its combined grouping
        search.send(:create_combined_grouping)
      else
        # For regular Search, return its base grouping
        search.base
      end
    end

    private

    def ensure_shared_context(left_search, right_search)
      # If searches already share a context, use it
      if left_search.context == right_search.context
        return left_search.context
      end

      # Create a new shared context for the same class
      shared_context = Context.for(left_search.klass)
      
      # Re-create searches with shared context to ensure proper join handling
      recreate_search_with_context(left_search, shared_context)
      recreate_search_with_context(right_search, shared_context)
      
      shared_context
    end

    def recreate_search_with_context(search, context)
      # If it's a ChainedSearch, handle recursively
      if search.is_a?(ChainedSearch)
        recreate_search_with_context(search.left_search, context)
        recreate_search_with_context(search.right_search, context)
        search.instance_variable_set(:@context, context)
      else
        # For regular Search, we need to update its context
        # This is a bit hacky but necessary for join consistency
        search.instance_variable_set(:@context, context)
      end
    end

    def apply_scopes(relation, search)
      if search.is_a?(ChainedSearch)
        relation = apply_scopes(relation, search.left_search)
        relation = apply_scopes(relation, search.right_search)
      elsif search.respond_to?(:scope_args) && search.scope_args.any?
        # Apply scopes from the search
        search.scope_args.each do |scope_name, args|
          if relation.respond_to?(scope_name)
            relation = relation.public_send(scope_name, *args)
          end
        end
      end
      relation
    end
  end
end
