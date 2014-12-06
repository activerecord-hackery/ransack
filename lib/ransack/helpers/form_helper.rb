module Ransack
  module Helpers
    module FormHelper

      def search_form_for(record, options = {}, &proc)
        if record.is_a?(Ransack::Search)
          search = record
          options[:url] ||= polymorphic_path(
            search.klass, format: options.delete(:format)
            )
        elsif record.is_a?(Array) &&
            (search = record.detect { |o| o.is_a?(Ransack::Search) })
          options[:url] ||= polymorphic_path(
            record.map { |o| o.is_a?(Ransack::Search) ? o.klass : o },
            format: options.delete(:format)
            )
        else
          raise ArgumentError,
            "No Ransack::Search object was provided to search_form_for!"
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

      # sort_link(@q, :name, [:name, 'kind ASC'], 'Player Name')
      def sort_link(search, attribute, *args)
        # Extract out a routing proxy for url_for scoping later
        if search.is_a?(Array)
          routing_proxy = search.shift
          search = search.first
        end

        raise TypeError, "First argument must be a Ransack::Search!" unless
          Search === search

        # This is the field that this link represents. The direction of the sort icon (up/down arrow) will
        # depend on the sort status of this field
        field_name = attribute.to_s

        # Determine the fields we want to sort on
        sort_fields = if Array === args.first
          args.shift
        else
          Array(field_name)
        end

        label_text =
          if String === args.first
            args.shift.to_s
          else
            Translate.attribute(field_name, :context => search.context)
          end

        options = args.first.is_a?(Hash) ? args.shift.dup : {}
        hide_indicator = options.delete :hide_indicator
        default_order = options.delete :default_order
        default_order_is_a_hash = Hash === default_order

        # If the default order is a hash of fields, duplicate it and let us
        # access it with strings or symbols.
        if default_order_is_a_hash
          default_order = default_order.dup.with_indifferent_access
        end

        search_params = params[search.context.search_key].presence ||
          {}.with_indifferent_access

        # Find the current direction (if there is one) of the primary sort field
        if existing_sort = search.sorts.detect { |s| s.name == field_name }
          field_current_dir = existing_sort.dir
        end

        sort_params = initialize_sort_params(sort_fields, existing_sort,
        search, default_order_is_a_hash, default_order)

        # if there is only one sort parameter, remove it from the array and just
        # use the string as the parameter
        if sort_params.size == 1
          sort_params = sort_params.first
        end

        html_options = args.first.is_a?(Hash) ? args.shift.dup : {}
        css = [Constants::SORT_LINK, field_current_dir]
          .compact.join(Constants::SPACE)
        html_options[:class] = [css, html_options[:class]]
          .compact.join(Constants::SPACE)

        query_hash = {}
        query_hash[search.context.search_key] = search_params
          .merge(:s => sort_params)
        options.merge!(query_hash)
        options_for_url = params.merge(options)

        url = build_url_for(routing_proxy, options_for_url)
        name = link_name(label_text, field_current_dir, hide_indicator)

        link_to(name, url, html_options)
      end

      private

        # Extract out a routing proxy for url_for scoping later
        def routing_proxy_and_search_object(search)
          if search.is_a? Array
            [search.first, search.second]
          else
            [nil, search]
          end
        end

        def initialize_sort_params(sort_fields, existing_sort, search,
                                   default_order_is_a_hash, default_order)
          sort_fields.each_with_object([]) do |field, a|
            attr_name, new_dir = field.to_s.split(/\s+/)
            current_dir = nil
            # if the user didn't specify the sort direction, detect the previous
            # sort direction on this field and invert it.
            if neither_asc_nor_desc?(new_dir)
              if existing_sort = search.sorts.detect { |s| s.name == attr_name }
                current_dir = existing_sort.dir
              end
              new_dir =
                if current_dir
                  direction_text(current_dir)
                elsif default_order_is_a_hash
                  default_order[attr_name] || Constants::ASC
                else
                  default_order || Constants::ASC
                end
            end
            a << "#{attr_name} #{new_dir}"
          end
        end

        def build_url_for(routing_proxy, options_for_url)
          if routing_proxy && respond_to?(routing_proxy)
            send(routing_proxy).url_for(options_for_url)
          else
            url_for(options_for_url)
          end
        end

        def link_name(label_text, dir, hide_indicator)
          [ERB::Util.h(label_text), order_indicator_for(dir, hide_indicator)]
          .compact
          .join(Constants::NON_BREAKING_SPACE)
          .html_safe
        end

        def order_indicator_for(dir, hide_indicator)
          if hide_indicator || neither_asc_nor_desc?(dir)
            nil
          else
            direction_arrow(dir)
          end
        end

        def neither_asc_nor_desc?(dir)
          Constants::ASC_DESC.none? { |d| d == dir }
        end

        def direction_arrow(dir)
          if dir == Constants::DESC
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
