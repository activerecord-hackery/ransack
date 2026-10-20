module Ransack
  module ActiveRecord
    # Prepended to ActiveRecord::Associations::JoinDependency.
    #
    # Teaches the join tree about Join nodes (join type, polymorphic class),
    # and exposes the table aliasing Ransack needs to add one association at a
    # time to a relation that may already carry joins of its own.
    module JoinDependencyExtensions
      # The table aliases a search counted on for one association it added,
      # by position in its reflection chain (nil where the name could not be
      # kept), and the join that ended up with them; see #pin_search_tables.
      SearchPin = Struct.new(:name, :tables, :top_level, :joined_by, :joined_as)

      # Set on a dependency Ransack stashes on a relation for an association
      # a search added, and whether the search counted the relation's eager
      # load first.
      attr_accessor :added_by_search, :after_eager_load

      # Replaces ActiveRecord::Associations::JoinDependency#build
      def build(associations, base_klass)
        associations.map do |name, right|
          if name.is_a? Join
            reflection = find_reflection base_klass, name.name
            reflection.check_validity!
            reflection.check_eager_loadable!

            klass = if reflection.polymorphic?
              name.klass || base_klass
            else
              reflection.klass
            end
            JoinAssociation.new(reflection, build(right, klass), name.klass, name.type)
          else
            reflection = find_reflection base_klass, name
            reflection.check_validity!
            reflection.check_eager_loadable!

            if reflection.polymorphic?
              raise ::ActiveRecord::EagerLoadPolymorphicError.new(reflection)
            end
            JoinAssociation.new(reflection, build(right, reflection.klass))
          end
        end
      end

      def join_constraints(joins_to_add, alias_tracker, references)
        @alias_tracker = alias_tracker
        @joined_tables = {}
        @references = {}

        references.each do |table_name|
          @references[table_name.to_sym] = table_name if table_name.is_a?(String)
        end

        pin_search_tables(joins_to_add)

        joins = make_join_constraints(join_root, join_type)

        joins.concat eager_load_first(joins_to_add.to_a).flat_map { |oj|
          if oj.added_by_search
            search_join_constraints(oj)
          elsif top_level?(oj)
            walk join_root, oj.join_root, oj.join_type
          else
            make_join_constraints(oj.join_root, oj.join_type)
          end
        }
      end

      # A search binds its conditions to the table aliases its joins are
      # going to have, and roots a nested join at its parent's alias, all
      # worked out from the relation it searched. A join added to the result
      # afterwards (`result.joins(:target_person)`) renders first, and would
      # take a name one of the search's joins was counting on, moving its
      # conditions and nested joins onto the new join (#1776).
      #
      # So each association a search added keeps its aliases, those of a
      # through association's intermediate tables included: the names are
      # reserved before anything is joined, and a join of the same
      # association added afterwards takes them over and stands in for the
      # search's join; any other join is aliased around them. A name that a
      # string or Arel join already claims cannot be kept; the joins nested
      # under that association then follow the alias it does get.
      def pin_search_tables(joins)
        @search_pins = {}.compare_by_identity
        aliases = alias_tracker.aliases
        joins.each do |jd|
          next unless jd.added_by_search

          top_level = top_level?(jd)
          jd.join_root.children.each do |node|
            next if node.own_tables.blank?

            tables = node.own_tables.map do |table|
              next unless aliases[table.name].zero?

              aliases[table.name] = 1
              table
            end
            @search_pins[node] = SearchPin.new(node.own_tables.first.name, tables, top_level)
          end
        end
      end

      def construct_tables_for_association!(join_root, association, join_type = self.join_type)
        tables = table_aliases_for(join_root, association, join_type)
        association.table = tables.first
        tables
      end

      private

      # Active Record renders the eager load last, after every
      # `left_outer_joins` dependency. A search of a relation that eager
      # loads counted the eager load's aliases before those of the joins it
      # added, and may have rooted one of them at an eager-loaded join
      # (#1767), so the eager load goes back in front of the first of them.
      def eager_load_first(joins)
        index = joins.index(&:after_eager_load)
        joins.insert(index, joins.pop) if index && !joins.last.added_by_search
        joins
      end

      def top_level?(jd)
        join_root.match?(jd.join_root) && join_root.table.name == jd.join_root.table.name
      end

      # The pin for a node about to be joined: the search's own node, or a
      # join of the same association under the root, which stands in for it.
      # Each pin goes to whichever of them is joined first.
      def take_search_pin(parent, node)
        return unless @search_pins

        pin = @search_pins[node]
        if pin.nil? && parent.equal?(join_root)
          pin = @search_pins.find { |search_node, p| p.top_level && !p.joined_by && search_node.match?(node) }&.last
        end
        return if pin.nil? || pin.joined_by

        pin.joined_by = node
        pin
      end

      # A search's join: left out when a join added afterwards stands in for
      # it, and a nested one hung off the alias its parent actually got.
      def search_join_constraints(jd)
        root = jd.join_root
        if top_level?(jd)
          root.children.flat_map do |node|
            joined_by = @search_pins[node]&.joined_by
            if (joined_by && !joined_by.equal?(node)) || join_root.children.any? { |child| node.match?(child) }
              []
            else
              make_constraints(join_root, node, jd.join_type)
            end
          end
        else
          parent = @search_pins.each_value.find { |pin| pin.name == root.table.name && pin.joined_as }
          if parent && parent.joined_as.name != root.table.name
            root = JoinDependency::JoinBase.new(root.base_klass, parent.joined_as, root.children)
          end
          make_join_constraints(root, jd.join_type)
        end
      end

      # Replaces ActiveRecord::Associations::JoinDependency#make_constraints,
      # to join an association a search added with the alias it pinned.
      def make_constraints(parent, child, join_type)
        foreign_table = parent.table
        foreign_klass = parent.base_klass
        pin = nil
        child.join_constraints(foreign_table, foreign_klass, join_type, alias_tracker) do |reflection, remaining_reflection_chain|
          table, terminated = @joined_tables[remaining_reflection_chain]
          root = reflection == child.reflection
          index = child.reflection.chain.size - remaining_reflection_chain.size
          pin = take_search_pin(parent, child) if root

          if table && (!root || !terminated) && reusable?(table, pin, index)
            @joined_tables[remaining_reflection_chain] = [table, root] if root
            pin.joined_as = table if pin && root
            next table, true
          end

          table = aliased_table_for(parent, reflection, index, pin)
          pin.joined_as = table if pin && root

          @joined_tables[remaining_reflection_chain] ||= [table, root] if join_type == Arel::Nodes::OuterJoin
          table
        end.concat child.children.flat_map { |c| make_constraints(child, c, join_type) }
      end

      # The tables for a node's reflection chain, assigned the way Active
      # Record's JoinDependency#make_constraints assigns them, so that the
      # aliases Ransack binds conditions to are the ones the query will have.
      # Once a chain tail has been joined before, Active Record stops
      # aliasing and reuses that join; the remaining positions here are
      # filled from the same record for the correlated-subquery builder.
      def table_aliases_for(parent, node, join_type)
        @joined_tables ||= {}
        chain = node.reflection.chain
        terminated_at = nil
        pin = nil

        chain.each_with_index.map { |reflection, index|
          remaining = chain[index..]
          table, terminated = @joined_tables[remaining]
          root = reflection == node.reflection
          pin = take_search_pin(parent, node) if root && !terminated_at

          if terminated_at
            table || reflection.klass.arel_table
          elsif table && (!root || !terminated) && reusable?(table, pin, index)
            @joined_tables[remaining] = [table, root] if root
            pin.joined_as = table if pin && root
            terminated_at = index
            table
          else
            table = aliased_table_for(parent, reflection, index, pin)
            pin.joined_as = table if pin && root
            @joined_tables[remaining] ||= [table, root] if join_type == Arel::Nodes::OuterJoin
            table
          end
        }.tap { |tables| node.own_tables = tables.first(terminated_at || tables.size) }
      end

      # Whether a table an earlier join already provides can stand in for
      # one position of a node's reflection chain. Not when a search pinned
      # another alias there: the search's conditions name that one, so the
      # node is joined on its own (#1776).
      def reusable?(table, pin, index)
        pinned = pin&.tables&.at(index)
        pinned.nil? || pinned.name == table.name
      end

      # A new table for one position of a node's reflection chain: the one a
      # search pinned for it, or the next alias Active Record would give.
      def aliased_table_for(parent, reflection, index, pin)
        return pin.tables[index] if pin&.tables&.at(index)

        table_name = @references && @references[reflection.name.to_sym]&.to_s
        alias_tracker.aliased_table_for(reflection.klass.arel_table, table_name) do
          name = reflection.alias_candidate(parent.table_name)
          index.zero? ? name : "#{name}_join"
        end
      end

      module ClassMethods
        # Prepended before ActiveRecord::Associations::JoinDependency#walk_tree
        #
        def walk_tree(associations, hash)
          case associations
          when TreeNode
            associations.add_to_tree(hash)
          when Hash
            associations.each do |k, v|
              cache =
                if TreeNode === k
                  k.add_to_tree(hash)
                else
                  hash[k] ||= {}
                end
              walk_tree(v, cache)
            end
          else
            super(associations, hash)
          end
        end
      end

    end
  end
end
