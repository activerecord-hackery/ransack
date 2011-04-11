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

        describe '#ransacker' do
          it 'creates ransack attributes' do
            Person.ransacker :backwards_name do |parent|
              parent.table[:backwards_name]
            end
            s = Person.search(:backwards_name_eq => 'blah')
            s.result.to_sql.should match /"people"."backwards_name" = 'blah'/
          end
        end

      end
    end
  end
end