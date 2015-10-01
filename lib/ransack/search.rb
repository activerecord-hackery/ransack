require 'ransack/nodes'
require 'ransack/context'
Ransack::Adapters.require_search
require 'ransack/naming'

module Ransack
  class Search
    include Naming

    attr_reader :base, :context

    delegate :object, :klass, :to => :context
    delegate :new_grouping, :new_condition,
             :build_grouping, :build_condition,
             :translate, :to => :base

    def initialize(object, params = {}, options = {})
      if params.instance_variable_defined?(:@parameters)
        params = params.instance_variable_get :@parameters
      end
      if params.is_a? Hash
        params.each { |search_expression, _| enable_shallow_search(object, search_expression) }
        params = params.dup.delete_if { |_, v| [*v].all?{ |i| i.blank? && i != false } }
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
      build(params.with_indifferent_access)
    end

    def result(opts = {})
      @context.evaluate(self, opts)
    end

    def build(params)
      collapse_multiparameter_attributes!(params).each do |key, value|
        if ['s'.freeze, 'sorts'.freeze].freeze.include?(key)
          send("#{key}=", value)
        elsif base.attribute_method?(key)
          base.send("#{key}=", value)
        elsif @context.ransackable_scope?(key, @context.object)
          add_scope(key, value)
        elsif !Ransack.options[:ignore_unknown_conditions]
          raise ArgumentError, "Invalid search term #{key}"
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
          self.sorts << sort
        end
      when Hash
        args.each do |index, attrs|
          sort = Nodes::Sort.new(@context).build(attrs)
          self.sorts << sort
        end
      when String
        self.sorts = [args]
      else
        raise ArgumentError,
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
      if @context.scope_arity(key) == 1
        @scope_args[key] = args.is_a?(Array) ? args[0] : args
      else
        @scope_args[key] = args.is_a?(Array) ? sanitized_scope_args(args) : args
      end
      @context.chain_scope(key, sanitized_scope_args(args))
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

    private

    def enable_shallow_search(klass, expr)
      scoped_attr_name = expr.is_a?(String) ? expr.dup : expr.to_s
      Predicate.detect_and_strip_from_string!(scoped_attr_name)
      find_or_create_assoc(klass, scoped_attr_name)
    end

    def find_or_create_assoc(klass, scoped_attr_name, parent_name = nil)
      return scoped_attr_name, nil, parent_name if is_attr_of?(scoped_attr_name, klass)
      Hash[klass.reflections.sort { |a, b| b<=>a }].each do |_, assoc|
        result = find_or_create_nested_assoc_if_applicable(klass, assoc, scoped_attr_name)
        return result if result && result[0]
      end
    end

    def is_attr_of?(attr_name, klass)
      klass.attribute_names.include?(attr_name)
    end

    def find_or_create_nested_assoc_if_applicable(klass, assoc, scoped_attr_name)
      #TODO: proper support for polymorphic too; support for _or_
      if scoped_attr_name.start_with?(assoc.name.to_s) && !assoc.options[:polymorphic] && !scoped_attr_name.include?('_or_')
        return find_or_create_nested_assoc(klass, assoc, scoped_attr_name)
      end
    end

    def find_or_create_nested_assoc(klass, assoc, scoped_attr_name)
      target_name = scoped_attr_name.match(/\A#{assoc.name.to_s}_(.*)/)[1]
      attribute_name, macro, target_name = find_or_create_assoc(assoc.klass, target_name, assoc.name)
      assoc_to_be_created = scoped_attr_name.match(/(.*)_#{attribute_name}\Z/)[1]
      macro = create_association_if_necessary(klass, assoc_to_be_created, macro, assoc)
      return attribute_name, macro, target_name
    end

    def create_association_if_necessary(klass, assoc_name, macro, target_assoc)
      macro ||= (target_assoc.macro == :has_many ? :has_many : :has_one)
      unless klass.method_defined?(assoc_name) #assoc to be created is already present
        source = assoc_name.match(/#{target_assoc.name}_(.*)/)[1]
        klass.send(macro, assoc_name.to_sym, through: target_assoc.name.to_sym, source: source.to_sym)
      end
      macro
    end

    def class_name_for(reflection, association_name, search_expression)
      if refle  ction.options[:polymorphic]
        search_expression.gsub(/#{association_name}_of_(.*?)_type.*/, '\1')
      else
        reflection.class_name
      end
    end
  end
end
