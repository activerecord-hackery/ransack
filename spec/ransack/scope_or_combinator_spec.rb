require 'spec_helper'

module Ransack
  describe Search do
    describe 'scopes with OR combinator' do
      # Set up a test model with scopes for color-based searching
      before do
        # Add some test scopes to Person model for this test
        Person.class_eval do
          scope :red, -> { where(name: 'Red Person') }
          scope :green, -> { where(name: 'Green Person') }
          
          def self.ransackable_scopes(auth_object = nil)
            super + [:red, :green]
          end
        end
        
        # Create test data
        @red_person = Person.create!(name: 'Red Person', email: 'red@example.com')
        @green_person = Person.create!(name: 'Green Person', email: 'green@example.com')
        @blue_person = Person.create!(name: 'Blue Person', email: 'blue@example.com')
      end
      
      after do
        # Clean up test data
        Person.delete_all
      end

      context 'when conditions are two scopes' do
        let(:ransack) { Person.ransack(red: true, green: true, m: :or) }

        it 'supports :or combinator' do
          expect(ransack.base.combinator).to eq :or
        end

        it 'generates SQL containing OR' do
          sql = ransack.result.to_sql
          expect(sql).to include 'OR'
        end

        it 'returns records matching either scope' do
          results = ransack.result.to_a
          expect(results).to include(@red_person)
          expect(results).to include(@green_person)
          expect(results).not_to include(@blue_person)
        end
      end

      context 'when conditions are a scope and an attribute' do
        let(:ransack) { Person.ransack(red: true, name_cont: 'Green', m: :or) }

        it 'supports :or combinator' do
          expect(ransack.base.combinator).to eq :or
        end

        it 'generates SQL containing OR' do
          sql = ransack.result.to_sql
          expect(sql).to include 'OR'
        end

        it 'returns records matching either the scope or the attribute condition' do
          results = ransack.result.to_a
          expect(results).to include(@red_person)
          expect(results).to include(@green_person)
          expect(results).not_to include(@blue_person)
        end
      end
    end
  end
end