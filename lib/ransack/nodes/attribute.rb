module Ransack
  module Nodes
    class Attribute < Node
      include Bindable

      attr_reader :name

      delegate :blank?, :==, :to => :name
      delegate :engine, :to => :context

      def initialize(context, name = nil)
        super(context)
        self.name = name unless name.blank?
      end

      def name=(name)
        @name = name
        context.bind(self, name) unless name.blank?
      end

      def valid?
        attr
      end

      def ransacker
        klass._ransackers[attr_name] if klass.respond_to?(:_ransackers)
      end

      def type
        if ransacker
          return ransacker[:type]
        else
          context.type_for(attr)
        end
      end

      def eql?(other)
        self.class == other.class &&
        self.name == other.name
      end
      alias :== :eql?

      def hash
        self.name.hash
      end

      def persisted?
        false
      end
    end
  end
end