require 'ransack/nodes'
require 'ransack/context'
Ransack::Adapters.object_mapper.require_search
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
      params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
      if params.is_a? Hash
        params = params.dup
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
        elsif polymorphic_method = construct_polymorphic_parameter(key)
          base.send("#{polymorphic_method}=", value)
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
      elsif polymorphic_method = construct_polymorphic_parameter(method_id.to_s)
        base.send(polymorphic_method, *args)
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

    def construct_polymorphic_parameter(key)
      # Handle polymorphic search. A new parameter will be created to
      # replace the old invalid one.
      conditions = []
      predicate = Predicate.detect_from_string(key)
      # Search all the models to find ones that are associated.
      ActiveRecord::Base.descendants.each do |model|
        next if model.name == 'ApplicationRecord'
        next if model.name == @context.klass.name
        model.reflect_on_all_associations.each do |association|
          next if association.options[:as].blank?
          next unless key =~ /#{association.options[:as]}/
          able = association.options[:as].to_s
          column_name = key.gsub("#{able}_", '').gsub("_#{predicate}", '')
          next unless model.column_names.include? column_name
          conditions << "#{able}_of_#{model.name}_type_#{column_name}"
        end
      end
      "#{conditions.join('_or_')}_#{predicate}"
    end

  end
end
