module Ransack
  module Adapters
    module Mongoid
      module Attributes
        module OrderPredications
          def asc
            { name => :asc }
          end

          def desc
            { name => :desc }
          end
        end
      end
    end
  end
end
