require 'spec_helper'

module Ransack
  module Nodes
    describe Condition do
      context 'bug report #1245' do
        it 'preserves tuple behavior' do
          ransack_hash = {
              m: 'and',
              g: [
                { title_type_in: ['["title 1", ""]'] }
              ]
            }

          sql = Article.ransack(ransack_hash).result.to_sql
          expect(sql).to include("IN (('title 1', ''))")
        end
      end

      context 'with a null_sentinel' do
        let(:sentinel) { '__ransack_null__' }

        before { Ransack.configure { |c| c.null_sentinel = sentinel } }
        after { Ransack.configure { |c| c.null_sentinel = nil } }

        def where_clause(hash)
          sql = Person.ransack(hash).result.to_sql
          sql.split(/\bWHERE\b/, 2).last.to_s
             .split(/\bORDER BY\b/).first.to_s.strip
        end

        # `col` is quoted the way the current adapter would quote
        # `people.<col>`, so these assertions hold on SQLite, PostgreSQL
        # and MySQL/Trilogy alike, rather than assuming double quotes.
        def qcol(col)
          "#{quote_table_name('people')}.#{quote_column_name(col)}"
        end

        context 'on a string column, through _in' do
          it 'behaves as a plain _in with no sentinel present' do
            expect(where_clause(name_in: ['Aaron']))
              .to eq "#{qcol('name')} IN (#{quote_value('Aaron')})"
          end

          it 'ORs in IS NULL when the sentinel accompanies real values' do
            expect(where_clause(name_in: ['Aaron', sentinel]))
              .to eq "(#{qcol('name')} IN (#{quote_value('Aaron')}) " \
                     "OR #{qcol('name')} IS NULL)"
          end

          it 'is IS NULL alone when the sentinel is the only value' do
            expect(where_clause(name_in: [sentinel]))
              .to eq "#{qcol('name')} IS NULL"
          end
        end

        context 'on a string column, through _eq' do
          it 'is IS NULL when the sentinel is submitted' do
            expect(where_clause(name_eq: sentinel))
              .to eq "#{qcol('name')} IS NULL"
          end
        end

        context 'on an integer column, through _in' do
          it 'casts the real values and ORs in IS NULL' do
            expect(where_clause(salary_in: ['1', sentinel]))
              .to eq "(#{qcol('salary')} IN (1) OR #{qcol('salary')} IS NULL)"
          end
        end

        context 'on a date column, through _in' do
          # A date cast of the sentinel string yields nil, which the
          # default validator rejects. Without a sentinel-aware
          # `Predicate#validate`, this condition is dropped entirely
          # rather than reaching `Condition#format_predicate` at all.
          it 'is IS NULL alone when the sentinel is the only value' do
            expect(where_clause(life_start_in: [sentinel]))
              .to eq "#{qcol('life_start')} IS NULL"
          end

          it 'casts the real value and ORs in IS NULL' do
            date = quote_value('2020-01-01')
            expect(where_clause(life_start_in: ['2020-01-01', sentinel]))
              .to eq "(#{qcol('life_start')} IN (#{date}) " \
                     "OR #{qcol('life_start')} IS NULL)"
          end
        end

        context 'on an eq_any compound predicate' do
          it 'ORs in IS NULL alongside the compound' do
            expect(where_clause(name_eq_any: ['Aaron', sentinel]))
              .to eq "((#{qcol('name')} = #{quote_value('Aaron')}) " \
                     "OR #{qcol('name')} IS NULL)"
          end

          it 'is IS NULL alone when the sentinel is the only value' do
            expect(where_clause(name_eq_any: [sentinel]))
              .to eq "#{qcol('name')} IS NULL"
          end
        end

        context 'on an in_any compound predicate' do
          it 'ORs in IS NULL alongside the compound' do
            expect(where_clause(name_in_any: ['Aaron', sentinel]))
              .to eq "((#{qcol('name')} IN (#{quote_value('Aaron')})) " \
                     "OR #{qcol('name')} IS NULL)"
          end

          it 'is IS NULL alone when the sentinel is the only value' do
            expect(where_clause(name_in_any: [sentinel]))
              .to eq "#{qcol('name')} IS NULL"
          end
        end

        context 'the eq_all and in_all compound predicates, which are ambiguous and out of scope' do
          # Both are conjunctive: ORing IS NULL onto them would widen rather
          # than narrow, since a column can never equal two different real
          # values at once. They are excluded for the same reason the
          # negative predicates below are.
          it 'treats the sentinel as a literal value for eq_all' do
            expect(where_clause(name_eq_all: ['Aaron', sentinel]))
              .to eq "(#{qcol('name')} = #{quote_value('Aaron')} " \
                     "AND #{qcol('name')} = #{quote_value(sentinel)})"
          end

          it 'treats the sentinel as a literal value for in_all' do
            expect(where_clause(name_in_all: ['Aaron', sentinel]))
              .to eq "(#{qcol('name')} IN (#{quote_value('Aaron')}) " \
                     "AND #{qcol('name')} IN (#{quote_value(sentinel)}))"
          end
        end

        context 'the negative predicates, which are out of scope' do
          it 'treats the sentinel as a literal value for _not_in' do
            expect(where_clause(name_not_in: ['Aaron', sentinel]))
              .to eq "#{qcol('name')} NOT IN (#{quote_value('Aaron')}, " \
                     "#{quote_value(sentinel)})"
          end

          it 'treats the sentinel as a literal value for _not_eq' do
            expect(where_clause(name_not_eq: sentinel))
              .to eq "#{qcol('name')} != #{quote_value(sentinel)}"
          end
        end

        context 'the form round-trip' do
          it 'returns the sentinel alongside the real value, on a string column' do
            search = Person.ransack(name_in: ['Aaron', sentinel])
            expect(search.name_in).to match_array(['Aaron', sentinel])
          end

          it 'returns the sentinel uncast, on an integer column' do
            search = Person.ransack(salary_in: ['1', sentinel])
            expect(search.salary_in).to match_array([1, sentinel])
          end

          it 'returns the sentinel uncast, on a date column' do
            search = Person.ransack(life_start_in: ['2020-01-01', sentinel])
            expect(search.life_start_in).to match_array([Date.new(2020, 1, 1), sentinel])
          end
        end

        context 'with no null_sentinel configured' do
          before { Ransack.configure { |c| c.null_sentinel = nil } }

          it 'treats a sentinel-shaped value as a literal, when unset' do
            expect(where_clause(name_in: ['Aaron', sentinel]))
              .to eq "#{qcol('name')} IN (#{quote_value('Aaron')}, " \
                     "#{quote_value(sentinel)})"
          end
        end
      end

      context 'with an alias' do
        subject {
          Condition.extract(
            Context.for(Person), 'term_start', Person.first(2).map(&:name)
          )
        }

        specify { expect(subject.combinator).to eq 'or' }
        specify { expect(subject.predicate.name).to eq 'start' }

        it 'converts the alias to the correct attributes' do
          expect(subject.attributes.map(&:name)).to eq(['name', 'email'])
        end
      end

      context 'with multiple values and an _any predicate' do
        subject {
          Condition.extract(
            Context.for(Person), 'name_eq_any', Person.first(2).map(&:name)
          )
        }

        specify { expect(subject.values.size).to eq(2) }
      end

      describe '#negative?' do
        let(:context) { Context.for(Person) }
        let(:eq)      { Condition.extract(context, 'name_eq', 'A') }
        let(:not_eq)  { Condition.extract(context, 'name_not_eq', 'A') }

        specify { expect(not_eq.negative?).to be true }
        specify { expect(eq.negative?).to be false }
      end

      context 'with an invalid predicate' do
        subject {
          Condition.extract(
            Context.for(Person), 'name_invalid', Person.first.name
          )
        }

        context "when ignore_unknown_conditions is false" do
          before do
            Ransack.configure { |c| c.ignore_unknown_conditions = false }
          end

          specify { expect { subject }.to raise_error ArgumentError }
          specify { expect { subject }.to raise_error InvalidSearchError }
        end

        context "when ignore_unknown_conditions is true" do
          before do
            Ransack.configure { |c| c.ignore_unknown_conditions = true }
          end

          specify { expect(subject).to be_nil }
        end
      end

      context 'with an empty predicate' do
        subject {
          Condition.extract(
            Context.for(Person), 'full_name', Person.first.name
          )
        }

        context "when default_predicate = nil" do
          before do
            Ransack.configure { |c| c.default_predicate = nil }
          end

          specify { expect(subject).to be_nil }
        end

        context "when default_predicate = 'eq'" do
          before do
            Ransack.configure { |c| c.default_predicate = 'eq' }
          end

          specify { expect(subject).to eq Condition.extract(Context.for(Person), 'full_name_eq', Person.first.name) }
        end
      end

      context 'with wildcard string values' do
        # 'test%' must match values ending in a literal '%', not act as a
        # second wildcard, so the '%' is escaped and an ESCAPE clause is
        # emitted. See https://github.com/activerecord-hackery/ransack/issues/1581
        let(:escaped_value) { quote_value('%test\\%%') }
        let(:escape_clause) { "ESCAPE #{quote_value('\\')}" }

        let(:like) { 'LIKE' }

        it 'escapes wildcards in the value for LIKE predicates' do
          sql = Person.ransack(name_cont: 'test%').result.to_sql

          expect(sql).to include("#{like} #{escaped_value} #{escape_clause}")
          expect(sql).not_to include("NOT #{like}")
        end

        it 'escapes wildcards in the value for NOT LIKE predicates' do
          sql = Person.ransack(name_not_cont: 'test%').result.to_sql

          expect(sql).to include("NOT #{like} #{escaped_value} #{escape_clause}")
        end
      end

      context 'with negative conditions on associations' do
        it 'handles not_null predicate with true value correctly' do
          ransack_hash = { comments_id_not_null: true }
          sql = Person.ransack(ransack_hash).result.to_sql

          # Should generate an IN query with IS NOT NULL condition
          expect(sql).to include('IN (')
          expect(sql).to include('IS NOT NULL')
          expect(sql).not_to include('IS NULL')
        end

        it 'handles not_null predicate with false value correctly' do
          ransack_hash = { comments_id_not_null: false }
          sql = Person.ransack(ransack_hash).result.to_sql

          # Should generate a NOT IN query with IS NULL condition
          expect(sql).to include('NOT IN (')
          expect(sql).to include('IS NULL')
          expect(sql).not_to include('IS NOT NULL')
        end

        it 'handles not_cont predicate correctly' do
          ransack_hash = { comments_body_not_cont: 'test' }
          sql = Person.ransack(ransack_hash).result.to_sql

          # Should generate a NOT IN query with LIKE condition (not NOT LIKE)
          expect(sql).to include('NOT IN (')
          expect(sql).to include("LIKE '%test%'")
          expect(sql).not_to include("NOT LIKE '%test%'")
        end
      end

      context 'with nested conditions' do
        it 'correctly identifies non-nested conditions' do
          condition = Condition.extract(
            Context.for(Person), 'name_eq', 'Test'
          )

          # Create a mock parent table
          parent_table = Person.arel_table

          # Get the attribute name and make sure it starts with the table name
          attribute = condition.attributes.first
          expect(attribute.name).to eq('name')
          expect(parent_table.name).to eq('people')

          # The method should return false because 'name' doesn't start with 'people'
          result = condition.send(:not_nested_condition, attribute, parent_table)
          expect(result).to be false
        end

        it 'correctly identifies truly non-nested conditions when attribute name starts with table name' do
          # Create a condition with an attribute that starts with the table name
          condition = Condition.extract(
            Context.for(Person), 'name_eq', 'Test'
          )

          # Modify the attribute name to start with the table name for testing purposes
          attribute = condition.attributes.first
          allow(attribute).to receive(:name).and_return('people_name')

          # Create a parent table
          parent_table = Person.arel_table

          # Now the method should return true because 'people_name' starts with 'people'
          result = condition.send(:not_nested_condition, attribute, parent_table)
          expect(result).to be true
        end

        it 'correctly identifies nested conditions' do
          condition = Condition.extract(
            Context.for(Person), 'articles_title_eq', 'Test'
          )

          # Create a mock table alias
          parent_table = Arel::Nodes::TableAlias.new(
            Article.arel_table,
            Article.arel_table
          )

          # Access the private method using send
          result = condition.send(:not_nested_condition, condition.attributes.first, parent_table)

          # Should return false for nested condition
          expect(result).to be false
        end
      end

      context 'with polymorphic associations and not_in predicate' do
        before do
          # Define test models for polymorphic associations
          class ::TestTask < ::ActiveRecord::Base
            self.table_name = 'tasks'
            has_many :follows, primary_key: :uid, inverse_of: :followed, foreign_key: :followed_uid, class_name: 'TestFollow'
            has_many :users, through: :follows, source: :follower, source_type: 'TestUser'

            # Add ransackable_attributes method
            def self.ransackable_attributes(auth_object = nil)
              ["created_at", "id", "name", "uid", "updated_at"]
            end

            # Add ransackable_associations method
            def self.ransackable_associations(auth_object = nil)
              ["follows", "users"]
            end
          end

          class ::TestFollow < ::ActiveRecord::Base
            self.table_name = 'follows'
            belongs_to :follower, polymorphic: true, foreign_key: :follower_uid, primary_key: :uid
            belongs_to :followed, polymorphic: true, foreign_key: :followed_uid, primary_key: :uid

            # Add ransackable_attributes method
            def self.ransackable_attributes(auth_object = nil)
              ["created_at", "followed_type", "followed_uid", "follower_type", "follower_uid", "id", "updated_at"]
            end

            # Add ransackable_associations method
            def self.ransackable_associations(auth_object = nil)
              ["followed", "follower"]
            end
          end

          class ::TestUser < ::ActiveRecord::Base
            self.table_name = 'users'
            has_many :follows, primary_key: :uid, inverse_of: :follower, foreign_key: :follower_uid, class_name: 'TestFollow'
            has_many :tasks, through: :follows, source: :followed, source_type: 'TestTask'

            # Add ransackable_attributes method
            def self.ransackable_attributes(auth_object = nil)
              ["created_at", "id", "name", "uid", "updated_at"]
            end

            # Add ransackable_associations method
            def self.ransackable_associations(auth_object = nil)
              ["follows", "tasks"]
            end
          end

          # Create tables if they don't exist
          ::ActiveRecord::Base.lease_connection.create_table(:tasks, force: true) do |t|
            t.string :uid
            t.string :name
            t.timestamps null: false
          end

          ::ActiveRecord::Base.lease_connection.create_table(:follows, force: true) do |t|
            t.string :followed_uid, null: false
            t.string :followed_type, null: false
            t.string :follower_uid, null: false
            t.string :follower_type, null: false
            t.timestamps null: false
            t.index [:followed_uid, :followed_type]
            t.index [:follower_uid, :follower_type]
          end

          ::ActiveRecord::Base.lease_connection.create_table(:users, force: true) do |t|
            t.string :uid
            t.string :name
            t.timestamps null: false
          end
        end

        after do
          # Clean up test models and tables
          Object.send(:remove_const, :TestTask)
          Object.send(:remove_const, :TestFollow)
          Object.send(:remove_const, :TestUser)

          ::ActiveRecord::Base.lease_connection.drop_table(:tasks, if_exists: true)
          ::ActiveRecord::Base.lease_connection.drop_table(:follows, if_exists: true)
          ::ActiveRecord::Base.lease_connection.drop_table(:users, if_exists: true)
        end

        it 'correctly handles not_in predicate with polymorphic associations' do
          # Create the search
          search = TestTask.ransack(users_uid_not_in: ['uid_example'])
          sql = search.result.to_sql

          # Verify the SQL contains the expected NOT IN clause
          expect(sql).to include('NOT IN')
          expect(sql).to include("follower_uid")
          expect(sql).to include("followed_uid")
          expect(sql).to include("'uid_example'")

          # The SQL should include a reference to tasks.uid
          expect(sql).to include("tasks")
          expect(sql).to include("uid")

          # The SQL should include a reference to follows table
          expect(sql).to include("follows")
        end
      end
    end
  end
end
