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
            expect(subject.object).to be_an ::ActiveRecord::Relation
          end

          context 'with scopes' do
            before do
              Person.stub :ransackable_scopes => [:active, :over_age]
            end

            it "applies true scopes" do
              search =  Person.search('active' => true)
              search.result.to_sql.should include "active = 1"
            end

            it "ignores unlisted scopes" do
              search =  Person.search('restricted' => true)
              search.result.to_sql.should_not include "restricted"
            end

            it "ignores false scopes" do
              search = Person.search('active' => false)
              search.result.to_sql.should_not include "active"
            end

            it "passes values to scopes" do
              search = Person.search('over_age' => 18)
              search.result.to_sql.should include "age > 18"
            end

            it "chains scopes" do
              search = Person.search('over_age' => 18, 'active' => true)
              search.result.to_sql.should include "age > 18"
              search.result.to_sql.should include "active = 1"
            end
          end

          it 'does not raise exception for string :params argument' do
            lambda { Person.search('') }.should_not raise_error
          end

          it 'does not modify the parameters' do
            params = { :name_eq => '' }
            expect { Person.search(params) }.not_to change { params }
          end
        end

        describe '#ransacker' do
          # For infix tests
          def self.sane_adapter?
            case ::ActiveRecord::Base.connection.adapter_name
            when "SQLite3", "PostgreSQL"
              true
            else
              false
            end
          end
          # in schema.rb, class Person:
          # ransacker :reversed_name, formatter: proc { |v| v.reverse } do |parent|
          #   parent.table[:name]
          # end
          #
          # ransacker :doubled_name do |parent|
          #   Arel::Nodes::InfixOperation.new(
          #     '||', parent.table[:name], parent.table[:name]
          #   )
          # end

          it 'creates ransack attributes' do
            s = Person.search(:reversed_name_eq => 'htimS cirA')
            expect(s.result.size).to eq(1)

            expect(s.result.first).to eq Person.where(name: 'Aric Smith').first
          end

          it 'can be accessed through associations' do
            s = Person.search(:children_reversed_name_eq => 'htimS cirA')
            expect(s.result.to_sql).to match(
              /#{quote_table_name("children_people")}.#{
                 quote_column_name("name")} = 'Aric Smith'/
            )
          end

          it 'allows an "attribute" to be an InfixOperation' do
            s = Person.search(:doubled_name_eq => 'Aric SmithAric Smith')
            expect(s.result.first).to eq Person.where(name: 'Aric Smith').first
          end if defined?(Arel::Nodes::InfixOperation) && sane_adapter?

          it "doesn't break #count if using InfixOperations" do
            s = Person.search(:doubled_name_eq => 'Aric SmithAric Smith')
            expect(s.result.count).to eq 1
          end if defined?(Arel::Nodes::InfixOperation) && sane_adapter?

          it "should remove empty key value pairs from the params hash" do
            s = Person.search(:children_reversed_name_eq => '')
            expect(s.result.to_sql).not_to match /LEFT OUTER JOIN/
          end

          it "should keep proper key value pairs in the params hash" do
            s = Person.search(:children_reversed_name_eq => 'Testing')
            expect(s.result.to_sql).to match /LEFT OUTER JOIN/
          end

          it "should function correctly when nil is passed in" do
            s = Person.search(nil)
          end

          it "should function correctly when a blank string is passed in" do
            s = Person.search('')
          end

          it "should function correctly when using fields with dots in them" do
            s = Person.search(:email_cont => "example.com")
            expect(s.result.exists?).to be true
          end

          it "should function correctly when using fields with % in them" do
            Person.create!(:name => "110%-er")
            s = Person.search(:name_cont => "10%")
            expect(s.result.exists?).to be true
          end

          it "should function correctly when using fields with backslashes in them" do
            Person.create!(:name => "\\WINNER\\")
            s = Person.search(:name_cont => "\\WINNER\\")
            expect(s.result.exists?).to be true
          end

          it 'allows sort by "only_sort" field' do
            s = Person.search(
              "s" => { "0" => { "dir" => "asc", "name" => "only_sort" } }
            )
            expect(s.result.to_sql).to match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_sort")} ASC/
            )
          end

          it "doesn't sort by 'only_search' field" do
            s = Person.search(
              "s" => { "0" => { "dir" => "asc", "name" => "only_search" } }
            )
            expect(s.result.to_sql).not_to match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_search")} ASC/
            )
          end

          it 'allows search by "only_search" field' do
            s = Person.search(:only_search_eq => 'htimS cirA')
            expect(s.result.to_sql).to match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_search")} = 'htimS cirA'/
            )
          end

          it "can't be searched by 'only_sort'" do
            s = Person.search(:only_sort_eq => 'htimS cirA')
            expect(s.result.to_sql).not_to match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_sort")} = 'htimS cirA'/
            )
          end

          it 'allows sort by "only_admin" field, if auth_object: :admin' do
            s = Person.search(
              { "s" => { "0" => { "dir" => "asc", "name" => "only_admin" } } },
              { auth_object: :admin }
            )
            expect(s.result.to_sql).to match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} ASC/
            )
          end

          it "doesn't sort by 'only_admin' field, if auth_object: nil" do
            s = Person.search(
              "s" => { "0" => { "dir" => "asc", "name" => "only_admin" } }
            )
            expect(s.result.to_sql).not_to match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} ASC/
            )
          end

          it 'allows search by "only_admin" field, if auth_object: :admin' do
            s = Person.search(
              { :only_admin_eq => 'htimS cirA' },
              { :auth_object => :admin }
            )
            expect(s.result.to_sql).to match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} = 'htimS cirA'/
            )
          end

          it "can't be searched by 'only_admin', if auth_object: nil" do
            s = Person.search(:only_admin_eq => 'htimS cirA')
            expect(s.result.to_sql).not_to match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} = 'htimS cirA'/
            )
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

        describe '#ransackable_scopes' do
          subject { Person.ransackable_scopes }

          it { should eq [] }
        end

      end
    end
  end
end
