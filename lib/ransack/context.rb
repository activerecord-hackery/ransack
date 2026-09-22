require 'ransack/visitor'

module Ransack
  class Context
    attr_reader :search, :object, :klass, :base, :engine, :arel_visitor
    attr_accessor :auth_object, :search_key, :ignore_unknown_conditions

    class << self

      # An ORM integration registers a block that returns a Context for the
      # objects it understands and nil for anything else. Ransack ships the
      # Active Record integration (see Ransack::ActiveRecord::Context); an
      # integration for another ORM registers its own resolver here.
      def register(&resolver)
        Ransack::Context.resolvers << resolver
      end

      def resolvers
        @resolvers ||= []
      end

      def for(object, options = {})
        Ransack::Context.resolvers.each do |resolver|
          context = resolver.call(object, options)
          return context if context
        end
        raise ArgumentError, "Don't know what context to use for #{object}"
      end

    end # << self

    # Unknown attributes, predicates and combinators raise rather than being
    # ignored when either the global option or this search's own option says so.
    def strict_conditions?
      !Ransack.options[:ignore_unknown_conditions] || ignore_unknown_conditions == false
    end

    def initialize(object, options = {})
      @object = relation_for(object)
      @klass = @object.klass
      @join_type = options[:join_type] || Arel::Nodes::OuterJoin
      @search_key = options[:search_key] || Ransack.options[:search_key]
      @associations_pot = {}
      @tables_pot = {}
      @lock_associations = []
      @join_dependency = join_dependency(@object)

      @base = @join_dependency.instance_variable_get(:@join_root)
    end

    # False when a key has more `_`-separated segments than Ransack will
    # parse. The attribute / association / predicate parsing that follows is
    # superlinear in the segment count and the key is attacker-controlled, so
    # an over-long key is treated as unknown rather than parsed
    # (GHSA-j3f8-w227-4hh8).
    def key_within_depth_limit?(key)
      key.to_s.count(Constants::UNDERSCORE) <= Constants::MAX_KEY_DEPTH
    end

    def bind_pair_for(key)
      @bind_pairs ||= {}

      @bind_pairs[key] ||= begin
        parent, attr_name = get_parent_and_attribute_name(key.to_s)
        [parent, attr_name] if parent && attr_name
      end
    end

    # The SQL dialect the search will be rendered in, for the few places
    # where generated SQL differs by database. See
    # Ransack::ActiveRecord::Dialect for the questions it answers.
    def dialect
      raise NotImplementedError, "#{self.class} must implement #dialect"
    end

    # The model class behind a search object, an association node or a class.
    # Each ORM integration decides what counts as a model, so this is defined
    # on the integration's Context subclass.
    def klassify(obj)
      raise NotImplementedError, "#{self.class} must implement #klassify"
    end

    # Convert a string representing a chain of associations and an attribute
    # into the attribute itself
    def contextualize(str)
      parent, attr_name = bind_pair_for(str)
      table_for(parent)[attr_name]
    end

    # A bare `false` normally means "this checkbox was not ticked" and the
    # scope is not applied at all. A scope listed in
    # `ransackable_scopes_skip_sanitize_args` has asked to see its values as
    # given, so `false` reaches it like any other value and it can be driven
    # by a yes / no / any select (#1375).
    def chain_scope(scope, args)
      return unless @klass.method(scope)
      return if args == false && !ransackable_scope_skip_sanitize_args?(scope, @klass)

      @object = if scope_arity(scope) < 1 && args == true
                  @object.public_send(scope)
                elsif scope_arity(scope) == 1 && args.is_a?(Array)
                  # For scopes with arity 1, pass the array as a single argument instead of splatting
                  @object.public_send(scope, args)
                else
                  @object.public_send(scope, *args)
                end
    end

    def scope_arity(scope)
      @klass.method(scope).arity
    end

    def sanitize_scope_args(key, args)
      if Ransack.options[:sanitize_scope_args] && !ransackable_scope_skip_sanitize_args?(key, object)
        cast_scope_args(args)
      else
        args
      end
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
      return ''.freeze unless key_within_depth_limit?(str)

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
          # A polymorphic association is only complete once its
          # `_of_Model_type` suffix has been consumed; matching on the bare
          # name would ask the reflection for a class it cannot know (#1557).
          next if found_assoc.polymorphic? && klass.nil?
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
      klass._ransack_aliases.fetch(str, klass._ransack_aliases.fetch(str.to_sym, str))
    end

    # Expands every `ransack_alias` in a condition name: the whole name, each
    # `_or_` / `_and_` segment of a compound, and an alias defined on an
    # associated model and reached through an association path
    # (`person_term` when Person aliases `term`). An alias that expands to a
    # compound is joined with that compound's own combinator, so
    # `term_or_daddy` with `term => name_or_email` becomes
    # `name_or_email_or_parent_name`. Returns the name unchanged when it
    # holds no alias.
    def resolve_aliases(str)
      return str.to_s unless key_within_depth_limit?(str)

      whole = resolve_alias_segment(str)
      return whole if whole != str
      # A name that is an attribute in its own right is never split, even if
      # it contains a combinator (a column called `true_or_false`).
      return str if attribute_method?(str)

      segments = str.split(/_and_|_or_/)
      resolved = segments.map { |segment| resolve_alias_segment(segment) }
      return str if resolved == segments

      combinator = str[/_(or|and)_/, 1] || Constants::OR
      resolved.join("_#{combinator}_")
    end

    def ransackable_attribute?(str, klass)
      klass.ransackable_attributes(auth_object).any? { |s| s.to_sym == str.to_sym }
    end

    def ransortable_attribute?(str, klass)
      klass.ransortable_attributes(auth_object).any? { |s| s.to_sym == str.to_sym }
    end

    def ransackable_association?(str, klass)
      klass.ransackable_associations(auth_object).any? { |s| s.to_sym == str.to_sym }
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

    private

    def resolve_alias_segment(segment)
      target = ransackable_alias(segment)
      return target if target != segment

      path = association_path(segment)
      return segment if path.blank?

      remainder = segment.delete_prefix("#{path}_")
      associated = traverse(path)
      target = associated._ransack_aliases.fetch(remainder, associated._ransack_aliases.fetch(remainder.to_sym, remainder))
      return segment if target == remainder
      # The target may itself be one attribute whose name contains a
      # combinator (`terms_and_conditions`); it is prefixed whole.
      return "#{path}_#{target}" if ransackable_attribute?(target, associated)

      # Prefix every attribute of the alias's target with the path.
      target.gsub(/(\A|_and_|_or_)/) { "#{$1}#{path}_" }
    end

    def cast_scope_args(args)
      if args.is_a?(Array)
        args = args.map(&method(:cast_scope_args))
      end

      if Constants::TRUE_VALUES.include? args
        true
      elsif Constants::FALSE_VALUES.include? args
        false
      else
        args
      end
    end
  end
end
