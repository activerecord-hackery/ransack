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

            s.result.to_sql.should match /#{quote_table_name("children_people")}.#{quote_column_name("name")} = 'Aric Smith'/
          end

          it 'allows an "attribute" to be an InfixOperation' do
            s = Person.search(:doubled_name_eq => 'Aric SmithAric Smith')
            s.result.first.should eq Person.find_by_name('Aric Smith')
          end if defined?(Arel::Nodes::InfixOperation) && sane_adapter?

          it "doesn't break #count if using InfixOperations" do
            s = Person.search(:doubled_name_eq => 'Aric SmithAric Smith')
            s.result.count.should eq 1
          end if defined?(Arel::Nodes::InfixOperation) && sane_adapter?

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
        end

        describe '#ransackable_attributes' do
          subject { Person.ransackable_attributes }

          it { should include 'name' }
          it { should include 'reversed_name' }
          it { should include 'doubled_name' }
        end
        
         describe "#spare_from_ransack" do
           
          context "with given attribute" do
            subject { Person.ransackable_attributes }
            
            it { should include 'name'}
            
            Person.spare_from_ransack :name
            
            it { should_not include 'name' }
            it { should include 'reversed_name' }
            it { should include 'doubled_name' }
          end
          
          context "with :primary" do 
            subject { Person.ransackable_attributes }
            
            it { should include Person.primary_key }
            
            Person.spare_from_ransack :primary
            
            it { should_not include Person.primary_key }
          end
          context "with :assocation_keys" do
            subject { Person.ransackable_attributes }
            
            it { should include "parent_id" }
            
            Person.spare_from_ransack :association_keys
            
            it { should_not include "parent_id" }
          end
          context "with :time_stamps" do
            subject { Person.ransackable_attributes }
            
            it { should include "created_at" }
            it { should include "updated_at" }
            
            Person.spare_from_ransack :time_stamps
            
            it { should_not include "created_at" }
            it { should_not include "updated_at" }
          end
        end
        describe '#ransortable_attributes' do
          subject { Person.ransortable_attributes }

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
