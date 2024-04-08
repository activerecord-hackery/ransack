module Ransack
  module Helpers
    class SimpleFormBuilder < ::Ransack::Helpers::FormBuilder
      attr_reader :simple_form_builder

      def initialize(*args, **kwargs)
        @simple_form_builder = ::SimpleForm::FormBuilder.new(*args, **kwargs)
        super
      end

      def input(attribute_name, options = {}, &block)
        options[:label] ||= label_text(attribute_name, nil, options)
        options[:required] ||= false
        simple_form_builder.input(attribute_name, options, &block)
      end
    end
  end
end
