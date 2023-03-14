module Ransack
  module Adapters
    module ActiveRecord
      module Base

        def self.extended(base)
          base.class_eval do
            class_attribute :_ransackers
            class_attribute :_ransack_aliases
            self._ransackers ||= {}
            self._ransack_aliases ||= {}
          end
        end

        def ransack(params = {}, options = {})
          Search.new(self, params, options)
        end

        def ransack!(params = {}, options = {})
          ransack(params, options.merge(ignore_unknown_conditions: false))
        end

        def ransacker(name, opts = {}, &block)
          self._ransackers = _ransackers.merge name.to_s => Ransacker
            .new(self, name, opts, &block)
        end

        def ransack_alias(new_name, old_name)
          self._ransack_aliases = _ransack_aliases.merge new_name.to_s =>
            old_name.to_s
        end

        # Ransackable_attributes, by default, returns all column names
        # and any defined ransackers as an array of strings.
        # For overriding with a whitelist array of strings.
        #
        def ransackable_attributes(auth_object = nil)
          @ransackable_attributes ||= deprecated_ransackable_list(:ransackable_attributes)
        end

        # Ransackable_associations, by default, returns the names
        # of all associations as an array of strings.
        # For overriding with a whitelist array of strings.
        #
        def ransackable_associations(auth_object = nil)
          @ransackable_associations ||= deprecated_ransackable_list(:ransackable_associations)
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

        # ransack_scope_skip_sanitize_args, by default, returns an empty array.
        # i.e. use the sanitize_scope_args setting to determine if args should be converted.
        # For overriding with a list of scopes which should be passed the args as-is.
        #
        def ransackable_scopes_skip_sanitize_args
          []
        end

        # Bare list of all potentially searchable attributes. Searchable attributes
        # need to be explicitly allowlisted through the `ransackable_attributes`
        # method in each model, but if you're allowing almost everything to be
        # searched, this list can be used as a base for exclusions.
        #
        def authorizable_ransackable_attributes
          if Ransack::SUPPORTS_ATTRIBUTE_ALIAS
            column_names + _ransackers.keys + _ransack_aliases.keys +
            attribute_aliases.keys
          else
            column_names + _ransackers.keys + _ransack_aliases.keys
          end.uniq
        end

        # Bare list of all potentially searchable associations. Searchable
        # associations need to be explicitly allowlisted through the
        # `ransackable_associations` method in each model, but if you're
        # allowing almost everything to be searched, this list can be used as a
        # base for exclusions.
        #
        def authorizable_ransackable_associations
          reflect_on_all_associations.map { |a| a.name.to_s }
        end

        private

        def deprecated_ransackable_list(method)
          list_type = method.to_s.delete_prefix("ransackable_")

          if explicitly_defined?(method)
            warn_deprecated <<~ERROR
              Ransack's builtin `#{method}` method is deprecated and will result
              in an error in the future. If you want to authorize the full list
              of searchable #{list_type} for this model, use
              `authorizable_#{method}` instead of delegating to `super`.
            ERROR

            public_send("authorizable_#{method}")
          else
            raise <<~MESSAGE
              Ransack needs #{name} #{list_type} explicitly allowlisted as
              searchable. Define a `#{method}` class method in your `#{name}`
              model, watching out for items you DON'T want searchable (for
              example, `encrypted_password`, `password_reset_token`, `owner` or
              other sensitive information). You can use the following as a base:

              ```ruby
              class #{name} < ApplicationRecord

                # ...

                def self.#{method}(auth_object = nil)
                  #{public_send("authorizable_#{method}").sort.inspect}
                end

                # ...

              end
              ```
            MESSAGE
          end
        end

        def explicitly_defined?(method)
          definer_ancestor = singleton_class.ancestors.find do |ancestor|
            ancestor.instance_methods(false).include?(method)
          end

          definer_ancestor != Ransack::Adapters::ActiveRecord::Base
        end

        def warn_deprecated(message)
          caller_location = caller_locations.find { |location| !location.path.start_with?(File.expand_path("../..", __dir__)) }

          warn "DEPRECATION WARNING: #{message.squish} (called at #{caller_location.path}:#{caller_location.lineno})"
        end
      end
    end
  end
end
