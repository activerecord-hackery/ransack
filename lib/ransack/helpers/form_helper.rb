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
        options[:as] ||= Ransack::Constants::DEFAULT_SEARCH_KEY
        options[:html].reverse_merge!(html_options)
        options[:builder] ||= FormBuilder

        form_for(record, options, &proc)
      end

      # sort_link @q, :name, [:name, 'kind ASC'], 'Player Name'
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
        default_order = options.delete :default_order
        default_order_is_a_hash = Hash === default_order

        # If the default order is a hash of fields, duplicate it and let us access it with strings or symbols
        default_order = default_order.dup.with_indifferent_access if
          default_order_is_a_hash

        search_params = params[search.context.search_key].presence ||
          {}.with_indifferent_access

        # Find the current direction (if there is one) of the primary sort field
        if existing_sort = search.sorts.detect { |s| s.name == field_name }
          field_current_dir = existing_sort.dir
        end

        sort_params = []

        Array(sort_fields).each do |sort_field|
          attr_name, new_dir = sort_field.to_s.downcase.split(/\s+/)
          current_dir = nil

          # if the user didn't specify the sort direction, detect the previous
          # sort direction on this field and reverse it
          if Ransack::Constants::ASC_DESC.none? { |d| d == new_dir }
            if existing_sort = search.sorts.detect { |s| s.name == attr_name }
              current_dir = existing_sort.dir
            end

            new_dir =
              if current_dir
                if current_dir == Ransack::Constants::DESC
                  Ransack::Constants::ASC
                else
                  Ransack::Constants::DESC
                end
              elsif default_order_is_a_hash
                default_order[attr_name] || Ransack::Constants::ASC
              else
                default_order || Ransack::Constants::ASC
              end
          end

          sort_params << "#{attr_name} #{new_dir}"
        end

        # if there is only one sort parameter, remove it from the array and just
        # use the string as the parameter
        sort_params = sort_params.first if sort_params.size == 1

        html_options = args.first.is_a?(Hash) ? args.shift.dup : {}
        css = [Ransack::Constants::SORT_LINK, field_current_dir]
          .compact.join(Ransack::Constants::SPACE)
        html_options[:class] = [css, html_options[:class]]
          .compact.join(Ransack::Constants::SPACE)

        query_hash = {}
        query_hash[search.context.search_key] = search_params
          .merge(:s => sort_params)
        options.merge!(query_hash)
        options_for_url = params.merge(options)

        url =
        if routing_proxy && respond_to?(routing_proxy)
          send(routing_proxy).url_for(options_for_url)
        else
          url_for(options_for_url)
        end

        name = link_name(label_text, field_current_dir)

        link_to(name, url, html_options)
      end

      private

      def link_name(label_text, dir)
        [ERB::Util.h(label_text), order_indicator_for(dir)]
        .compact
        .join(Ransack::Constants::NON_BREAKING_SPACE)
        .html_safe
      end

      def order_indicator_for(dir)
        if dir == Ransack::Constants::ASC
          Ransack::Constants::ASC_ARROW
        elsif dir == Ransack::Constants::DESC
          Ransack::Constants::DESC_ARROW
        else
          nil
        end
      end

    end
  end
end
