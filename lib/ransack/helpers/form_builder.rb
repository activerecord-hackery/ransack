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
          @template.grouped_collection_select(
            @object_name, :name, attribute_collection_for_bases(bases), :last, :first, :first, :last,
            objectify_options(options), @default_options.merge(html_options)
          )
        else
          collection = object.context.searchable_attributes(bases.first).map do |c|
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
        if bases.size > 1
          @template.grouped_collection_select(
            @object_name, :name, attribute_collection_for_bases(bases), :last, :first, :first, :last,
            objectify_options(options), @default_options.merge(html_options)
          ) + @template.collection_select(
            @object_name, :dir, [['asc', object.translate('asc')], ['desc', object.translate('desc')]], :first, :last,
            objectify_options(options), @default_options.merge(html_options)
          )
        else
          collection = object.context.searchable_attributes(bases.first).map do |c|
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
          output << @template.fields_for("#{name}[#{options[:child_index] || nested_child_index(name)}]", child, options, &block)
        end
        output
      end

      def predicate_select(options = {}, html_options = {})
        options[:compounds] = true if options[:compounds].nil?
        keys = options[:compounds] ? Predicate.names : Predicate.names.reject {|k| k.match(/_(any|all)$/)}
        if only = options[:only]
          if only.respond_to? :call
            keys = keys.select {|k| only.call(k)}
          else
            only = Array.wrap(only).map(&:to_s)
            keys = keys.select {|k| only.include? k.sub(/_(any|all)$/, '')}
          end
        end

        @template.collection_select(
          @object_name, :p, keys.map {|k| [k, Translate.predicate(k)]}, :first, :last,
          objectify_options(options), @default_options.merge(html_options)
        )
      end

      def combinator_select(options = {}, html_options = {})
        @template.collection_select(
          @object_name, :m, combinator_choices, :first, :last,
          objectify_options(options), @default_options.merge(html_options)
        )
      end

      private

      def combinator_choices
        if Nodes::Condition === object
          [['or', Translate.word(:any)], ['and', Translate.word(:all)]]
        else
          [['and', Translate.word(:all)], ['or', Translate.word(:any)]]
        end
      end

      def association_array(obj, prefix = nil)
        ([prefix] + case obj
        when Array
          obj
        when Hash
          obj.map do |key, value|
            case value
            when Array, Hash
              association_array(value, key.to_s)
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

      def attribute_collection_for_bases(bases)
        bases.map do |base|
          begin
          [
            Translate.association(base, :context => object.context),
            object.context.searchable_attributes(base).map do |c|
              [
                attr_from_base_and_column(base, c),
                Translate.attribute(attr_from_base_and_column(base, c), :context => object.context)
              ]
            end
          ]
          rescue UntraversableAssociationError => e
            nil
          end
        end.compact
      end

    end
  end
end