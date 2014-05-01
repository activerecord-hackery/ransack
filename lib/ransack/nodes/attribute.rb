module Ransack
  module Nodes
    class Attribute < Node
      include Bindable

      attr_reader :name

      delegate :blank?, :present?, :==, :to => :name
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
        bound? && attr &&
        context.klassify(parent).ransackable_attributes(context.auth_object)
        .include?(attr_name)
      end

      def type
        if ransacker
          return ransacker.type
        else
          context.type_for(self)
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

      def inspect
        "Attribute <#{name}>"
      end

    end
  end
end
