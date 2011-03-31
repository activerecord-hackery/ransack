require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe Base do

        it 'adds a ransack method to ActiveRecord::Base' do
          ::ActiveRecord::Base.should respond_to :ransack
        end

        it 'aliases the method to search if available' do
          ::ActiveRecord::Base.should respond_to :search
        end

        describe '#search' do
          before do
            @s = Person.search
          end

          it 'creates a search with Relation as its object' do
            @s.should be_a Search
            @s.object.should be_an ::ActiveRecord::Relation
          end
        end

      end
    end
  end
end