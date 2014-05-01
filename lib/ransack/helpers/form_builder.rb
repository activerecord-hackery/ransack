require 'action_view'

require 'simple_form' if
  (ENV['RANSACK_FORM_BUILDER'] || '').match('SimpleForm')

module Ransack
  module Helpers
    class FormBuilder < (ENV['RANSACK_FORM_BUILDER'].try(:constantize) ||
      ActionView::Helpers::FormBuilder)

      def label(method, *args, &block)
        options = args.extract_options!
        text = args.first
        i18n = options[:i18n] || {}
        text ||= object.translate(
          method, i18n.reverse_merge(:include_associations => true)
          ) if object.respond_to? :translate
        super(method, text, options, &block)
      end

      def submit(value = nil, options = {})
        value, options = nil, value if value.is_a?(Hash)
        value ||= Translate.word(:search).titleize
        super(value, options)
      end

      def attribute_select(options = nil, html_options = nil, action = nil)
        options = options || {}
        html_options = html_options || {}
        action = action || 'search'
        default = options.delete(:default)
        raise ArgumentError, formbuilder_error_message(
          "#{action}_select") unless object.respond_to?(:context)
        options[:include_blank] = true unless options.has_key?(:include_blank)
        bases = [''] + association_array(options[:associations])
        if bases.size > 1
          collection = attribute_collection_for_bases(action, bases)
          object.name ||= default if can_use_default?(
            default, :name, mapped_values(collection.flatten(2))
            )
          template_grouped_collection_select(collection, options, html_options)
        else
          collection = collection_for_base(action, bases.first)
          object.name ||= default if can_use_default?(
            default, :name, mapped_values(collection)
            )
          template_collection_select(:name, collection, options, html_options)
        end
      end

      def sort_direction_select(options = {}, html_options = {})
        raise ArgumentError, formbuilder_error_message(
          'sort_direction') unless object.respond_to?(:context)
        template_collection_select(:dir, sort_array, options, html_options)
      end

      def sort_select(options = {}, html_options = {})
        attribute_select(options, html_options, 'sort') +
        sort_direction_select(options, html_options)
      end

      def sort_fields(*args, &block)
        search_fields(:s, args, block)
      end

      def sort_link(attribute, *args)
        @template.sort_link @object, attribute, *args
      end

      def condition_fields(*args, &block)
        search_fields(:c, args, block)
      end

      def grouping_fields(*args, &block)
        search_fields(:g, args, block)
      end

      def attribute_fields(*args, &block)
        search_fields(:a, args, block)
      end

      def predicate_fields(*args, &block)
        search_fields(:p, args, block)
      end

      def value_fields(*args, &block)
        search_fields(:v, args, block)
      end

      def search_fields(name, args, block)
        args << {} unless args.last.is_a?(Hash)
        args.last[:builder] ||= options[:builder]
        args.last[:parent_builder] = self
        options = args.extract_options!
        objects = args.shift
        objects ||= @object.send(name)
        objects = [objects] unless Array === objects
        name = "#{options[:object_name] || object_name}[#{name}]"
        output = ActiveSupport::SafeBuffer.new
        objects.each do |child|
          output << @template.fields_for("#{name}[#{
            options[:child_index] || nested_child_index(name)
            }]", child, options, &block)
        end
        output
      end

      def predicate_select(options = {}, html_options = {})
        options[:compounds] = true if options[:compounds].nil?
        default = options.delete(:default) || 'cont'

        keys = options[:compounds] ? Predicate.names :
          Predicate.names.reject { |k| k.match(/_(any|all)$/) }
        if only = options[:only]
          if only.respond_to? :call
            keys = keys.select { |k| only.call(k) }
          else
            only = Array.wrap(only).map(&:to_s)
            keys = keys.select { |k| only.include? k.sub(/_(any|all)$/, '') }
          end
        end
        collection = keys.map { |k| [k, Translate.predicate(k)] }
        object.predicate ||= Predicate.named(default) if can_use_default?(
          default, :predicate, keys
          )
        template_collection_select(:p, collection, options, html_options)
      end

      def combinator_select(options = {}, html_options = {})
        template_collection_select(
          :m, combinator_choices, options, html_options)
      end

      private

      def template_grouped_collection_select(collection, options, html_options)
        @template.grouped_collection_select(
          @object_name, :name, collection, :last, :first, :first, :last,
          objectify_options(options), @default_options.merge(html_options)
          )
      end

      def template_collection_select(name, collection, options, html_options)
        @template.collection_select(
          @object_name, name, collection, :first, :last,
          objectify_options(options), @default_options.merge(html_options)
          )
      end

      def can_use_default?(default, attribute, values)
        object.respond_to?("#{attribute}=") && default &&
          values.include?(default.to_s)
      end

      def mapped_values(values)
        values.map { |v| v.is_a?(Array) ? v.first : nil }.compact
      end

      def sort_array
        [['asc', object.translate('asc')], ['desc', object.translate('desc')]]
      end

      def combinator_choices
        if Nodes::Condition === object
          [['or', Translate.word(:any)], ['and', Translate.word(:all)]]
        else
          [['and', Translate.word(:all)], ['or', Translate.word(:any)]]
        end
      end

      def association_array(obj, prefix = nil)
        ([prefix] + association_object(obj))
        .compact
        .flatten
        .map { |v| [prefix, v].compact.join('_') }
      end

      def association_object(obj)
        case obj
        when Array
          obj
        when Hash
          association_hash(obj)
        else
          [obj]
        end
      end

      def association_hash(obj)
        obj.map do |key, value|
          case value
          when Array, Hash
            association_array(value, key.to_s)
          else
            [key.to_s, [key, value].join('_')]
          end
        end
      end

      def attribute_collection_for_bases(action, bases)
        bases.map { |base| get_attribute_element(action, base) }.compact
      end

      def get_attribute_element(action, base)
        begin
          [Translate.association(base, :context => object.context),
            collection_for_base(action, base)]
        rescue UntraversableAssociationError => e
          nil
        end
      end

      def attribute_collection_for_base(attributes, base = nil)
        attributes.map do |c|
          [attr_from_base_and_column(base, c),
            Translate.attribute(
              attr_from_base_and_column(base, c),
              :context => object.context
            )
          ]
        end
      end

      def collection_for_base(action, base)
        attribute_collection_for_base(
          object.context.send("#{action}able_attributes", base), base)
      end

      def attr_from_base_and_column(base, column)
        [base, column].reject { |v| v.blank? }.join('_')
      end

      def formbuilder_error_message(action)
        "#{action.sub('search', 'attribute')
          } must be called inside a search FormBuilder!"
      end

    end
  end
end
