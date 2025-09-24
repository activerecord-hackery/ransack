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
      
      describe '#default_type' do
        let(:context) { Context.for(Person) }
        
        it 'returns predicate type when available' do
          condition = Condition.new(context)
          predicate = double('predicate', type: :datetime)
          condition.predicate = predicate
          
          expect(condition.default_type).to eq :datetime
        end
        
        it 'returns attribute type when predicate type is nil' do
          condition = Condition.new(context)
          predicate = double('predicate', type: nil)
          condition.predicate = predicate
          
          attribute = double('attribute', type: :string)
          condition.attributes << attribute
          
          expect(condition.default_type).to eq :string
        end
        
        it 'prioritizes ransacker type over regular attribute type' do
          condition = Condition.new(context)
          predicate = double('predicate', type: nil)
          condition.predicate = predicate
          
          # Regular attribute with integer type
          regular_attr = double('regular_attribute', 
            type: :integer, 
            ransacker: nil
          )
          
          # Ransacker attribute with explicit string type
          ransacker = double('ransacker', type: :string)
          ransacker_attr = double('ransacker_attribute',
            type: :string,
            ransacker: ransacker
          )
          
          # Add regular attribute first, ransacker second
          condition.attributes << regular_attr
          condition.attributes << ransacker_attr
          
          # Should prioritize ransacker type even though it's not first
          expect(condition.default_type).to eq :string
        end
        
        it 'handles empty attributes gracefully' do
          condition = Condition.new(context)
          predicate = double('predicate', type: nil)
          condition.predicate = predicate
          
          expect(condition.default_type).to be_nil
        end
        
        it 'falls back to first attribute when no ransackers present' do
          condition = Condition.new(context)
          predicate = double('predicate', type: nil)
          condition.predicate = predicate
          
          attr1 = double('attr1', type: :integer, ransacker: nil)
          attr2 = double('attr2', type: :string, ransacker: nil)
          
          condition.attributes << attr1
          condition.attributes << attr2
          
          # Should use first attribute when no ransackers
          expect(condition.default_type).to eq :integer
        end
      end
    end
  end
end
