module Ransack
  module Nodes
    class Sort < Node
      include Bindable

      attr_reader :name, :dir
      i18n_word :asc, :desc

      class << self
        def extract(context, str)
          attr, direction = str.split(/\s+/,2)
          self.new(context).build(name: attr, dir: direction)
        end
      end

      def build(params)
        params.with_indifferent_access.each do |key, value|
          if key.match(/^(name|dir)$/)
            self.send("#{key}=", value)
          end
        end

        self
      end

      def valid?
        bound? && attr &&
          context.klassify(parent).ransortable_attributes(context.auth_object)
          .include?(attr_name)
      end

      def name=(name)
        @name = name
        context.bind(self, name) unless name.blank?
      end

      def dir=(dir)
        dir = dir.try(:downcase)
        @dir = %w(asc desc).include?(dir) ? dir : 'asc'
      end

    end
  end
end
