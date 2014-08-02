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

          ###
          # Create a node for lowering this attribute
          def lower
            relation.lower self
          end

          def eq(other)
            { name => other }.to_inquiry
          end

          def not_eq(other)
            { name.to_sym.ne => other }.to_inquiry
          end

          def matches(other)
            { name => /#{Regexp.escape(other)}/i }.to_inquiry
          end

          def does_not_match(other)
            { "$not" => { name => /#{Regexp.escape(other)}/i } }.to_inquiry
          end

          def not_eq_all(other)
            q = []
            other.each do |value|
              q << { name.to_sym.ne => value }
            end
            { "$and" => q }.to_inquiry
          end

          def eq_any(other)
            q = []
            other.each do |value|
              q << { name => value }
            end
            { "$or" => q }.to_inquiry
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
