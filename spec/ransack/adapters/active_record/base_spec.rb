require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe Base do

        subject { ::ActiveRecord::Base }

        it { should respond_to :ransack }
        it { should respond_to :search }

        describe '#search' do
          subject { Person.search }

          it { should be_a Search }
          it 'has a Relation as its object' do
            subject.object.should be_an ::ActiveRecord::Relation
          end
        end

        describe '#ransacker' do
          # in schema.rb, class Person:
          # ransacker :reversed_name, :formatter => proc {|v| v.reverse} do |parent|
          #   parent.table[:name]
          # end
          #
          # ransacker :doubled_name do |parent|
          #   Arel::Nodes::InfixOperation.new('||', parent.table[:name], parent.table[:name])
          # end
          it 'creates ransack attributes' do
            s = Person.search(:reversed_name_eq => 'htimS cirA')
            s.result.should have(1).person
            s.result.first.should eq Person.find_by_name('Aric Smith')
          end

          it 'can be accessed through associations' do
            s = Person.search(:children_reversed_name_eq => 'htimS cirA')
            s.result.to_sql.should match /"children_people"."name" = 'Aric Smith'/
          end

          it 'allows an "attribute" to be an InfixOperation' do
            s = Person.search(:doubled_name_eq => 'Aric SmithAric Smith')
            s.result.first.should eq Person.find_by_name('Aric Smith')
          end if defined?(Arel::Nodes::InfixOperation)

          it "doesn't break #count if using InfixOperations" do
            s = Person.search(:doubled_name_eq => 'Aric SmithAric Smith')
            s.result.count.should eq 1
          end if defined?(Arel::Nodes::InfixOperation)
        end

        describe '#ransackable_attributes' do
          subject { Person.ransackable_attributes }

          it { should include 'name' }
          it { should include 'reversed_name' }
          it { should include 'doubled_name' }
        end

        describe '#ransackable_associations' do
          subject { Person.ransackable_associations }

          it { should include 'parent' }
          it { should include 'children' }
          it { should include 'articles' }
        end

      end
    end
  end
end