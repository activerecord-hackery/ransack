require 'delegate'

module Ransack
  module Adapters
    module Mongoid
      module Base

        extend ActiveSupport::Concern

        included do
        end

        class ColumnWrapper < SimpleDelegator
          def type
            _super = super
            case _super
            when BSON::ObjectId, Object
              :string
            else
              _super.name.underscore.to_sym
            end
          end
        end

        class Connection
          def initialize model
            @model = model
          end

          def quote_column_name name
            name
          end
        end

        module ClassMethods
          def _ransack_aliases
            @_ransack_aliases ||= {}
          end

          def _ransack_aliases=(value)
            @_ransack_aliases = value
          end

          def _ransackers
            @_ransackers ||= {}
          end

          def _ransackers=(value)
            @_ransackers = value
          end

          def ransack(params = {}, options = {})
            params = params.presence || {}
            Search.new(self, params ? params.delete_if {
              |k, v| v.blank? && v != false } : params, options)
          end

          alias_method :search, :ransack

          def ransack_alias(new_name, old_name)
            self._ransack_aliases.store(new_name.to_s, old_name.to_s)
          end

          def ransacker(name, opts = {}, &block)
            self._ransackers = _ransackers.merge name.to_s => Ransacker
              .new(self, name, opts, &block)
          end

          def all_ransackable_attributes
            ['id'] + column_names.select { |c| c != '_id' } + _ransackers.keys +
              _ransack_aliases.keys
          end

          def ransackable_attributes(auth_object = nil)
            all_ransackable_attributes
          end

          def ransortable_attributes(auth_object = nil)
            # Here so users can overwrite the attributes
            # that show up in the sort_select
            ransackable_attributes(auth_object)
          end

          def ransackable_associations(auth_object = nil)
            reflect_on_all_associations_all.map { |a| a.name.to_s }
          end

          def reflect_on_all_associations_all
            reflect_on_all_associations(
              :belongs_to, :has_one, :has_many, :embeds_many, :embedded_in
              )
          end

          # For overriding with a whitelist of symbols
          def ransackable_scopes(auth_object = nil)
            []
          end

          # imitating active record

          def joins_values *args
            []
          end

          def custom_join_ast *args
            []
          end

          def first(*args)
            if args.size == 0
              super
            else
              self.criteria.limit(args.first)
            end
          end

          # def group_by *args, &block
          #   criteria
          # end

          def columns
            @columns ||= fields.map(&:second).map{ |c| ColumnWrapper.new(c) }
          end

          def column_names
            @column_names ||= fields.map(&:first)
          end

          def columns_hash
            columns.index_by(&:name)
          end

          def table
            name = ::Ransack::Adapters::Mongoid::Attributes::Attribute.new(
              self.criteria, :name
              )
            { :name => name }
          end

        end

      end # Base
    end
  end
end
