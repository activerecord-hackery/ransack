module Ransack
  module Helpers
    module FormHelper

      def search_form_for(record, options = {}, &proc)
        if record.is_a?(Ransack::Search)
          search = record
          options[:url] ||= polymorphic_path(search.klass)
        elsif record.is_a?(Array) && (search = record.detect {|o| o.is_a?(Ransack::Search)})
          options[:url] ||= polymorphic_path(record.map {|o| o.is_a?(Ransack::Search) ? o.klass : o})
        else
          raise ArgumentError, "No Ransack::Search object was provided to search_form_for!"
        end
        options[:html] ||= {}
        html_options = {
          :class  => options[:as] ? "#{options[:as]}_search" : "#{search.klass.to_s.underscore}_search",
          :id => options[:as] ? "#{options[:as]}_search" : "#{search.klass.to_s.underscore}_search",
          :method => :get
        }
        options[:as] ||= 'q'
        options[:html].reverse_merge!(html_options)
        options[:builder] ||= FormBuilder

        form_for(record, options, &proc)
      end

      def sort_link(search, attribute, *args)
        raise TypeError, "First argument must be a Ransack::Search!" unless Search === search

        search_params = params[:q] || {}.with_indifferent_access

        attr_name = attribute.to_s

        name = (args.size > 0 && !args.first.is_a?(Hash)) ? args.shift.to_s : Translate.attribute(attr_name, :context => search.context)

        if existing_sort = search.sorts.detect {|s| s.name == attr_name}
          prev_attr, prev_dir = existing_sort.name, existing_sort.dir
        end

        options = args.first.is_a?(Hash) ? args.shift.dup : {}
        default_order = options.delete :default_order
        no_order_indicator = options.delete :no_order_indicator
        current_dir = prev_attr == attr_name && !no_order_indicator ? prev_dir : nil

        if current_dir
          new_dir = current_dir == 'desc' ? 'asc' : 'desc'
        else
          new_dir = default_order || 'asc'
        end

        html_options = args.first.is_a?(Hash) ? args.shift.dup : {}
        css = ['sort_link', current_dir].compact.join(' ')
        html_options[:class] = [css, html_options[:class]].compact.join(' ')
        options.merge!(
          :q => search_params.merge(:s => "#{attr_name} #{new_dir}")
        )
        link_to [ERB::Util.h(name), order_indicator_for(current_dir)].compact.join(' ').html_safe,
                url_for(options),
                html_options
      end

      private

      def order_indicator_for(order)
        if order == 'asc'
          '&#9650;'
        elsif order == 'desc'
          '&#9660;'
        else
          nil
        end
      end

    end
  end
end