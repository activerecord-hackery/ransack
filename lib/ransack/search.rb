require 'ransack/nodes'
require 'ransack/context'
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
      if params.is_a? Hash
        params = params.dup
        params.delete_if { |k, v| [*v].all?{ |i| i.blank? && i != false } }
      else
        params = {}
      end
      @context = options[:context] || Context.for(object, options)
      @context.auth_object = options[:auth_object]
      @base = Nodes::Grouping.new(@context, options[:grouping] || 'and')
      @scope_args = {}
      build(params.with_indifferent_access)
    end

    def result(opts = {})
      @context.evaluate(self, opts)
    end

    def build(params)
      collapse_multiparameter_attributes!(params).each do |key, value|
        if ['s', 'sorts'].include?(key)
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
      @sorts ||= []
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
      getter_name = method_name.sub(/=$/, '')
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
      ].compact.map { |d| d.join(': ') }.join(', ')
      "Ransack::Search<#{details}>"
    end

    private

    def add_scope(key, args)
      if @context.scope_arity(key) == 1
        @scope_args[key] = args.is_a?(Array) ? args[0] : args
      else
        @scope_args[key] = args
      end
      @context.chain_scope(key, args)
    end

    def collapse_multiparameter_attributes!(attrs)
      attrs.keys.each do |k|
        if k.include?("(")
          real_attribute, position = k.split(/\(|\)/)
          cast = %w(a s i).include?(position.last) ? position.last : nil
          position = position.to_i - 1
          value = attrs.delete(k)
          attrs[real_attribute] ||= []
          attrs[real_attribute][position] = if cast
            (value.blank? && cast == 'i') ? nil : value.send("to_#{cast}")
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
end
