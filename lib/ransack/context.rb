module Ransack
  class Context
    attr_reader :search, :object, :klass, :base, :engine, :arel_visitor

    class << self

      def for(object)
        context = Class === object ? for_class(object) : for_object(object)
        context or raise ArgumentError, "Don't know what context to use for #{object}"
      end

      def for_class(klass)
        if klass < ActiveRecord::Base
          Adapters::ActiveRecord::Context.new(klass)
        end
      end

      def for_object(object)
        case object
        when ActiveRecord::Relation
          Adapters::ActiveRecord::Context.new(object.klass)
        end
      end

      def can_accept?(object)
        method_defined? DISPATCH[object.class]
      end

    end

    def initialize(object)
      @object = object.scoped
      @klass = @object.klass
      @join_dependency = join_dependency(@object)
      @base = @join_dependency.join_base
      @engine = @base.arel_engine
      @arel_visitor = Arel::Visitors.visitor_for @engine
      @default_table = Arel::Table.new(@base.table_name, :as => @base.aliased_table_name, :engine => @engine)
      @attributes = Hash.new do |hash, key|
        if attribute = get_attribute(key.to_s)
          hash[key] = attribute
        end
      end
    end

    # Convert a string representing a chain of associations and an attribute
    # into the attribute itself
    def contextualize(str)
      @attributes[str]
    end

    def traverse(str, base = @base)
      str ||= ''

      if (segments = str.split(/_/)).size > 0
        association_parts = []
        found_assoc = nil
        while !found_assoc && segments.size > 0 && association_parts << segments.shift do
          if found_assoc = get_association(association_parts.join('_'), base)
            base = traverse(segments.join('_'), found_assoc.klass)
          end
        end
        raise ArgumentError, "No association matches #{str}" unless found_assoc
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
          if found_assoc = get_association(association_parts.join('_'), base)
            path += association_parts
            association_parts = []
            base = klassify(found_assoc)
          end
        end
      end

      path.join('_')
    end

    def searchable_columns(str = '')
      traverse(str).column_names
    end

    def accept(object)
      visit(object)
    end

    def can_accept?(object)
      respond_to? DISPATCH[object.class]
    end

    def visit_Array(object)
      object.map {|o| accept(o)}.compact
    end

    def visit_Ransack_Nodes_Condition(object)
      object.apply_predicate if object.valid?
    end

    def visit_Ransack_Nodes_And(object)
      nodes = object.values.map {|o| accept(o)}.compact
      return nil unless nodes.size > 0

      if nodes.size > 1
        Arel::Nodes::Grouping.new(Arel::Nodes::And.new(nodes))
      else
        nodes.first
      end
    end

    def visit_Ransack_Nodes_Sort(object)
      object.attr.send(object.dir) if object.valid?
    end

    def visit_Ransack_Nodes_Or(object)
      nodes = object.values.map {|o| accept(o)}.compact
      return nil unless nodes.size > 0

      if nodes.size > 1
        nodes.inject(&:or)
      else
        nodes.first
      end
    end

    def quoted?(object)
      case object
      when Arel::Nodes::SqlLiteral, Bignum, Fixnum
        false
      else
        true
      end
    end

    def visit(object)
      send(DISPATCH[object.class], object)
    end

    DISPATCH = Hash.new do |hash, klass|
      hash[klass] = "visit_#{klass.name.gsub('::', '_')}"
    end

  end
end