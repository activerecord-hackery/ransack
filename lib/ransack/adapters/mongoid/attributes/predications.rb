module Ransack
  module Adapters
    module Mongoid
      module Attributes
        module Predications

          def eq(other)
            { name => other }.to_inquiry
          end

          def not_eq(other)
            { name => { '$ne' => other } }.to_inquiry
          end

          def matches(other)
            { name => /#{Regexp.escape(other)}/i }.to_inquiry
          end

          def does_not_match(other)
            { "$not" => { name => /#{Regexp.escape(other)}/i } }.to_inquiry
          end

          def eq_all(others)
            grouping_all :eq, others
          end

          def not_eq_all(others)
            grouping_all :not_eq, others
          end

          def eq_any(others)
            grouping_any :eq, others
          end

          def not_eq_any(others)
            grouping_any :not_eq, others
          end

          def gteq right
            { name => { '$gte' => right } }.to_inquiry
          end

          def gteq_any others
            grouping_any :gteq, others
          end

          def gteq_all others
            grouping_all :gteq, others
          end

          def gt right
            { name => { '$gt' => right } }
          end

          def gt_any others
            grouping_any :gt, others
          end

          def gt_all others
            grouping_all :gt, others
          end

          def lt right
            { name => { '$lt' => right } }
          end

          def lt_any others
            grouping_any :lt, others
          end

          def lt_all others
            grouping_all :lt, others
          end

          def lteq right
            { name => { '$lte' => right } }.to_inquiry
          end

          def lteq_any others
            grouping_any :lteq, others
          end

          def lteq_all others
            grouping_all :lteq, others
          end

          private

          def grouping_any method_id, others
            nodes = others.map { |e| send(method_id, e) }
            { "$or" => nodes }.to_inquiry
          end

          def grouping_all method_id, others
            nodes = others.map { |e| send(method_id, e) }
            { "$and" => nodes }.to_inquiry
          end
        end
      end
    end
  end
end
