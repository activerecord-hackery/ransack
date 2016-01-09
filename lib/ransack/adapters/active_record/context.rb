require 'ransack/context'
require 'ransack/adapters/active_record/compat'
require 'polyamorous'

module Ransack
  module Adapters
    module ActiveRecord
      class Context < ::Ransack::Context

        # Because the AR::Associations namespace is insane
        if defined? ::ActiveRecord::Associations::JoinDependency
          JoinDependency = ::ActiveRecord::Associations::JoinDependency
        end

        def initialize(object, options = {})
          super
          @arel_visitor = @engine.connection.visitor
        end

        def relation_for(object)
          object.all
        end

        def type_for(attr)
          return nil unless attr && attr.valid?
          name         = attr.arel_attribute.name.to_s
          table        = attr.arel_attribute.relation.table_name
          schema_cache = @engine.connection.schema_cache
          unless schema_cache.send(database_table_exists?, table)
            raise "No table named #{table} exists."
          end
          schema_cache.columns_hash(table)[name].type
        end

        def evaluate(search, opts = {})
          viz = Visitor.new
          relation = @object.where(viz.accept(search.base))
          if search.sorts.any?
            relation = relation.except(:order).reorder(viz.accept(search.sorts))
          end
          opts[:distinct] ? relation.distinct : relation
        end

        def attribute_method?(str, klass = @klass)
          exists = false
          if ransackable_attribute?(str, klass)
            exists = true
          elsif (segments = str.split(/_/)).size > 1
            remainder = []
            found_assoc = nil
            while !found_assoc && remainder.unshift(segments.pop) &&
            segments.size > 0 do
              assoc, poly_class = unpolymorphize_association(
                segments.join(Constants::UNDERSCORE)
                )
              if found_assoc = get_association(assoc, klass)
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

        if ::ActiveRecord::VERSION::STRING >= Constants::RAILS_4_1

          def join_associations
            raise NotImplementedError,
            "ActiveRecord 4.1 and later does not use join_associations. Use join_sources."
          end

          # All dependent Arel::Join nodes used in the search query.
          #
          # This could otherwise be done as `@object.arel.join_sources`, except
          # that ActiveRecord's build_joins sets up its own JoinDependency.
          # This extracts what we need to access the joins using our existing
          # JoinDependency to track table aliases.
          #
          def join_sources
            base, joins =
            if ::ActiveRecord::VERSION::MAJOR >= 5
              [
                Arel::SelectManager.new(@object.table),
                @join_dependency.join_constraints(@object.joins_values, @join_type)
              ]
            else
              [
                Arel::SelectManager.new(@object.engine, @object.table),
                @join_dependency.join_constraints(@object.joins_values)
              ]
            end
            joins.each do |aliased_join|
              base.from(aliased_join)
            end
            base.join_sources
          end

        else

          # All dependent JoinAssociation items used in the search query.
          #
          # Deprecated: this goes away in ActiveRecord 4.1. Use join_sources.
          #
          def join_associations
            @join_dependency.join_associations
          end

          def join_sources
            base = Arel::SelectManager.new(@object.engine, @object.table)
            joins = @object.joins_values
            joins.each do |assoc|
              assoc.join_to(base)
            end
            base.join_sources
          end

        end

        def alias_tracker
          @join_dependency.alias_tracker
        end

        def lock_association(association)
          @lock_associations << association
        end

        if ::ActiveRecord::VERSION::STRING >= Constants::RAILS_4_1
          def remove_association(association)
            return if @lock_associations.include?(association)
            @join_dependency.join_root.children.delete_if { |stashed|
              stashed.eql?(association)
            }
            @object.joins_values.delete_if { |jd|
              jd.join_root.children.map(&:object_id) == [association.object_id]
            }
          end
        else
          def remove_association(association)
            return if @lock_associations.include?(association)
            @join_dependency.join_parts.delete(association)
            @object.joins_values.delete(association)
          end
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
          join_table = join_root.left
          correlated_key = join_root.right.expr.left
          subquery = Arel::SelectManager.new(association.base_klass)
          subquery.from(join_root.left)
          subquery.project(correlated_key)
          join_constraints.each do |j|
            subquery.join_sources << Arel::Nodes::InnerJoin.new(j.left, j.right)
          end
          subquery.where(correlated_key.eq(primary_key))
        end

        def primary_key
          @object.table[@object.primary_key]
        end

        private

        def database_table_exists?
          if ::ActiveRecord::VERSION::MAJOR >= 5
            :data_source_exists?
          else
            :table_exists?
          end
        end

        def get_parent_and_attribute_name(str, parent = @base)
          attr_name = nil

          if ransackable_attribute?(str, klassify(parent))
            attr_name = str
          elsif (segments = str.split(Constants::UNDERSCORE)).size > 1
            remainder = []
            found_assoc = nil
            while remainder.unshift(segments.pop) && segments.size > 0 &&
            !found_assoc do
              assoc, klass = unpolymorphize_association(
                segments.join(Constants::UNDERSCORE)
                )
              if found_assoc = get_association(assoc, parent)
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

        def join_dependency(relation)
          if relation.respond_to?(:join_dependency) # Polyamorous enables this
            relation.join_dependency
          else
            build_joins(relation)
          end
        end

        # Checkout active_record/relation/query_methods.rb +build_joins+ for
        # reference. Lots of duplicated code maybe we can avoid it
        def build_joins(relation)
          buckets = relation.joins_values.group_by do |join|
            case join
            when String
              :string_join
            when Hash, Symbol, Array
              :association_join
            when Polyamorous::JoinDependency, Polyamorous::JoinAssociation
              :stashed_join
            when Arel::Nodes::Join
              :join_node
            else
              raise 'unknown class: %s' % join.class.name
            end
          end
          buckets.default = []
          association_joins         = buckets[:association_join]
          stashed_association_joins = buckets[:stashed_join]
          join_nodes                = buckets[:join_node].uniq
          string_joins              = buckets[:string_join].map(&:strip).uniq

          join_list =
            if ::ActiveRecord::VERSION::MAJOR >= 5
              join_nodes +
              convert_join_strings_to_ast(relation.table, string_joins)
            else
              relation.send :custom_join_ast,
                relation.table.from(relation.table), string_joins
            end

          join_dependency = JoinDependency.new(
            relation.klass, association_joins, join_list
          )

          join_nodes.each do |join|
            join_dependency.alias_tracker.aliases[join.left.name.downcase] = 1
          end

          if ::ActiveRecord::VERSION::STRING >= Constants::RAILS_4_1
            join_dependency
          else
            join_dependency.graft(*stashed_association_joins)
          end
        end

        def convert_join_strings_to_ast(table, joins)
          joins
          .flatten
          .reject(&:blank?)
          .map { |join| table.create_string_join(Arel.sql(join)) }
        end

        def build_or_find_association(name, parent = @base, klass = nil)
          find_association(name, parent, klass) or build_association(name, parent, klass)
        end

        if ::ActiveRecord::VERSION::STRING >= Constants::RAILS_4_1

          def find_association(name, parent = @base, klass = nil)
            @join_dependency.join_root.children.detect do |assoc|
              assoc.reflection.name == name &&
              (@associations_pot.empty? || @associations_pot[assoc] == parent) &&
              (!klass || assoc.reflection.klass == klass)
            end
          end

          def build_association(name, parent = @base, klass = nil)
            jd = JoinDependency.new(
              parent.base_klass,
              Polyamorous::Join.new(name, @join_type, klass),
              []
            )
            found_association = jd.join_root.children.last
            @associations_pot[found_association] = parent

            # TODO maybe we dont need to push associations here, we could loop
            # through the @associations_pot instead
            @join_dependency.join_root.children.push found_association

            # Builds the arel nodes properly for this association
            @join_dependency.send(
              :construct_tables!, jd.join_root, found_association
              )

            # Leverage the stashed association functionality in AR
            @object = @object.joins(jd)

            found_association
          end

          def extract_joins(association)
            parent = @join_dependency.join_root
            reflection = association.reflection
            join_constraints = association.join_constraints(
              parent.table,
              parent.base_klass,
              association,
              Arel::Nodes::OuterJoin,
              association.tables,
              reflection.scope_chain,
              reflection.chain
            )
            join_constraints.to_a.flatten
          end

        else

          def build_association(name, parent = @base, klass = nil)
            @join_dependency.send(
              :build,
              Polyamorous::Join.new(name, @join_type, klass),
              parent
              )
            found_association = @join_dependency.join_associations.last
            # Leverage the stashed association functionality in AR
            @object = @object.joins(found_association)

            found_association
          end

          def extract_joins(association)
            query = Arel::SelectManager.new(association.base_klass, association.table)
            association.join_to(query).join_sources
          end

          def find_association(name, parent = @base, klass = nil)
            found_association = @join_dependency.join_associations
            .detect do |assoc|
              assoc.reflection.name == name &&
              assoc.parent == parent &&
              (!klass || assoc.reflection.klass == klass)
            end
          end

        end

      end
    end
  end
end
