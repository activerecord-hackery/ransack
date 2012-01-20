require 'ransack/context'
require 'ransack/adapters/active_record/3.1/context'
require 'polyamorous'

module Ransack
  module Adapters
    module ActiveRecord
      class Context < ::Ransack::Context
        
        # Redefine a few things that have changed with 3.2.
        
        def initialize(object, options = {})
          super
          @arel_visitor = @engine.connection.visitor
        end
        
        def type_for(attr)
          return nil unless attr && attr.valid?
          name    = attr.arel_attribute.name.to_s
          table   = attr.arel_attribute.relation.table_name

          unless @engine.connection.table_exists?(table)
            raise "No table named #{table} exists"
          end

          @engine.connection.schema_cache.columns_hash[table][name].type
        end
        
      end
    end
  end
end