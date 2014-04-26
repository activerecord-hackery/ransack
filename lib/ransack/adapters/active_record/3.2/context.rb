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
            relation = relation.except(:order).reorder(viz.accept(search.sorts))
          end
          opts[:distinct] ? relation.uniq : relation
        end

      end
    end
  end
end
