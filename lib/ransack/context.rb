require 'ransack/visitor'

module Ransack
  class Context
    attr_reader :search, :object, :klass, :base, :engine, :arel_visitor
    attr_accessor :auth_object, :search_key
    attr_reader :arel_visitor

    class << self

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

      def for(object, options = {})
        context =
          if Class === object
            for_class(object, options)
          else
            for_object(object, options)
          end
        context or raise ArgumentError,
          "Don't know what context to use for #{object}"
      end

    end # << self

    def initialize(object, options = {})
      @object = relation_for(object)
      @klass = @object.klass
      @join_dependency = join_dependency(@object)
      @join_type = options[:join_type] || Polyamorous::OuterJoin
      @search_key = options[:search_key] || Ransack.options[:search_key]
      @associations_pot = {}
      @tables_pot = {}
      @lock_associations = []

      @base = @join_dependency.instance_variable_get(:@join_root)
    end

    def bind_pair_for(key)
      @bind_pairs ||= {}

      @bind_pairs[key] ||= begin
        parent, attr_name = get_parent_and_attribute_name(key.to_s)
        [parent, attr_name] if parent && attr_name
      end
    end

    def klassify(obj)
      if Class === obj && ::ActiveRecord::Base > obj
        obj
      elsif obj.respond_to? :klass
        obj.klass
      else
        raise ArgumentError, "Don't know how to klassify #{obj.inspect}"
      end
    end

    # Convert a string representing a chain of associations and an attribute
    # into the attribute itself
    def contextualize(str)
      parent, attr_name = bind_pair_for(str)
      table_for(parent)[attr_name]
    end

    def chain_scope(scope, args)
      return unless @klass.method(scope) && args != false
      @object = if scope_arity(scope) < 1 && args == true
                  @object.public_send(scope)
                else
                  @object.public_send(scope, *args)
                end
    end

    def scope_arity(scope)
      @klass.method(scope).arity
    end

    def bind(object, str)
      return nil unless str
      object.parent, object.attr_name = bind_pair_for(str)
    end

    def traverse(str, base = @base)
      str ||= ''.freeze
      segments = str.split(Constants::UNDERSCORE)
      unless segments.empty?
        remainder = []
        found_assoc = nil
        until found_assoc || segments.empty?
          # Strip the _of_Model_type text from the association name, but hold
          # onto it in klass, for use as the next base
          assoc, klass = unpolymorphize_association(
            segments.join(Constants::UNDERSCORE)
          )
          if found_assoc = get_association(assoc, base)
            base = traverse(
              remainder.join(Constants::UNDERSCORE), klass || found_assoc.klass
            )
          end

          remainder.unshift segments.pop
        end
        unless found_assoc
          raise(UntraversableAssociationError,
                "No association matches #{str}")
        end
      end

      klassify(base)
    end

    def association_path(str, base = @base)
      base = klassify(base)
      str ||= ''.freeze
      path = []
      segments = str.split(Constants::UNDERSCORE)
      association_parts = []
      unless segments.empty?
        while !segments.empty? &&
              !base.columns_hash[segments.join(Constants::UNDERSCORE)] &&
              association_parts << segments.shift
          assoc, klass = unpolymorphize_association(
            association_parts.join(Constants::UNDERSCORE)
          )
          next unless found_assoc = get_association(assoc, base)
          path += association_parts
          association_parts = []
          base = klassify(klass || found_assoc)
        end
      end

      path.join(Constants::UNDERSCORE)
    end

    def unpolymorphize_association(str)
      if (match = str.match(/_of_([^_]+?)_type$/))
        [match.pre_match, Kernel.const_get(match.captures.first)]
      else
        [str, nil]
      end
    end

    def ransackable_alias(str)
      klass._ransack_aliases.fetch(str, str)
    end

    def ransackable_attribute?(str, klass)
      klass.ransackable_attributes(auth_object).include?(str) ||
        klass.ransortable_attributes(auth_object).include?(str)
    end

    def ransackable_association?(str, klass)
      klass.ransackable_associations(auth_object).include? str
    end

    def ransackable_scope?(str, klass)
      klass.ransackable_scopes(auth_object).any? { |s| s.to_sym == str.to_sym }
    end

    def ransackable_scope_skip_sanitize_args?(str, klass)
      klass.ransackable_scopes_skip_sanitize_args.any? { |s| s.to_sym == str.to_sym }
    end

    def searchable_attributes(str = ''.freeze)
      traverse(str).ransackable_attributes(auth_object)
    end

    def sortable_attributes(str = ''.freeze)
      traverse(str).ransortable_attributes(auth_object)
    end

    def searchable_associations(str = ''.freeze)
      traverse(str).ransackable_associations(auth_object)
    end
  end
end
