require 'ransack/visitor'

module Ransack
  class Context
    # attr_reader :arel_visitor

    class << self

      def for_class(klass, options = {})
        if klass.ancestors.include?(::Mongoid::Document)
          Adapters::Mongoid::Context.new(klass, options)
        end
      end

      def for_object(object, options = {})
        case object
        when ActiveRecord::Relation
          Adapters::ActiveRecord::Context.new(object.klass, options)
        end
      end

    end # << self

    def initialize(object, options = {})
      @object = relation_for(object)
      @klass = @object.klass
      # @join_dependency = join_dependency(@object)
      # @join_type = options[:join_type] || Arel::OuterJoin
      @search_key = options[:search_key] || Ransack.options[:search_key]

      @base = @object.klass
      # @engine = @base.arel_engine

      # @default_table = Arel::Table.new(
      #   @base.table_name, :as => @base.aliased_table_name, :engine => @engine
      #   )
      @bind_pairs = Hash.new do |hash, key|
        parent, attr_name = get_parent_and_attribute_name(key.to_s)
        if parent && attr_name
          hash[key] = [parent, attr_name]
        end
      end
    end

    def klassify(obj)
      if Class === obj && ::ActiveRecord::Base > obj
        obj
      elsif obj.respond_to? :klass
        obj.klass
      elsif obj.respond_to? :active_record  # Rails 3
        obj.active_record
      elsif obj.respond_to? :base_klass     # Rails 4
        obj.base_klass
      else
        raise ArgumentError, "Don't know how to klassify #{obj.inspect}"
      end
    end

  end
end
