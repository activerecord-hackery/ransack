module Ransack
  module Helpers
    module FormHelper

      # +search_form_for+
      #
      # Example: <%= search_form_for(@q) do |f| %>
      #
      def search_form_for(record, options = {}, &proc)
        if record.is_a? Ransack::Search
          search = record
          options[:url] ||= polymorphic_path(
            search.klass, format: options.delete(:format)
            )
        elsif record.is_a? Array &&
            (search = record.detect { |o| o.is_a? Ransack::Search })
          options[:url] ||= polymorphic_path(
            record.map { |o| o.is_a? Ransack::Search ? o.klass : o },
            format: options.delete(:format)
            )
        else
          raise ArgumentError,
            'No Ransack::Search object was provided to search_form_for!'
        end
        options[:html] ||= {}
        html_options = {
          :class => options[:class].present? ?
            "#{options[:class]}" :
            "#{search.klass.to_s.underscore}_search",
          :id => options[:id].present? ?
            "#{options[:id]}" :
            "#{search.klass.to_s.underscore}_search",
          :method => :get
        }
        options[:as] ||= Ransack.options[:search_key]
        options[:html].reverse_merge!(html_options)
        options[:builder] ||= FormBuilder

        form_for(record, options, &proc)
      end

      # +sort_link+
      #
      # Example: <%= sort_link(@q, :name, [:name, 'kind ASC'], 'Player Name') %>
      #
      def sort_link(search, attribute, *args)
        @search_object, routing_proxy = extract_search_obj_and_routing(search)
        raise TypeError, 'First argument must be a Ransack::Search!' unless
          Search === @search_object
        initialize!(search, attribute, args)
        link_to(name, url(routing_proxy), html_options(args))
      end

      private

        # All mutation and order-dependent code happens here.
        # Ivars are not mutated outside of this method.
        def initialize!(search, attribute, args)
          @field_name        = attribute.to_s
          sort_fields,  args = extract_sort_fields(args)
          @label_text,  args = extract_label_text(args)
          @options,     args = extract_options(args)
          @hide_indicator    = @options.delete :hide_indicator
          @default_order     = @options.delete :default_order
          if Hash === @default_order
            @default_order   = @default_order.with_indifferent_access
          end
          @sort_params       = initialize_sort_params(sort_fields)
          @sort_params       = @sort_params.first if @sort_params.size == 1
          @current_dir       = existing_sort_direction
        end

        def name
          [ERB::Util.h(@label_text), order_indicator]
          .compact.join(Constants::NON_BREAKING_SPACE).html_safe
        end

        def url(routing_proxy)
          if routing_proxy && respond_to?(routing_proxy)
            send(routing_proxy).url_for(options_for_url)
          else
            url_for(options_for_url)
          end
        end

        def options_for_url
          @options[@search_object.context.search_key] = search_and_sort_params
          params.merge(@options)
        end

        def search_and_sort_params
          search_params.merge(:s => @sort_params)
        end

        def search_params
          params[@search_object.context.search_key].presence ||
          {}.with_indifferent_access
        end

        def html_options(args)
          html_options = extract_options(args).first
          html_options.merge(class: [css, html_options[:class]]
          .compact.join(Constants::SPACE))
        end

        def css
          [Constants::SORT_LINK, @current_dir].compact.join(Constants::SPACE)
        end

        def extract_search_obj_and_routing(search)
          if search.is_a? Array
            [search.second, search.first]
          else
            [search, nil]
          end
        end

        def extract_sort_fields(args)
          if Array === args.first
            [args.shift, args]
          else
            [Array(@field_name), args]
          end
        end

        def extract_label_text(args)
          if String === args.first
            [args.shift, args]
          else
            [Translate.attribute(@field_name, :context => @search_object.context), args]
          end
        end

        def extract_options(args)
          if args.first.is_a? Hash
            [args.shift, args]
          else
            [{}, args]
          end
        end

        def initialize_sort_params(sort_fields)
          sort_fields.each_with_object([]) do |field, a|
            attr_name, new_dir = field.to_s.split(/\s+/)
            if no_sort_direction_specified?(new_dir)
              new_dir = detect_previous_sort_direction_and_invert_it(attr_name)
            end
            a << "#{attr_name} #{new_dir}"
          end
        end

        def detect_previous_sort_direction_and_invert_it(attr_name)
          sort_dir = existing_sort_direction(attr_name)
          if sort_dir
            direction_text(sort_dir)
          else
            default_sort_order(attr_name) || Constants::ASC
          end
        end

        def existing_sort_direction(attr_name = @field_name)
          if sort = @search_object.sorts.detect { |s| s.name == attr_name }
            sort.dir
          end
        end

        def default_sort_order(attr_name)
          Hash === @default_order ? @default_order[attr_name] : @default_order
        end

        def order_indicator
          if @hide_indicator || no_sort_direction_specified?
            nil
          else
            direction_arrow
          end
        end

        def no_sort_direction_specified?(dir = @current_dir)
          Constants::ASC_DESC.none? { |d| d == dir }
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
