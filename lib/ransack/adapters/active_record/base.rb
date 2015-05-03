module Ransack
  module Adapters
    module ActiveRecord
      module Base

        def self.extended(base)
          alias :search :ransack unless base.respond_to? :search
          base.class_eval do
            class_attribute :_ransackers
            class_attribute :_ransacker_aliases
            self._ransackers ||= {}
            self._ransacker_aliases ||= {}
          end
        end

        def ransack(params = {}, options = {})
          params.keys.each do |k|
            search_attr = k.to_s.sub(/_#{Ransack::Predicate.detect_from_string(k.to_s)}$/, Ransack::Constants::EMPTY)
            search_pred = k.to_s.sub(/^#{search_attr}_/, Ransack::Constants::EMPTY)
            if _ransacker_aliases.has_key?(search_attr)
              params["#{_ransacker_aliases[search_attr]}_#{search_pred}"] = params.delete(k)
            end
          end

          Search.new(self, params, options)
        end

        def ransacker(name, opts = {}, &block)
          self._ransackers = _ransackers.merge name.to_s => Ransacker
            .new(self, name, opts, &block)
        end
        
        def ransacker_alias(alias_name, normal_name)
          self._ransacker_aliases[alias_name.to_s] = normal_name.to_s
        end

        # Ransackable_attributes, by default, returns all column names
        # and any defined ransackers as an array of strings.
        # For overriding with a whitelist array of strings.
        #
        def ransackable_attributes(auth_object = nil)
          column_names + _ransackers.keys
        end

        # Ransackable_associations, by default, returns the names
        # of all associations as an array of strings.
        # For overriding with a whitelist array of strings.
        #
        def ransackable_associations(auth_object = nil)
          reflect_on_all_associations.map { |a| a.name.to_s }
        end

        # Ransortable_attributes, by default, returns the names
        # of all attributes available for sorting as an array of strings.
        # For overriding with a whitelist array of strings.
        #
        def ransortable_attributes(auth_object = nil)
          ransackable_attributes(auth_object)
        end

        # Ransackable_scopes, by default, returns an empty array
        # i.e. no class methods/scopes are authorized.
        # For overriding with a whitelist array of *symbols*.
        #
        def ransackable_scopes(auth_object = nil)
          []
        end

      end
    end
  end
end
