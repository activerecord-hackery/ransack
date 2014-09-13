module Ransack
  module Adapters
    module ActiveRecord
      module Base

        def self.extended(base)
          alias :search :ransack unless base.respond_to? :search
          base.class_eval do
            class_attribute :_ransackers
            self._ransackers ||= {}
          end
        end

        def ransack(params = {}, options = {})
          Search.new(self, params, options)
        end

        def ransacker(name, opts = {}, &block)
          self._ransackers = _ransackers.merge name.to_s => Ransacker
            .new(self, name, opts, &block)
        end

        def ransackable_attributes(auth_object = nil)
          # By default returns all column names and any defined ransackers
          # as strings. For overriding with a whitelist of strings.
          column_names + _ransackers.keys
        end

        def ransackable_associations(auth_object = nil)
          # By default returns the names of all associations as strings.
          # For overriding with a whitelist of strings.
          reflect_on_all_associations.map { |a| a.name.to_s }
        end

        def ransortable_attributes(auth_object = nil)
          # By default returns the names of all attributes for sorting.
          # For overriding with a whitelist of strings.
          ransackable_attributes(auth_object)
        end

        def ransackable_scopes(auth_object = nil)
          # By default returns an empty array, i.e. no class methods/scopes
          # are authorized. For overriding with a whitelist of symbols.
          []
        end

      end
    end
  end
end
