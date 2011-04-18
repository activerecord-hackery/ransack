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

    end
  end
end