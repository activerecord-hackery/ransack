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
            s = Person.search(reversed_name_eq: 'htimS cirA')
            s.result.should have(1).person

            s.result.first.should eq Person.where(name: 'Aric Smith').first
          end

          it 'can be accessed through associations' do
            s = Person.search(children_reversed_name_eq: 'htimS cirA')
            s.result.to_sql.should match(
              /#{quote_table_name("children_people")}.#{
                 quote_column_name("name")} = 'Aric Smith'/
            )
          end

          it 'allows an "attribute" to be an InfixOperation' do
            s = Person.search(doubled_name_eq: 'Aric SmithAric Smith')
            s.result.first.should eq Person.where(name: 'Aric Smith').first
          end if defined?(Arel::Nodes::InfixOperation) && sane_adapter?

          it "doesn't break #count if using InfixOperations" do
            s = Person.search(doubled_name_eq: 'Aric SmithAric Smith')
            s.result.count.should eq 1
          end if defined?(Arel::Nodes::InfixOperation) && sane_adapter?

          it "should remove empty key value pairs from the params hash" do
            s = Person.search(children_reversed_name_eq: '')
            s.result.to_sql.should_not match /LEFT OUTER JOIN/
          end

          it "should keep proper key value pairs in the params hash" do
            s = Person.search(children_reversed_name_eq: 'Testing')
            s.result.to_sql.should match /LEFT OUTER JOIN/
          end

          it "should function correctly when nil is passed in" do
            s = Person.search(nil)
          end

          it "should function correctly when using fields with dots in them" do
            s = Person.search(email_cont: "example.com")
            s.result.exists?.should be_true
          end

          it "should function correctly when using fields with % in them" do
            Person.create!(name: "110%-er")
            s = Person.search(name_cont: "10%")
            s.result.exists?.should be_true
          end

          it "should function correctly when using fields with backslashes in them" do
            Person.create!(name: "\\WINNER\\")
            s = Person.search(name_cont: "\\WINNER\\")
            s.result.exists?.should be_true
          end

          it 'allows sort by "only_sort" field' do
            s = Person.search(
              "s" => { "0" => { "dir" => "asc", "name" => "only_sort" } }
            )
            s.result.to_sql.should match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_sort")} ASC/
            )
          end

          it "doesn't sort by 'only_search' field" do
            s = Person.search(
              "s" => { "0" => { "dir" => "asc", "name" => "only_search" } }
            )
            s.result.to_sql.should_not match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_search")} ASC/
            )
          end

          it 'allows search by "only_search" field' do
            s = Person.search(only_search_eq: 'htimS cirA')
            s.result.to_sql.should match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_search")} = 'htimS cirA'/
            )
          end

          it "can't be searched by 'only_sort'" do
            s = Person.search(only_sort_eq: 'htimS cirA')
            s.result.to_sql.should_not match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_sort")} = 'htimS cirA'/
            )
          end

          it 'allows sort by "only_admin" field, if auth_object: :admin' do
            s = Person.search(
              { "s" => { "0" => { "dir" => "asc", "name" => "only_admin" } } },
              { auth_object: :admin }
            )
            s.result.to_sql.should match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} ASC/
            )
          end

          it "doesn't sort by 'only_admin' field, if auth_object: nil" do
            s = Person.search(
              "s" => { "0" => { "dir" => "asc", "name" => "only_admin" } }
            )
            s.result.to_sql.should_not match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} ASC/
            )
          end

          it 'allows search by "only_admin" field, if auth_object: :admin' do
            s = Person.search(
              { only_admin_eq: 'htimS cirA' },
              { auth_object: :admin }
            )
            s.result.to_sql.should match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} = 'htimS cirA'/
            )
          end

          it "can't be searched by 'only_admin', if auth_object: nil" do
            s = Person.search(only_admin_eq: 'htimS cirA')
            s.result.to_sql.should_not match(
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

      end
    end
  end
end
