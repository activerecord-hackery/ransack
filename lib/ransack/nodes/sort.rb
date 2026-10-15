module Ransack
  module Nodes
    class Sort < Node
      include Bindable

      attr_reader :name, :dir, :ransacker_args
      i18n_word :asc, :desc

      class << self
        def extract(context, str)
          return if str.blank?
          attr, direction = str.split(/\s+/, 2)
          self.new(context).build(name: attr, dir: direction)
        end
      end

      def build(params)
        indifferent_params(params, 'sort').each do |key, value|
          if key.match(/\A(name|dir|ransacker_args)\z/)
            self.send("#{key}=", value)
          end
        end
        # A sort given without a direction is ascending, as it is from a
        # string (`s: 'name'`).
        self.dir = nil unless defined?(@dir)

        self
      end

      def valid?
        bound? && attr &&
          context.ransortable_attribute?(attr_name.split('.').last, context.klassify(parent))
      end

      def name=(name)
        @name = context.resolve_aliases(scalar_param(name, 'a sort name').to_s)
        context.bind(self, @name)
      end

      def dir=(dir)
        dir = scalar_param(dir, 'a sort direction').to_s.downcase
        @dir =
          if dir == 'asc'.freeze || dir == 'desc'.freeze
            dir
          else
            'asc'.freeze
          end
      end

      def ransacker_args=(ransack_args)
        @ransacker_args = ransack_args
      end

    end
  end
end
