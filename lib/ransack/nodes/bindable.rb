module Ransack
  module Nodes
    module Bindable

      attr_accessor :parent, :attr_name

      def attr
        @attr ||= get_arel_attribute
      end
      alias :arel_attribute :attr

      def ransacker
        klass._ransackers[attr_name]
      end

      def klass
        @klass ||= context.klassify(parent)
      end

      def bound?
        attr_name.present? && parent.present?
      end

      def reset_binding!
        @parent = @attr_name = @attr = @klass = nil
      end

      private

        def get_arel_attribute
          if ransacker
            ransacker.attr_from(self)
          else
            context.table_for(parent)[attr_name]
          end
        end

    end
  end
end
