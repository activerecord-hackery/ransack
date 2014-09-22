require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      version = ::ActiveRecord::VERSION
      AR_version = "#{version::MAJOR}.#{version::MINOR}"

      describe Context do
        subject { Context.new(Person) }

        if AR_version >= "3.1"
          its(:alias_tracker) {
            should be_a ::ActiveRecord::Associations::AliasTracker
          }
        end

        describe '#relation_for' do
          it 'returns relation for given object' do
            expect(subject.object).to be_an ::ActiveRecord::Relation
          end
        end

        describe '#evaluate' do
          it 'evaluates search objects' do
            search = Search.new(Person, :name_eq => 'Joe Blow')
            result = subject.evaluate(search)

            expect(result).to be_an ::ActiveRecord::Relation
            expect(result.to_sql)
            .to match /#{quote_column_name("name")} = 'Joe Blow'/
          end

          it 'SELECTs DISTINCT when distinct: true' do
            search = Search.new(Person, :name_eq => 'Joe Blow')
            result = subject.evaluate(search, :distinct => true)

            expect(result).to be_an ::ActiveRecord::Relation
            expect(result.to_sql).to match /SELECT DISTINCT/
          end
        end

        describe "sharing context across searches" do
          let(:shared_context) { Context.for(Person) }

          before do
            Search.new(Person, { :parent_name_eq => 'A' },
              context: shared_context)
            Search.new(Person, { :children_name_eq => 'B' },
              context: shared_context)
          end

          describe '#join_associations', :if => AR_version <= '4.0' do
            it 'returns dependent join associations for all searches run
                against the context' do
              parents, children = shared_context.join_associations

              expect(children.aliased_table_name).to eq "children_people"
              expect(parents.aliased_table_name).to eq "parents_people"
            end

            it 'can be rejoined to execute a valid query' do
              parents, children = shared_context.join_associations

              expect { Person.joins(parents).joins(children).to_a }
              .to_not raise_error
            end
          end

          describe '#join_sources' do
            # FIXME: fix this test for Rails 4.2.
            it 'returns dependent arel join nodes for all searches run against
            the context',
            :if => %w(3.1 3.2 4.0 4.1).include?(AR_version) do
              parents, children = shared_context.join_sources

              expect(children.left.name).to eq "children_people"
              expect(parents.left.name).to eq "parents_people"
            end

            it 'can be rejoined to execute a valid query',
            :if => AR_version >= '3.1' do
              parents, children = shared_context.join_sources

              expect { Person.joins(parents).joins(children).to_a }
              .to_not raise_error
            end
          end
        end

        it 'contextualizes strings to attributes' do
          attribute = subject.contextualize 'children_children_parent_name'
          expect(attribute).to be_a Arel::Attributes::Attribute
          expect(attribute.name.to_s).to eq 'name'
          expect(attribute.relation.table_alias).to eq 'parents_people'
        end

        it 'builds new associations if not yet built' do
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
