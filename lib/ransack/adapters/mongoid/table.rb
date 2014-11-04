module Ransack
  module Adapters
    module Mongoid
      class Table
        attr_accessor :name

        alias :table_name :name

        def initialize(object, engine = nil)
          @object  = object
          @name    = object.collection.name
          @engine  = engine
          @columns = nil
          @aliases = []
          @table_alias = nil
          @primary_key = nil

          if Hash === engine
            # @engine  = engine[:engine] || Table.engine

            # Sometime AR sends an :as parameter to table, to let the table know
            # that it is an Alias.  We may want to override new, and return a
            # TableAlias node?
            # @table_alias = engine[:as] unless engine[:as].to_s == @name
          end
        end

        def [](name)
          Ransack::Adapters::Mongoid::Attribute.new self, name
        end

      end
    end
  end
end
