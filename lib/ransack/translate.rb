require 'i18n'

I18n.load_path += Dir[
  File.join(File.dirname(__FILE__), 'locale'.freeze, '*.yml'.freeze)
]

module Ransack
  module Translate
    class << self
      def word(key, options = {})
        I18n.translate(:"ransack.#{key}", default: key.to_s)
      end

      def predicate(key, options = {})
        I18n.translate(:"ransack.predicates.#{key}", default: key.to_s)
      end

      def attribute(key, options = {})
        unless context = options.delete(:context)
          raise ArgumentError, "A context is required to translate attributes"
        end

        original_name = key.to_s
        base_class = context.klass
        base_ancestors = base_class.ancestors.select {
          |x| x.respond_to?(:model_name)
        }
        attributes_str = original_name.dup # will be modified by ⬇
        predicate = Predicate.detect_and_strip_from_string!(attributes_str)
        attribute_names = attributes_str.split(/_and_|_or_/)
        combinator = attributes_str =~ /_and_/ ? :and : :or
        defaults = base_ancestors.map do |klass|
          "ransack.attributes.#{i18n_key(klass)}.#{original_name}".to_sym
        end
        defaults << options.delete(:default) if options[:default]

        translated_names = attribute_names.map do |name|
          attribute_name(context, name, options[:include_associations])
        end

        interpolations = {
          attributes: translated_names.join(" #{Translate.word(combinator)} ")
        }

        if predicate
          defaults << "%{attributes} %{predicate}".freeze
          interpolations[:predicate] = Translate.predicate(predicate)
        else
          defaults << "%{attributes}".freeze
        end

        options.reverse_merge! count: 1, default: defaults
        I18n.translate(defaults.shift, **options.merge(interpolations))
      end

      def association(key, options = {})
        unless context = options.delete(:context)
          raise ArgumentError, "A context is required to translate associations"
        end

        defaults =
          if key.blank?
            [:"ransack.models.#{i18n_key(context.klass)}",
             :"#{context.klass.i18n_scope}.models.#{i18n_key(context.klass)}"]
          else
            [:"ransack.associations.#{i18n_key(context.klass)}.#{key}"]
          end
        defaults << context.traverse(key).model_name.human
        options = { count: 1, default: defaults }
        I18n.translate(defaults.shift, **options)
      end

      private

      # The module is shared by every thread, so nothing here is kept between
      # calls: each helper is handed what it needs. Storing the name being
      # translated on the module let one request read another's while both
      # rendered sort links.
      AttributeName = Struct.new(:context, :name, :attr_name, :assoc_path,
                                 :associated_class, :include_associated)
      private_constant :AttributeName

      def attribute_name(context, name, include_associations = nil)
        assoc_path = context.association_path(name)
        associated_class = context.traverse(assoc_path) if assoc_path.present?
        part = AttributeName.new(
          context, name, name.sub(/\A#{Regexp.escape(assoc_path)}_/, ''.freeze),
          assoc_path, associated_class, include_associations && associated_class
        )

        defaults = default_attribute_name(part) << fallback_args(part)
        options = { count: 1, default: defaults }
        interpolations = build_interpolations(part)

        I18n.translate(defaults.shift, **options.merge(interpolations))
      end

      def default_attribute_name(part)
        ["ransack.attributes.#{i18n_key(part.context.klass)}.#{part.name}".to_sym]
      end

      def fallback_args(part)
        if part.include_associated
          '%{association_name} %{attr_fallback_name}'.freeze
        else
          '%{attr_fallback_name}'.freeze
        end
      end

      def build_interpolations(part)
        {
          attr_fallback_name: attr_fallback_name(part),
          association_name: association_name(part)
        }.reject { |_, value| value.nil? }
      end

      def attr_fallback_name(part)
        I18n.t(
          :"ransack.attributes.#{fallback_class(part)}.#{part.attr_name}",
          default: default_interpolation(part)
        )
      end

      def fallback_class(part)
        i18n_key(part.associated_class || part.context.klass)
      end

      def association_name(part)
        association(part.assoc_path, context: part.context) if part.include_associated
      end

      def default_interpolation(part)
        [
          associated_attribute(part),
          ".attributes.#{part.attr_name}".to_sym,
          part.attr_name.humanize
        ].flatten
      end

      def associated_attribute(part)
        if part.associated_class
          translated_attribute(part.associated_class, part.attr_name)
        else
          translated_ancestor_attributes(part)
        end
      end

      def translated_attribute(klass, attr_name)
        key = "#{klass.i18n_scope}.attributes.#{i18n_key(klass)}.#{attr_name}"
        ["#{key}.one".to_sym, key.to_sym]
      end

      def translated_ancestor_attributes(part)
        part.context.klass.ancestors
          .select { |ancestor| ancestor.respond_to?(:model_name) }
          .map { |ancestor| translated_attribute(ancestor, part.attr_name) }
      end

      def i18n_key(klass)
        klass.model_name.i18n_key
      end
    end
  end
end
