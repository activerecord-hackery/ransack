module Ransack
  module Adapters
    module Mongoid
      module Base

        def self.extended(base)
          base::ClassMethods.class_eval do
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
          end # base::ClassMethods.class_eval
        end

      end # Base
    end
  end
end
