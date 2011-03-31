module Ransack
  module Nodes
    class Attribute < Node
      attr_reader :name, :attr
      delegate :blank?, :==, :to => :name

      def initialize(context, name = nil)
        super(context)
        self.name = name unless name.blank?
      end

      def name=(name)
        @name = name
        @attr = contextualize(name) unless name.blank?
      end

      def valid?
        @attr
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