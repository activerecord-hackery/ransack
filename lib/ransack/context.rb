require 'ransack/visitor'
Ransack::Adapters.object_mapper.require_context

module Ransack
  class Context
    attr_reader :search, :object, :klass, :base, :engine, :arel_visitor
    attr_accessor :auth_object, :search_key

    class << self

      def for_class(klass, options = {})
        raise "not implemented"
      end

      def for_object(object, options = {})
        raise "not implemented"
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
      raise "not implemented"
    end

    def klassify(obj)
      raise "not implemented"
    end

    # Convert a string representing a chain of associations and an attribute
    # into the attribute itself
    def contextualize(str)
      parent, attr_name = @bind_pairs[str]
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
      object.parent, object.attr_name = @bind_pairs[str]
    end

    def traverse(str, base = @base)
      str ||= ''.freeze

      if (segments = str.split(/_/)).size > 0
        remainder = []
        found_assoc = nil
        while !found_assoc && segments.size > 0 do
          # Strip the _of_Model_type text from the association name, but hold
          # onto it in klass, for use as the next base
          assoc, klass = unpolymorphize_association(
            segments.join('_'.freeze)
            )
          if found_assoc = get_association(assoc, base)
            base = traverse(
              remainder.join('_'.freeze), klass || found_assoc.klass
              )
          end

          remainder.unshift segments.pop
        end
        raise UntraversableAssociationError,
          "No association matches #{str}" unless found_assoc
      end

      klassify(base)
    end

    def association_path(str, base = @base)
      base = klassify(base)
      str ||= ''.freeze
      path = []
      segments = str.split(/_/)
      association_parts = []
      if (segments = str.split(/_/)).size > 0
        while segments.size > 0 &&
        !base.columns_hash[segments.join(Constants::UNDERSCORE)] &&
        association_parts << segments.shift do
          assoc, klass = unpolymorphize_association(
            association_parts.join(Constants::UNDERSCORE)
            )
          if found_assoc = get_association(assoc, base)
            path += association_parts
            association_parts = []
            base = klassify(klass || found_assoc)
          end
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
      klass.ransackable_scopes(auth_object).any? { |s| s.to_s == str }
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
