require 'mongoid_spec_helper'

module Ransack
  module Adapters
    module Mongoid
      describe Context do
        subject { Context.new(Person) }

        describe '#relation_for' do
          before { pending "not implemented for mongoid" }
          it 'returns relation for given object' do
            expect(subject.object).to be_an ::ActiveRecord::Relation
          end
        end

        describe '#evaluate' do
          it 'evaluates search objects' do
            search = Search.new(Person, :name_eq => 'Joe Blow')
            result = subject.evaluate(search)

            expect(result).to be_an ::Mongoid::Criteria
            expect(result.selector).to eq({ 'name' => 'Joe Blow' })
          end

          it 'SELECTs DISTINCT when distinct: true' do
            pending "distinct doesn't work"

            search = Search.new(Person, :name_eq => 'Joe Blow')
            result = subject.evaluate(search, :distinct => true)

            expect(result).to be_an ::ActiveRecord::Relation
            expect(result.to_sql).to match /SELECT DISTINCT/
          end
        end

        it 'contextualizes strings to attributes' do
          attribute = subject.contextualize 'name'
          expect(attribute).to be_a ::Ransack::Adapters::Mongoid::Attributes::Attribute
          expect(attribute.name.to_s).to eq 'name'
          # expect(attribute.relation.table_alias).to eq 'parents_people'
        end

        it 'builds new associations if not yet built' do
          pending "not implemented for mongoid"

          attribute = subject.contextualize 'children_articles_title'
          expect(attribute).to be_a Arel::Attributes::Attribute
          expect(attribute.name.to_s).to eq 'title'
          expect(attribute.relation.name).to eq 'articles'
          expect(attribute.relation.table_alias).to be_nil
        end

      end
    end
  end
end
