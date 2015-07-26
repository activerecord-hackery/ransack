module Ransack
  module Helpers
    module FormHelper

      # +search_form_for+
      #
      #   <%= search_form_for(@q) do |f| %>
      #
      def search_form_for(record, options = {}, &proc)
        if record.is_a? Ransack::Search
          search = record
          options[:url] ||= polymorphic_path(
            search.klass, format: options.delete(:format)
            )
        elsif record.is_a?(Array) &&
        (search = record.detect { |o| o.is_a?(Ransack::Search) })
          options[:url] ||= polymorphic_path(
            options_for(record), format: options.delete(:format)
            )
        else
          raise ArgumentError,
          'No Ransack::Search object was provided to search_form_for!'
        end
        options[:html] ||= {}
        html_options = {
          class:  html_option_for(options[:class], search),
          id:     html_option_for(options[:id], search),
          method: :get
        }
        options[:as] ||= Ransack.options[:search_key]
        options[:html].reverse_merge!(html_options)
        options[:builder] ||= FormBuilder

        form_for(record, options, &proc)
      end

      # +sort_link+
      #
      #   <%= sort_link(@q, :name, [:name, 'kind ASC'], 'Player Name') %>
      #
      def sort_link(search_object, attribute, *args)
        search, routing_proxy = extract_search_and_routing_proxy(search_object)
        unless Search === search
          raise TypeError, 'First argument must be a Ransack::Search!'
        end
        s = SortLink.new(search, attribute, args, params)
        link_to(s.name, url(routing_proxy, s.url_options), s.html_options(args))
      end

      private

        def options_for(record)
          record.map &method(:parse_record)
        end

        def parse_record(object)
          if object.is_a?(Ransack::Search)
            object.klass
          else
            object
          end
        end

        def html_option_for(option, search)
          if option.present?
            option.to_s
          else
            "#{search.klass.to_s.underscore}_search"
          end
        end

        def extract_search_and_routing_proxy(search)
          if search.is_a? Array
            [search.second, search.first]
          else
            [search, nil]
          end
        end

        def url(routing_proxy, options_for_url)
          if routing_proxy && respond_to?(routing_proxy)
            send(routing_proxy).url_for(options_for_url)
          else
            url_for(options_for_url)
          end
        end

      class SortLink
        def initialize(search, attribute, args, params)
          @search         = search
          @params         = params
          @field          = attribute.to_s
          @sort_fields    = extract_sort_fields_and_mutate_args!(args).compact
          @current_dir    = existing_sort_direction
          @label_text     = extract_label_and_mutate_args!(args)
          @options        = extract_options_and_mutate_args!(args)
          @hide_indicator = @options.delete :hide_indicator
          @default_order  = @options.delete :default_order
        end

        def name
          [ERB::Util.h(@label_text), order_indicator]
          .compact
          .join(Constants::NON_BREAKING_SPACE)
          .html_safe
        end

        def url_options
          @params.merge(
            @options.merge(
              @search.context.search_key => search_and_sort_params))
        end

        def html_options(args)
          html_options = extract_options_and_mutate_args!(args)
          html_options.merge(
            class: [[Constants::SORT_LINK, @current_dir], html_options[:class]]
                   .compact.join(Constants::SPACE)
          )
        end

        private

          def extract_sort_fields_and_mutate_args!(args)
            if args.first.is_a? Array
              args.shift
            else
              [@field]
            end
          end

          def extract_label_and_mutate_args!(args)
            if args.first.is_a? String
              args.shift
            else
              Translate.attribute(@field, context: @search.context)
            end
          end

          def extract_options_and_mutate_args!(args)
            if args.first.is_a? Hash
              args.shift.with_indifferent_access
            else
              {}
            end
          end

          def search_and_sort_params
            search_params.merge(s: sort_params)
          end

          def search_params
            @params[@search.context.search_key].presence || {}
          end

          def sort_params
            sort_array = recursive_sort_params_build(@sort_fields)
            if sort_array.size == 1
              sort_array.first
            else
              sort_array
            end
          end

          def recursive_sort_params_build(fields)
            return [] if fields.empty?
            [parse_sort(fields[0])] + recursive_sort_params_build(fields.drop 1)
          end

          def parse_sort(field)
            attr_name, new_dir = field.to_s.split(/\s+/)
            if no_sort_direction_specified?(new_dir)
              new_dir = detect_previous_sort_direction_and_invert_it(attr_name)
            end
            "#{attr_name} #{new_dir}"
          end

          def detect_previous_sort_direction_and_invert_it(attr_name)
            if sort_dir = existing_sort_direction(attr_name)
              direction_text(sort_dir)
            else
              default_sort_order(attr_name) || Constants::ASC
            end
          end

          def existing_sort_direction(attr_name = @field)
            if sort = @search.sorts.detect { |s| s && s.name == attr_name }
              sort.dir
            end
          end

          def default_sort_order(attr_name)
            if Hash === @default_order
              @default_order[attr_name]
            else
              @default_order
            end
          end

          def order_indicator
            if @hide_indicator || no_sort_direction_specified?
              nil
            else
              direction_arrow
            end
          end

          def no_sort_direction_specified?(dir = @current_dir)
            !Constants::ASC_DESC.include?(dir)
          end

          def direction_arrow
            if @current_dir == Constants::DESC
              Constants::DESC_ARROW
            else
              Constants::ASC_ARROW
            end
          end

          def direction_text(dir)
            if dir == Constants::DESC
              Constants::ASC
            else
              Constants::DESC
            end
          end

      end
    end
  end
end
