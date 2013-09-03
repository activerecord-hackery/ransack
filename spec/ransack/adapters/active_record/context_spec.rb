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
          it 'evaluates search objects DISTINCTly by default' do
            search = Search.new(Person, :name_eq => 'Joe Blow')
            result = subject.evaluate(search)

            result.should be_an ::ActiveRecord::Relation
            result.to_sql.should match /"name" = 'Joe Blow'/
            result.to_sql.should match /SELECT DISTINCT/
          end

          describe 'with user defined custom options of distinct: false' do
            let(:previous_options) { Ransack.options.clone }

            before do 
              Ransack.configure do |config|
                config.context_options = { :distinct => false }
              end
            end

            it 'evaluates a search with the distinct: false option' do
              search = Search.new(Person, :name_eq => 'Joe Blow')

              result = subject.evaluate(search)

              result.should be_an ::ActiveRecord::Relation
              result.to_sql.should_not match /SELECT DISTINCT/ 
            end

            it 'evaluates searches with distinct: true when specified in search' do
              search = Search.new(Person, :name_eq => 'Joe Blow')
              result = subject.evaluate(search, :distinct => true)

              result.should be_an ::ActiveRecord::Relation
              result.to_sql.should match /SELECT DISTINCT/

              # Return to default options value
              Ransack.configure do |config|
                config.context_options = { :distinct => true }
              end
            end
          end

          it 'Does not SELECT DISTINCT when :distinct => false' do
            search = Search.new(Person, :name_eq => 'Joe Blow')
            result = subject.evaluate(search, :distinct => false)

            result.should be_an ::ActiveRecord::Relation
            result.to_sql.should_not match /SELECT DISTINCT/
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