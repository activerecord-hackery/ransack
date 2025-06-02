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
        it 'properly quotes values with wildcards for LIKE predicates' do
          ransack_hash = { name_cont: 'test%' }
          sql = Person.ransack(ransack_hash).result.to_sql

          # The % should be properly quoted in the SQL
          expect(sql).to include("LIKE '%test%%'")
        end

        it 'properly quotes values with wildcards for NOT LIKE predicates' do
          ransack_hash = { name_not_cont: 'test%' }
          sql = Person.ransack(ransack_hash).result.to_sql

          # The % should be properly quoted in the SQL
          expect(sql).to include("NOT LIKE '%test%%'")
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
    end
  end
end
