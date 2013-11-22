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

          it 'allows sort by "only_sort" field' do
            s = Person.search("s"=>{"0"=>{"dir"=>"asc", "name"=>"only_sort"}})
            s.result.to_sql.should match /ORDER BY "people"."name" \|\| "only_sort" \|\| "people"."name" ASC/
          end

          it "doesn't sort by 'only_search' field" do
            s = Person.search("s"=>{"0"=>{"dir"=>"asc", "name"=>"only_search"}})
            s.result.to_sql.should_not match /ORDER BY "people"."name" \|\| "only_search" \|\| "people"."name" ASC/
          end

          it 'allows search by "only_search" field' do
            s = Person.search(:only_search_eq => 'htimS cirA')
            s.result.to_sql.should match /WHERE "people"."name" \|\| "only_search" \|\| "people"."name" = 'htimS cirA'/
          end

          it "can't be searched by 'only_sort'" do
            s = Person.search(:only_sort_eq => 'htimS cirA')
            s.result.to_sql.should_not match /WHERE "people"."name" \|\| "only_sort" \|\| "people"."name" = 'htimS cirA'/
          end

          it 'allows sort by "only_admin" field, if auth_object: :admin' do
            s = Person.search({"s"=>{"0"=>{"dir"=>"asc", "name"=>"only_admin"}}}, {auth_object: :admin})
            s.result.to_sql.should match /ORDER BY "people"."name" \|\| "only_admin" \|\| "people"."name" ASC/
          end

          it "doesn't sort by 'only_admin' field, if auth_object: nil" do
            s = Person.search("s"=>{"0"=>{"dir"=>"asc", "name"=>"only_admin"}})
            s.result.to_sql.should_not match /ORDER BY "people"."name" \|\| "only_admin" \|\| "people"."name" ASC/
          end

          it 'allows search by "only_admin" field, if auth_object: :admin' do
            s = Person.search({:only_admin_eq => 'htimS cirA'}, {auth_object: :admin})
            s.result.to_sql.should match /WHERE "people"."name" \|\| "only_admin" \|\| "people"."name" = 'htimS cirA'/
          end

          it "can't be searched by 'only_admin'" do
            s = Person.search(:only_admin_eq => 'htimS cirA')
            s.result.to_sql.should_not match /WHERE "people"."name" \|\| "only_admin" \|\| "people"."name" = 'htimS cirA'/
          end
        end

        describe '#ransackable_attributes' do
          context 'when auth_object is nil' do
            subject { Person.ransackable_attributes }

            it { should include 'name' }
            it { should include 'reversed_name' }
            it { should include 'doubled_name' }
            it { should include 'only_search' }
            it { should_not include 'only_sort' }
            it { should_not include 'only_admin' }
          end

          context 'with auth_object :admin' do
            subject { Person.ransackable_attributes(:admin) }

            it { should include 'name' }
            it { should include 'reversed_name' }
            it { should include 'doubled_name' }
            it { should include 'only_search' }
            it { should_not include 'only_sort' }
            it { should include 'only_admin' }
          end
        end

        describe '#ransortable_attributes' do
          context 'when auth_object is nil' do
            subject { Person.ransortable_attributes }

            it { should include 'name' }
            it { should include 'reversed_name' }
            it { should include 'doubled_name' }
            it { should include 'only_sort' }
            it { should_not include 'only_search' }
            it { should_not include 'only_admin' }
          end

          context 'with auth_object :admin' do
            subject { Person.ransortable_attributes(:admin) }

            it { should include 'name' }
            it { should include 'reversed_name' }
            it { should include 'doubled_name' }
            it { should include 'only_sort' }
            it { should_not include 'only_search' }
            it { should include 'only_admin' }
          end
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
