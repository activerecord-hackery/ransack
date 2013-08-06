require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe Context do
        subject { Context.new(Person) }

        describe '#relation_for' do
          it 'returns relation for given object' do
            subject.object.should be_an ::ActiveRecord::Relation
          end
        end

        describe '#evaluate' do
          it 'evaluates search obects' do
            search = Search.new(Person, :name_eq => 'Joe Blow')
            result = subject.evaluate(search)

            result.should be_an ::ActiveRecord::Relation
            result.to_sql.should match /"name" = 'Joe Blow'/
          end

          it 'SELECTs DISTINCT when :distinct => true' do
            search = Search.new(Person, :name_eq => 'Joe Blow')
            result = subject.evaluate(search, :distinct => true)

            result.should be_an ::ActiveRecord::Relation
            result.to_sql.should match /SELECT DISTINCT/
          end
        end

        it 'contextualizes strings to attributes' do
          attribute = subject.contextualize 'children_children_parent_name'
          attribute.should be_a Arel::Attributes::Attribute
          attribute.name.to_s.should eq 'name'
          attribute.relation.table_alias.should eq 'parents_people'
        end

        it 'builds new associations if not yet built' do
          attribute = subject.contextualize 'children_articles_title'
          attribute.should be_a Arel::Attributes::Attribute
          attribute.name.to_s.should eq 'title'
          attribute.relation.name.should eq 'articles'
          attribute.relation.table_alias.should be_nil
        end

      end
    end
  end
end