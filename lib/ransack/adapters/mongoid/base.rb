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

          def ransacker(name, opts = {}, &block)
            self._ransackers = _ransackers.merge name.to_s => Ransacker
              .new(self, name, opts, &block)
          end

          def ransackable_attributes(auth_object = nil)
            column_names + _ransackers.keys
          end

          def ransortable_attributes(auth_object = nil)
            # Here so users can overwrite the attributes
            # that show up in the sort_select
            ransackable_attributes(auth_object)
          end

          def ransackable_associations(auth_object = nil)
            reflect_on_all_associations.map { |a| a.name.to_s }
          end

          # For overriding with a whitelist of symbols
          def ransackable_scopes(auth_object = nil)
            []
          end

          # imitating active record

          def joins_values *args
            criteria
          end

          def group_by *args, &block
            criteria
          end

          def columns
            @columns ||= fields.map(&:second).map{ |c| ColumnWrapper.new(c) }
          end

          def column_names
            @column_names ||= fields.map(&:first)
          end

          def columns_hash
            columns.index_by(&:name)
          end

        end


          # base::ClassMethods.class_eval do

          # end # base::ClassMethods.class_eval

        # def self.extended(base)
        # end

      end # Base
    end
  end
end
