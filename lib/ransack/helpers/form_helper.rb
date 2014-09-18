module Ransack
  module Helpers
    module FormHelper

      def asc
        'asc'.freeze
      end

      def desc
        'desc'.freeze
      end

      def asc_arrow
        '&#9650;'.freeze
      end

      def desc_arrow
        '&#9660;'.freeze
      end

      def non_breaking_space
        '&nbsp;'.freeze
      end

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
        options[:as] ||= 'q'.freeze
        options[:html].reverse_merge!(html_options)
        options[:builder] ||= FormBuilder

        form_for(record, options, &proc)
      end

      def sort_link(search, attribute, *args)
        # Extract out a routing proxy for url_for scoping later
        if search.is_a?(Array)
          routing_proxy = search.shift
          search = search.first
        end

        raise TypeError, "First argument must be a Ransack::Search!" unless
          Search === search

        search_params = params[search.context.search_key].presence ||
          {}.with_indifferent_access

        attr_name = attribute.to_s

        name = (
          if args.size > 0 && !args.first.is_a?(Hash)
            args.shift.to_s
          else
            Translate.attribute(attr_name, :context => search.context)
          end
          )

        if existing_sort = search.sorts.detect { |s| s.name == attr_name }
          prev_attr, prev_dir = existing_sort.name, existing_sort.dir
        end

        options = args.first.is_a?(Hash) ? args.shift.dup : {}
        default_order = options.delete :default_order
        current_dir = prev_attr == attr_name ? prev_dir : nil

        if current_dir
          new_dir = current_dir == desc ? asc : desc
        else
          new_dir = default_order || asc
        end

        html_options = args.first.is_a?(Hash) ? args.shift.dup : {}
        css = ['sort_link', current_dir].compact.join(' ')
        html_options[:class] = [css, html_options[:class]].compact.join(' ')
        query_hash = {}
        query_hash[search.context.search_key] = search_params
        .merge(:s => "#{attr_name} #{new_dir}")
        options.merge!(query_hash)
        options_for_url = params.merge options

        url = if routing_proxy && respond_to?(routing_proxy)
          send(routing_proxy).url_for(options_for_url)
        else
          url_for(options_for_url)
        end

        link_to(
          [ERB::Util.h(name), order_indicator_for(current_dir)]
            .compact
            .join(non_breaking_space)
            .html_safe,
          url,
          html_options
          )
      end

      private

      def order_indicator_for(order)
        if order == asc
          asc_arrow
        elsif order == desc
          desc_arrow
        else
          nil
        end
      end

    end
  end
end
