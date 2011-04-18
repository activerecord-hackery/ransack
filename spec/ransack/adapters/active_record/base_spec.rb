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
            s = Person.search(:reversed_name_eq => 'htimS cirA')
            s.result.should have(1).person
            s.result.first.should eq Person.find_by_name('Aric Smith')
          end

          it 'allows access of attributes through associations' do
            s = Person.search(:children_reversed_name_eq => 'htimS cirA')
            s.result.to_sql.should match /"children_people"."name" = 'Aric Smith'/
          end

          it 'allows an "attribute" to be an InfixOperation' do
            s = Person.search(:doubled_name_eq => 'Aric SmithAric Smith')
            s.result.first.should eq Person.find_by_name('Aric Smith')
          end if defined?(Arel::Nodes::InfixOperation)
        end

      end
    end
  end
end