require 'ransack/context'
require 'ransack/adapters/active_record/3.1/context'
require 'ransack/adapters/active_record/compat'
require 'polyamorous'

module Ransack
  module Adapters
    module ActiveRecord
      class Context < ::Ransack::Context

        # Redefine a few things for ActiveRecord 3.2.

        def initialize(object, options = {})
          super
          @arel_visitor = @engine.connection.visitor
        end

        def relation_for(object)
          object.scoped
        end

        def type_for(attr)
          return nil unless attr && attr.valid?
          name    = attr.arel_attribute.name.to_s
          table   = attr.arel_attribute.relation.table_name

          schema_cache = @engine.connection.schema_cache
          raise "No table named #{table} exists" unless schema_cache.table_exists?(table)
          schema_cache.columns_hash[table][name].type
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
                relation = relation.order(scope_or_sort)
              end
            end
          end

          opts[:distinct] ? relation.uniq : relation
        end

      end
    end
  end
end
