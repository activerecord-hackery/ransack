module Ransack
  module Nodes
    module Bindable

      attr_accessor :parent, :attr_name

      def attr
        @attr ||= ransacker ? ransacker[:callable].call(parent) : context.table_for(parent)[attr_name]
      end

      def ransacker
        klass._ransackers[attr_name] if klass.respond_to?(:_ransackers)
      end

      def klass
        @klass ||= context.klassify(parent)
      end

      def reset_binding!
        @parent = @attr_name = @attr = @klass = nil
      end

    end
  end
end