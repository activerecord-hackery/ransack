require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe Base do

        subject { ::ActiveRecord::Base }

        it { should respond_to :ransack }
        it { should respond_to :search }

        describe '#search' do
          subject { Person.ransack }

          it { should be_a Search }
          it 'has a Relation as its object' do
            expect(subject.object).to be_an ::ActiveRecord::Relation
          end

          context 'with scopes' do
            before do
              Person.stub :ransackable_scopes => [:active, :over_age, :of_age]
            end

            it "applies true scopes" do
              s = Person.ransack('active' => true)
              expect(s.result.to_sql).to (include 'active = 1')
            end

            it "applies stringy true scopes" do
              s = Person.ransack('active' => 'true')
              expect(s.result.to_sql).to (include 'active = 1')
            end

            it "applies stringy boolean scopes with true value in an array" do
              s = Person.ransack('of_age' => ['true'])
              expect(s.result.to_sql).to (include 'age >= 18')
            end

            it "applies stringy boolean scopes with false value in an array" do
              s = Person.ransack('of_age' => ['false'])
              expect(s.result.to_sql).to (include 'age < 18')
            end

            it "ignores unlisted scopes" do
              s = Person.ransack('restricted' => true)
              expect(s.result.to_sql).to_not (include 'restricted')
            end

            it "ignores false scopes" do
              s = Person.ransack('active' => false)
              expect(s.result.to_sql).not_to (include 'active')
            end

            it "ignores stringy false scopes" do
              s = Person.ransack('active' => 'false')
              expect(s.result.to_sql).to_not (include 'active')
            end

            it "passes values to scopes" do
              s = Person.ransack('over_age' => 18)
              expect(s.result.to_sql).to (include 'age > 18')
            end

            it "chains scopes" do
              s = Person.ransack('over_age' => 18, 'active' => true)
              expect(s.result.to_sql).to (include 'age > 18')
              expect(s.result.to_sql).to (include 'active = 1')
            end
          end

          it 'does not raise exception for string :params argument' do
            expect { Person.ransack('') }.to_not raise_error
          end

          it 'does not modify the parameters' do
            params = { :name_eq => '' }
            expect { Person.ransack(params) }.not_to change { params }
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
            s = Person.ransack(:reversed_name_eq => 'htimS cirA')
            expect(s.result.size).to eq(1)

            expect(s.result.first).to eq Person.where(name: 'Aric Smith').first
          end

          it 'can be accessed through associations' do
            s = Person.ransack(:children_reversed_name_eq => 'htimS cirA')
            expect(s.result.to_sql).to match(
              /#{quote_table_name("children_people")}.#{
                 quote_column_name("name")} = 'Aric Smith'/
            )
          end

          it 'allows an "attribute" to be an InfixOperation' do
            s = Person.ransack(:doubled_name_eq => 'Aric SmithAric Smith')
            expect(s.result.first).to eq Person.where(name: 'Aric Smith').first
          end if defined?(Arel::Nodes::InfixOperation) && sane_adapter?

          it "doesn't break #count if using InfixOperations" do
            s = Person.ransack(:doubled_name_eq => 'Aric SmithAric Smith')
            expect(s.result.count).to eq 1
          end if defined?(Arel::Nodes::InfixOperation) && sane_adapter?

          it "should remove empty key value pairs from the params hash" do
            s = Person.ransack(:children_reversed_name_eq => '')
            expect(s.result.to_sql).not_to match /LEFT OUTER JOIN/
          end

          it "should keep proper key value pairs in the params hash" do
            s = Person.ransack(:children_reversed_name_eq => 'Testing')
            expect(s.result.to_sql).to match /LEFT OUTER JOIN/
          end

          it "should function correctly when nil is passed in" do
            s = Person.ransack(nil)
          end

          it "should function correctly when a blank string is passed in" do
            s = Person.ransack('')
          end

          it "should function correctly with a multi-parameter attribute" do
            ::ActiveRecord::Base.default_timezone = :utc
            Time.zone = 'UTC'

            date = Date.current
            s = Person.ransack(
              { "created_at_gteq(1i)" => date.year,
                "created_at_gteq(2i)" => date.month,
                "created_at_gteq(3i)" => date.day
              }
            )
            expect(s.result.to_sql).to match />=/
            expect(s.result.to_sql).to match date.to_s
          end

          it "should function correctly when using fields with dots in them" do
            s = Person.ransack(:email_cont => "example.com")
            expect(s.result.exists?).to be true
          end

          it "should function correctly when using fields with % in them" do
            p = Person.create!(:name => "110%-er")
            s = Person.ransack(:name_cont => "10%")
            expect(s.result.to_a).to eq [p]
          end

          it "should function correctly when using fields with backslashes in them" do
            p = Person.create!(:name => "\\WINNER\\")
            s = Person.ransack(:name_cont => "\\WINNER\\")
            expect(s.result.to_a).to eq [p]
          end

          context "searching on an `in` predicate with a ransacker" do
            it "should function correctly when passing an array of ids" do
              s = Person.ransack(array_users_in: true)
              expect(s.result.count).to be > 0
            end

            it "should function correctly when passing an array of strings" do
              Person.create!(name: Person.first.id.to_s)
              s = Person.ransack(array_names_in: true)
              expect(s.result.count).to be > 0
            end

            it 'should function correctly with an Arel SqlLiteral' do
              s = Person.ransack(sql_literal_id_in: 1)
              expect(s.result.count).to be 1
              s = Person.ransack(sql_literal_id_in: ['2', 4, '5', 8])
              expect(s.result.count).to be 4
            end
          end

          context "search on an `in` predicate with an array" do
            it "should function correctly when passing an array of ids" do
              array = Person.all.map(&:id)
              s = Person.ransack(id_in: array)
              expect(s.result.count).to eq array.size
            end
          end

          it "should function correctly when an attribute name ends with '_start'" do
            p = Person.create!(:new_start => 'Bar and foo', :name => 'Xiang')

            s = Person.ransack(:new_start_end => ' and foo')
            expect(s.result.to_a).to eq [p]

            s = Person.ransack(:name_or_new_start_start => 'Xia')
            expect(s.result.to_a).to eq [p]

            s = Person.ransack(:new_start_or_name_end => 'iang')
            expect(s.result.to_a).to eq [p]
          end

          it "should function correctly when an attribute name ends with '_end'" do
            p = Person.create!(:stop_end => 'Foo and bar', :name => 'Marianne')

            s = Person.ransack(:stop_end_start => 'Foo and')
            expect(s.result.to_a).to eq [p]

            s = Person.ransack(:stop_end_or_name_end => 'anne')
            expect(s.result.to_a).to eq [p]

            s = Person.ransack(:name_or_stop_end_end => ' bar')
            expect(s.result.to_a).to eq [p]
          end

          it "should function correctly when an attribute name has 'and' in it" do
            p = Person.create!(:terms_and_conditions => true)
            s = Person.ransack(:terms_and_conditions_eq => true)
            expect(s.result.to_a).to eq [p]
          end

          it 'allows sort by "only_sort" field' do
            s = Person.ransack(
              "s" => { "0" => { "dir" => "asc", "name" => "only_sort" } }
            )
            expect(s.result.to_sql).to match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_sort")} ASC/
            )
          end

          it "doesn't sort by 'only_search' field" do
            s = Person.ransack(
              "s" => { "0" => { "dir" => "asc", "name" => "only_search" } }
            )
            expect(s.result.to_sql).not_to match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_search")} ASC/
            )
          end

          it 'allows search by "only_search" field' do
            s = Person.ransack(:only_search_eq => 'htimS cirA')
            expect(s.result.to_sql).to match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_search")} = 'htimS cirA'/
            )
          end

          it "can't be searched by 'only_sort'" do
            s = Person.ransack(:only_sort_eq => 'htimS cirA')
            expect(s.result.to_sql).not_to match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_sort")} = 'htimS cirA'/
            )
          end

          it 'allows sort by "only_admin" field, if auth_object: :admin' do
            s = Person.ransack(
              { "s" => { "0" => { "dir" => "asc", "name" => "only_admin" } } },
              { auth_object: :admin }
            )
            expect(s.result.to_sql).to match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} ASC/
            )
          end

          it "doesn't sort by 'only_admin' field, if auth_object: nil" do
            s = Person.ransack(
              "s" => { "0" => { "dir" => "asc", "name" => "only_admin" } }
            )
            expect(s.result.to_sql).not_to match(
              /ORDER BY #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} ASC/
            )
          end

          it 'allows search by "only_admin" field, if auth_object: :admin' do
            s = Person.ransack(
              { :only_admin_eq => 'htimS cirA' },
              { :auth_object => :admin }
            )
            expect(s.result.to_sql).to match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} = 'htimS cirA'/
            )
          end

          it "can't be searched by 'only_admin', if auth_object: nil" do
            s = Person.ransack(:only_admin_eq => 'htimS cirA')
            expect(s.result.to_sql).not_to match(
              /WHERE #{quote_table_name("people")}.#{
                quote_column_name("only_admin")} = 'htimS cirA'/
            )
          end

          it 'should allow passing ransacker arguments to a ransacker' do
            s = Person.ransack(
              c: [{
                a: {
                  '0' => {
                    name: 'with_arguments', ransacker_args: [10, 100]
                  }
                },
                p: 'cont',
                v: ['Passing arguments to ransackers!']
              }]
            )
            expect(s.result.to_sql).to match(
              /LENGTH\(articles.body\) BETWEEN 10 AND 100/
            )
            expect(s.result.to_sql).to match(
              /LIKE \'\%Passing arguments to ransackers!\%\'/
              )
            expect { s.result.first }.to_not raise_error
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
