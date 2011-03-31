module Ransack
  module Nodes
    class Sort < Node
      attr_reader :name, :attr, :dir
      i18n_word :asc, :desc

      class << self
        def extract(context, str)
          attr, direction = str.split(/\s+/,2)
          self.new(context).build(:name => attr, :dir => direction)
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
        @attr
      end

      def name=(name)
        @name = name
        @attr = contextualize(name) unless name.blank?
      end

      def dir=(dir)
        @dir = %w(asc desc).include?(dir) ? dir : 'asc'
      end

    end
  end
end