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
      params ||= {}
      @context = Context.for(object, options)
      @context.auth_object = options[:auth_object]
      @base = Nodes::Grouping.new(@context, 'and')
      build(params.with_indifferent_access)
    end

    def result(opts = {})
      @context.evaluate(self, opts)
    end

    def build(params)
      collapse_multiparameter_attributes!(params).each do |key, value|
        case key
        when 's', 'sorts'
          send("#{key}=", value)
        else
          base.send("#{key}=", value) if base.attribute_method?(key)
        end
      end
      self
    end

    def sorts=(args)
      case args
      when Array
        args.each do |sort|
          sort = Nodes::Sort.extract(@context, sort)
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
        raise ArgumentError, "Invalid argument (#{args.class}) supplied to sorts="
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

    def respond_to?(method_id, include_private = false)
      super or begin
        method_name = method_id.to_s
        writer = method_name.sub!(/\=$/, '')
        base.attribute_method?(method_name) ? true : false
      end
    end

    def method_missing(method_id, *args)
      method_name = method_id.to_s
      writer = method_name.sub!(/\=$/, '')
      if base.attribute_method?(method_name)
        base.send(method_id, *args)
      else
        super
      end
    end

    def inspect
      "Ransack::Search<class: #{klass.name}, base: #{base.inspect}>"
    end

    private

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
