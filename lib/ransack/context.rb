require 'ransack/visitor'

module Ransack
  class Context
    attr_reader :search, :object, :klass, :base, :engine, :arel_visitor
    attr_accessor :auth_object, :search_key

    class << self

      def for(object, options = {})
        context = Class === object ? for_class(object, options) : for_object(object, options)
        context or raise ArgumentError, "Don't know what context to use for #{object}"
      end

      def for_class(klass, options = {})
        if klass < ActiveRecord::Base
          Adapters::ActiveRecord::Context.new(klass, options)
        end
      end

      def for_object(object, options = {})
        case object
        when ActiveRecord::Relation
          Adapters::ActiveRecord::Context.new(object.klass, options)
        end
      end

    end

    def initialize(object, options = {})
      @object = relation_for(object)
      @klass = @object.klass
      @join_dependency = join_dependency(@object)
      @join_type = options[:join_type] || Arel::OuterJoin
      @search_key = options[:search_key] || Ransack.options[:search_key]
      @base = @join_dependency.join_base
      @engine = @base.arel_engine
      @default_table = Arel::Table.new(@base.table_name, :as => @base.aliased_table_name, :engine => @engine)
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
      elsif obj.respond_to? :active_record # rails 3
        obj.active_record
      elsif obj.respond_to? :base_klass    # rails 4
        obj.base_klass
      else
        raise ArgumentError, "Don't know how to klassify #{obj}"
      end
    end

    # Convert a string representing a chain of associations and an attribute
    # into the attribute itself
    def contextualize(str)
      parent, attr_name = @bind_pairs[str]
      table_for(parent)[attr_name]
    end

    def bind(object, str)
      object.parent, object.attr_name = @bind_pairs[str]
    end

    def traverse(str, base = @base)
      str ||= ''

      if (segments = str.split(/_/)).size > 0
        remainder = []
        found_assoc = nil
        while !found_assoc && segments.size > 0 do
          # Strip the _of_Model_type text from the association name, but hold
          # onto it in klass, for use as the next base
          assoc, klass = unpolymorphize_association(segments.join('_'))
          if found_assoc = get_association(assoc, base)
            base = traverse(remainder.join('_'), klass || found_assoc.klass)
          end

          remainder.unshift segments.pop
        end
        raise UntraversableAssociationError, "No association matches #{str}" unless found_assoc
      end

      klassify(base)
    end

    def association_path(str, base = @base)
      base = klassify(base)
      str ||= ''
      path = []
      segments = str.split(/_/)
      association_parts = []
      if (segments = str.split(/_/)).size > 0
        while segments.size > 0 && !base.columns_hash[segments.join('_')] && association_parts << segments.shift do
          assoc, klass = unpolymorphize_association(association_parts.join('_'))
          if found_assoc = get_association(assoc, base)
            path += association_parts
            association_parts = []
            base = klassify(klass || found_assoc)
          end
        end
      end

      path.join('_')
    end

    def unpolymorphize_association(str)
      if (match = str.match(/_of_([^_]+?)_type$/))
        [match.pre_match, Kernel.const_get(match.captures.first)]
      else
        [str, nil]
      end
    end

    def ransackable_attribute?(str, klass)
      klass.ransackable_attributes(auth_object).include? str
    end

    def ransackable_association?(str, klass)
      klass.ransackable_associations(auth_object).include? str
    end

    def searchable_attributes(str = '')
      traverse(str).ransackable_attributes(auth_object)
    end

    def searchable_associations(str = '')
      traverse(str).ransackable_associations(auth_object)
    end

  end
end
