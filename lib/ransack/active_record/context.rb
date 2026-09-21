require 'ransack/context'

module Ransack
  module ActiveRecord
    # The Active Record implementation of Ransack::Context: resolves attribute
    # and association names against a model, builds the joins a search needs
    # on top of whatever joins the relation already has, and turns the search
    # tree into a relation.
    class Context < ::Ransack::Context

      def relation_for(object)
        object.all
      end

      def dialect
        @dialect ||= Dialect.for(@klass)
      end

      # The type a value for this attribute is cast to. Read through the
      # Attributes API rather than the schema column, so that
      # `attribute :starts_at, :datetime` on a date column is honoured (#1028);
      # a column with no attribute override reports its column type.
      def type_for(attr)
        return nil unless attr && attr.valid?
        relation     = attr.arel_attribute.relation
        name         = attr.arel_attribute.name.to_s
        table        = relation.respond_to?(:table_name) ? relation.table_name : relation.name
        schema_cache = self.klass.connection_pool.schema_cache
        unless schema_cache.send(:data_source_exists?, table)
          raise "No table named #{table} exists."
        end
        return nil unless attr.klass.attribute_types.key?(name)

        attr.klass.type_for_attribute(name).type
      end

      def evaluate(search, opts = {})
        viz = Visitor.new
        relation = @object.where(viz.accept(search.base))

        if search.sorts.any?
          relation = relation.except(:order)
          # Rather than applying all of the search's sorts in one fell swoop,
          # as the original implementation does, we apply one at a time.
          #
          # If the sort (returned by the Visitor above) is a symbol, we know
          # that it represents a scope on the model and we can apply that
          # scope.
          #
          # Otherwise, we fall back to the applying the sort with the "order"
          # method as the original implementation did. Actually the original
          # implementation used "reorder," which was overkill since we already
          # have a clean slate after "relation.except(:order)" above.
          viz.accept(search.sorts).each do |scope_or_sort|
            if scope_or_sort.is_a?(Symbol)
              relation = relation.send(scope_or_sort)
            else
              case Ransack.options[:fields_sort_option]
              when :nulls_first
                scope_or_sort = scope_or_sort.direction == :asc ? scope_or_sort.nulls_first : scope_or_sort.nulls_last
              when :nulls_last
                scope_or_sort = scope_or_sort.direction == :asc ? scope_or_sort.nulls_last : scope_or_sort.nulls_first
              when :nulls_always_first
                scope_or_sort = scope_or_sort.nulls_first
              when :nulls_always_last
                scope_or_sort = scope_or_sort.nulls_last
              end

              relation = relation.order(scope_or_sort)
            end
          end
        end

        opts[:distinct] ? relation.distinct : relation
      end

      def attribute_method?(str, klass = @klass)
        exists = false
        if ransackable_attribute?(str, klass) ||
           ransortable_attribute?(str, klass)
          exists = true
        elsif (segments = str.split(Constants::UNDERSCORE)).size > 1
          remainder = []
          found_assoc = nil
          while !found_assoc && remainder.unshift(segments.pop) &&
          segments.size > 0 do
            assoc, poly_class = unpolymorphize_association(
              segments.join(Constants::UNDERSCORE)
              )
            if found_assoc = traversable_association(assoc, poly_class, klass)
              exists = attribute_method?(
                remainder.join(Constants::UNDERSCORE),
                poly_class || found_assoc.klass
                )
            end
          end
        end
        exists
      end

      def table_for(parent)
        parent.table
      end

      def klassify(obj)
        if Class === obj && ::ActiveRecord::Base > obj
          obj
        elsif obj.respond_to? :klass
          obj.klass
        elsif obj.respond_to? :base_klass
          obj.base_klass
        else
          raise ArgumentError, "Don't know how to klassify #{obj}"
        end
      end

      # All dependent Arel::Join nodes used in the search query.
      #
      # This could otherwise be done as `@object.arel.join_sources`, except
      # that ActiveRecord's build_joins sets up its own JoinDependency.
      # This extracts what we need to access the joins using our existing
      # JoinDependency to track table aliases.
      #
      def join_sources
        base, joins = begin
          alias_tracker = @object.alias_tracker
          # The mirror tree covers the relation's own joins and the ones
          # Ransack added at the top level; a join Ransack added under
          # another is rooted at its parent's table and only reachable
          # through its stashed dependency, so those are handed on too. A
          # dependency whose nodes are already in the tree merges with them.
          stashed_joins = (@object.joins_values + @object.left_outer_joins_values).grep(JoinDependency)
          constraints   = @join_dependency.join_constraints(stashed_joins, alias_tracker, @object.references_values)

          [
            Arel::SelectManager.new(@object.table),
            constraints
          ]
        end
        joins.each do |aliased_join|
          base.from(aliased_join)
        end
        base.join_sources
      end

      def alias_tracker
        @join_dependency.send(:alias_tracker)
      end

      def lock_association(association)
        @lock_associations << association
      end

      # Drops a join Ransack added, when a negative condition on a collection
      # replaces it with a correlated subquery. A join the relation already
      # had, or one another condition needs, is locked and stays.
      def remove_association(association)
        return if @lock_associations.include?(association)

        @associations_pot.delete(association)
        @base.children.delete_if { |child| child.equal?(association) }
        @object.left_outer_joins_values = @object.left_outer_joins_values.reject { |jd|
          jd.is_a?(JoinDependency) &&
          jd.instance_variable_get(:@join_root).children.map(&:object_id) == [association.object_id]
        }
      end

      # Build an Arel subquery that selects keys for the top query,
      # drawn from the first join association's foreign_key.
      #
      # Example: for an Article that has_and_belongs_to_many Tags
      #
      #   context = Article.search.context
      #   attribute = Attribute.new(context, "tags_name").tap do |a|
      #     context.bind(a, a.name)
      #   end
      #   context.build_correlated_subquery(attribute.parent).to_sql
      #
      #   # SELECT "articles_tags"."article_id" FROM "articles_tags"
      #   # INNER JOIN "tags" ON "tags"."id" = "articles_tags"."tag_id"
      #   # WHERE "articles_tags"."article_id" = "articles"."id"
      #
      # The WHERE condition on this query makes it invalid by itself,
      # because it is correlated to the primary key on the outer query.
      #
      def build_correlated_subquery(association)
        join_constraints = extract_joins(association)
        join_root = join_constraints.shift
        correlated_key = extract_correlated_key(join_root)
        subquery = Arel::SelectManager.new(association.base_klass)
        subquery.from(join_root.left)
        subquery.project(correlated_key)
        join_constraints.each do |j|
          subquery.join_sources << Arel::Nodes::InnerJoin.new(j.left, j.right)
        end

        # Handle polymorphic associations where correlated_key is an array
        if correlated_key.is_a?(Array)
          # For polymorphic associations, we need to add conditions for both the foreign key and type
          correlated_key.each_with_index do |key, index|
            if index == 0
              # This is the foreign key
              subquery = subquery.where(key.eq(primary_key))
            else
              # This is the type key, which should be equal to the model name
              subquery = subquery.where(key.eq(@klass.name))
            end
          end
        else
          # Original behavior for non-polymorphic associations
          subquery = subquery.where(correlated_key.eq(primary_key))
        end

        subquery
      end

      def primary_key
        @object.table[@object.primary_key]
      end

      private

      def extract_correlated_key(join_root)
        case join_root
        when Arel::Nodes::OuterJoin
          # one of join_root.right/join_root.left is expected to be Arel::Nodes::On
          if join_root.right.is_a?(Arel::Nodes::On)
            extract_correlated_key(join_root.right.expr)
          elsif join_root.left.is_a?(Arel::Nodes::On)
            extract_correlated_key(join_root.left.expr)
          else
            raise 'Ransack encountered an unexpected arel structure'
          end
        when Arel::Nodes::Equality
          pk = primary_key
          if join_root.left.eql?(pk)
            join_root.right
          elsif join_root.right.eql?(pk)
            join_root.left
          else
            nil
          end
        when Arel::Nodes::And
          # And may have multiple children, so we need to check all, not via left/right
          if join_root.children.any?
            join_root.children.each do |child|
              key = extract_correlated_key(child)
              return key if key
            end
          else
            extract_correlated_key(join_root.left) || extract_correlated_key(join_root.right)
          end
        else
          # eg parent was Arel::Nodes::And and the evaluated side was one of
          # Arel::Nodes::Grouping or MultiTenant::TenantEnforcementClause
          nil
        end
      end

      def get_parent_and_attribute_name(str, parent = @base)
        attr_name = nil

        if ransackable_attribute?(str, klassify(parent)) ||
           ransortable_attribute?(str, klassify(parent))
          attr_name = str
        elsif (segments = str.split(Constants::UNDERSCORE)).size > 1
          remainder = []
          found_assoc = nil
          while remainder.unshift(segments.pop) && segments.size > 0 &&
          !found_assoc do
            assoc, klass = unpolymorphize_association(
              segments.join(Constants::UNDERSCORE)
              )
            if found_assoc = traversable_association(assoc, klass, parent)
              join = build_or_find_association(
                found_assoc.name, parent, klass
                )
              parent, attr_name = get_parent_and_attribute_name(
                remainder.join(Constants::UNDERSCORE), join
                )
            end
          end
        end

        [parent, attr_name]
      end

      def get_association(str, parent = @base)
        klass = klassify parent
        ransackable_association?(str, klass) &&
        klass.reflect_on_all_associations.detect { |a| a.name.to_s == str }
      end

      # An association that can actually be walked into. A polymorphic
      # association has no class of its own, so it only counts when the name
      # named one with `_of_Model_type`; otherwise `from_id_or_to_id` would
      # match the `from` association and ask it for a class (#1267).
      def traversable_association(name, polymorphic_class, parent)
        assoc = get_association(name, parent)
        return nil unless assoc
        return nil if assoc.polymorphic? && polymorphic_class.nil?

        assoc
      end

      # == Joins
      #
      # Ransack keeps a JoinDependency of its own, @join_dependency, that
      # mirrors the joins the relation will have once Active Record turns it
      # into SQL: the relation's `joins` and `left_outer_joins`, the join
      # dependencies already stashed on it (an eager load, a previous search)
      # and the associations Ransack adds for this search. The mirror exists
      # so that a condition can be bound to the table alias its join will
      # have.
      #
      # Active Record assigns those aliases only when it builds the query,
      # with a fresh alias tracker and in a fixed order: the relation's own
      # `joins`, then each stashed dependency in `joins_values`, then the
      # `left_outer_joins`, then the dependencies stashed among them, then
      # the eager load (see Relation#build_join_buckets). The mirror seeds
      # its tracker the same way and assigns in the same order, so the two
      # agree. Ransack stashes the joins it adds through `left_outer_joins`,
      # one dependency per association in the order they are added, which is
      # where they fall in that order; a join the relation already has is
      # reused rather than added again.
      #
      # The relation's own joins keep their tree shape in the mirror. A node
      # Ransack adds sits directly under the mirror root whatever its depth,
      # with its parent recorded in @associations_pot, because its stashed
      # dependency is rooted at the parent's table and Active Record renders
      # it on its own; placing it under the parent would render it twice.
      def join_dependency(relation)
        joins = relation.joins_values
        left  = relation.left_outer_joins_values
        eager = relation.eager_loading? ? (relation.eager_load_values | relation.includes_values) : []

        # The tracker seed: string joins and Arel join nodes, as in
        # Relation#build_joins.
        join_nodes   = (joins + left).grep(Arel::Nodes::Join).uniq
        string_joins = joins.grep(String).map(&:strip).uniq
        alias_tracker = relation.alias_tracker(join_nodes + convert_join_strings_to_ast(relation.table, string_joins))

        stashed = joins.grep(JoinDependency)
        eager_jd = stashed.pop if joins.last.is_a?(JoinDependency) && joins.last.base_klass == relation.klass

        mirror = JoinDependency.new(relation.klass, relation.table, named_joins(joins), Arel::Nodes::OuterJoin)
        mirror.instance_variable_set(:@alias_tracker, alias_tracker)
        # `where(assoc: { ... })` records the association name as a reference,
        # and Active Record then aliases that join to the name (#1437).
        mirror.instance_variable_set(:@references, referenced_aliases(relation))
        root = mirror.instance_variable_get(:@join_root)

        root.children.each { |child| adopt(mirror, root, child, Arel::Nodes::InnerJoin) }
        stashed.each { |jd| graft(mirror, jd, jd.instance_variable_get(:@join_type)) }
        graft(mirror, JoinDependency.new(relation.klass, relation.table, named_joins(left), Arel::Nodes::OuterJoin), Arel::Nodes::OuterJoin)
        left.grep(JoinDependency).each { |jd| graft(mirror, jd, jd.instance_variable_get(:@join_type)) }
        graft(mirror, eager_jd, Arel::Nodes::OuterJoin) if eager_jd
        graft(mirror, JoinDependency.new(relation.klass, relation.table, eager, Arel::Nodes::OuterJoin), Arel::Nodes::OuterJoin)

        mirror
      end

      def referenced_aliases(relation)
        relation.references_values.each_with_object({}) do |table_name, references|
          references[table_name.to_sym] = table_name if table_name.is_a?(Arel::Nodes::SqlLiteral)
        end
      end

      def named_joins(values)
        values.select { |join| join.is_a?(Hash) || join.is_a?(Symbol) || join.is_a?(Array) }
      end

      def convert_join_strings_to_ast(table, joins)
        joins.map! { |join| table.create_string_join(Arel.sql(join)) unless join.blank? }
        joins.compact!
        joins
      end

      # Adds the children of a join dependency to the mirror, under the node
      # they hang off, merging with what is already there the way Active
      # Record's JoinDependency#walk does.
      def graft(mirror, jd, join_type)
        root = jd.instance_variable_get(:@join_root)
        parent = mirror_node_for(mirror, root)
        return unless parent

        root.children.each { |child| merge(mirror, parent, child, join_type) }
      end

      def merge(mirror, parent, node, join_type)
        existing = parent.children.find { |child| node.match?(child) }
        if existing
          node.table = existing.table
          node.children.each { |child| merge(mirror, existing, child, join_type) }
        else
          parent.children << node
          adopt(mirror, parent, node, join_type)
        end
      end

      # Assigns the table aliases for a node the relation already joins, and
      # every node under it, and locks them so a negative condition cannot
      # remove a join that belongs to the relation.
      def adopt(mirror, parent, node, join_type)
        @tables_pot[node] = mirror.construct_tables_for_association!(parent, node, join_type)
        @lock_associations << node
        node.children.each { |child| adopt(mirror, node, child, join_type) }
      end

      # The mirror node a stashed dependency's root corresponds to: the
      # mirror root for one rooted at the model, otherwise the node whose
      # table it was built from (Ransack roots a nested join at its parent).
      def mirror_node_for(mirror, root)
        mirror_root = mirror.instance_variable_get(:@join_root)
        return mirror_root if root.base_klass == mirror_root.base_klass && root.table.name == mirror_root.table.name

        mirror_root.detect do |node|
          node != mirror_root && node.base_klass == root.base_klass && node.table && node.table.name == root.table.name
        end
      end

      def parent_of(node)
        @associations_pot[node] ||
          @base.detect { |candidate| candidate.children.any? { |child| child.equal?(node) } }
      end

      # The nodes that hang off a parent: the relation's own joins under it,
      # plus the ones Ransack added under it.
      def children_of(parent)
        parent.children + @associations_pot.select { |_node, node_parent| node_parent.equal?(parent) }.keys
      end

      def build_or_find_association(name, parent = @base, klass = nil)
        find_association(name, parent, klass) or build_association(name, parent, klass)
      end

      def find_association(name, parent = @base, klass = nil)
        children_of(parent).detect do |assoc|
          assoc.reflection.name == name && assoc.table &&
          (!klass || assoc.reflection.klass == klass)
        end
      end

      def build_association(name, parent = @base, klass = nil)
        # Rooted at the parent's table so that, when Active Record builds
        # the query, the join hangs off whatever alias the parent has there.
        jd = JoinDependency.new(
          parent.base_klass,
          parent.table,
          Join.new(name, @join_type, klass),
          @join_type
        )
        found_association = jd.instance_variable_get(:@join_root).children.last

        @associations_pot[found_association] = parent
        @base.children.push found_association
        @tables_pot[found_association] = @join_dependency.construct_tables_for_association!(parent, found_association, @join_type)

        # Stashed on the relation for Active Record to render; see the note
        # on ordering above join_dependency.
        @object = @object.left_outer_joins(jd)
        found_association
      end

      def extract_joins(association)
        parent = parent_of(association)
        join_constraints = association.join_constraints_with_tables(
                             parent.table,
                             parent.base_klass,
                             Arel::Nodes::OuterJoin,
                             @join_dependency.instance_variable_get(:@alias_tracker),
                             @tables_pot[association]
                           )
        join_constraints.to_a.flatten
      end
    end
  end
end

# Resolve a Context for a model class or a relation. Registered here rather
# than hard-coded in Ransack::Context so another ORM integration can register
# its own without patching Ransack.
Ransack::Context.register do |object, options|
  # Active Record may not be loaded at all when another ORM's resolver is
  # the one that should answer.
  next unless defined?(::ActiveRecord::Base)

  case object
  when Class
    Ransack::ActiveRecord::Context.new(object, options) if object < ::ActiveRecord::Base
  when ::ActiveRecord::Relation
    Ransack::ActiveRecord::Context.new(object, options)
  end
end
