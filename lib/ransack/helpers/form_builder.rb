require 'action_view'

module Ransack
  module Helpers
    class FormBuilder < ::ActionView::Helpers::FormBuilder
      def label(method, *args, &block)
        options = args.extract_options!
        text = args.first
        i18n = options[:i18n] || {}
        text ||= object.translate(method, i18n.reverse_merge(:include_associations => true)) if object.respond_to? :translate
        super(method, text, options, &block)
      end

      def submit(value=nil, options={})
        value, options = nil, value if value.is_a?(Hash)
        value ||= Translate.word(:search).titleize
        super(value, options)
      end

      def attribute_select(options = {}, html_options = {})
        raise ArgumentError, "attribute_select must be called inside a search FormBuilder!" unless object.respond_to?(:context)
        options[:include_blank] = true unless options.has_key?(:include_blank)
        bases = [''] + association_array(options[:associations])
        if bases.size > 1
          collection = bases.map do |base|
            [
              Translate.association(base, :context => object.context),
              object.context.searchable_columns(base).map do |c|
                [
                  attr_from_base_and_column(base, c),
                  Translate.attribute(attr_from_base_and_column(base, c), :context => object.context)
                ]
              end
            ]
          end
          @template.grouped_collection_select(
            @object_name, :name, collection, :last, :first, :first, :last,
            objectify_options(options), @default_options.merge(html_options)
          )
        else
          collection = object.context.searchable_columns(bases.first).map do |c|
            [
              attr_from_base_and_column(bases.first, c),
              Translate.attribute(attr_from_base_and_column(bases.first, c), :context => object.context)
            ]
          end
          @template.collection_select(
            @object_name, :name, collection, :first, :last,
            objectify_options(options), @default_options.merge(html_options)
          )
        end
      end

      def sort_select(options = {}, html_options = {})
        raise ArgumentError, "sort_select must be called inside a search FormBuilder!" unless object.respond_to?(:context)
        options[:include_blank] = true unless options.has_key?(:include_blank)
        bases = [''] + association_array(options[:associations])
        if bases.any?
          collection = bases.map do |base|
            [
              Translate.association(base, :context => object.context),
              object.context.searchable_columns(base).map do |c|
                [
                  attr_from_base_and_column(base, c),
                  Translate.attribute(attr_from_base_and_column(base, c), :context => object.context)
                ]
              end
            ]
          end
          @template.grouped_collection_select(
            @object_name, :name, collection, :last, :first, :first, :last,
            objectify_options(options), @default_options.merge(html_options)
          ) + @template.collection_select(
            @object_name, :dir, [['asc', object.translate('asc')], ['desc', object.translate('desc')]], :first, :last,
            objectify_options(options), @default_options.merge(html_options)
          )
        else
          collection = object.context.searchable_columns(bases.first).map do |c|
            [
              attr_from_base_and_column(bases.first, c),
              Translate.attribute(attr_from_base_and_column(bases.first, c), :context => object.context)
            ]
          end
          @template.collection_select(
            @object_name, :name, collection, :first, :last,
            objectify_options(options), @default_options.merge(html_options)
          ) + @template.collection_select(
            @object_name, :dir, [['asc', object.translate('asc')], ['desc', object.translate('desc')]], :first, :last,
            objectify_options(options), @default_options.merge(html_options)
          )
        end
      end

      def sort_fields(*args, &block)
        search_fields(:s, args, block)
      end

      def condition_fields(*args, &block)
        search_fields(:c, args, block)
      end

      def and_fields(*args, &block)
        search_fields(:n, args, block)
      end

      def or_fields(*args, &block)
        search_fields(:o, args, block)
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
          output << @template.fields_for("#{name}[#{options[:child_index] || nested_child_index(name)}]", child, options, &block)
        end
        output
      end

      def predicate_select(options = {}, html_options = {})
        @template.collection_select(
          @object_name, :p, Predicate.collection, :first, :last,
          objectify_options(options), @default_options.merge(html_options)
        )
      end

      def combinator_select(options = {}, html_options = {})
        @template.collection_select(
          @object_name, :m, [['or', Translate.word(:or)], ['and', Translate.word(:and)]], :first, :last,
          objectify_options(options), @default_options.merge(html_options)
        )
      end

      private

      def association_array(obj, prefix = nil)
        ([prefix] + case obj
        when Array
          obj
        when Hash
          obj.map do |key, value|
            case value
            when Array, Hash
              bases_array(value, key.to_s)
            else
              [key.to_s, [key, value].join('_')]
            end
          end
        else
          [obj]
        end).compact.flatten.map {|v| [prefix, v].compact.join('_')}
      end

      def attr_from_base_and_column(base, column)
        [base, column].reject {|v| v.blank?}.join('_')
      end

    end
  end
end