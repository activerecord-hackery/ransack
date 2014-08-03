require 'ransack/adapters/mongoid/attributes/predications'

module Ransack
  module Adapters
    module Mongoid
      module Attributes
        class Attribute < Struct.new :relation, :name
          # include Arel::Expressions
          # include Arel::Predications
          # include Arel::AliasPredication
          # include Arel::OrderPredications
          # include Arel::Math

          include ::Ransack::Adapters::Mongoid::Attributes::Predications

          ###
          # Create a node for lowering this attribute
          def lower
            relation.lower self
          end

          def asc
            { name => :asc }
          end

          def desc
            { name => :desc }
          end
        end

        class String    < Attribute; end
        class Time      < Attribute; end
        class Boolean   < Attribute; end
        class Decimal   < Attribute; end
        class Float     < Attribute; end
        class Integer   < Attribute; end
        class Undefined < Attribute; end
      end

      Attribute = Attributes::Attribute
    end # Attributes
  end
end
