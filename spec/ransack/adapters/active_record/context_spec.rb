require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      version = ::ActiveRecord::VERSION
      AR_version = "#{version::MAJOR}.#{version::MINOR}"

      describe Context do
        subject { Context.new(Person) }

        it 'has an Active Record alias tracker method' do
          expect(subject.alias_tracker)
          .to be_an ::ActiveRecord::Associations::AliasTracker
        end

        describe '#relation_for' do
          it 'returns relation for given object' do
            expect(subject.object).to be_an ::ActiveRecord::Relation
          end
        end

        describe '#evaluate' do
          it 'evaluates search objects' do
            s = Search.new(Person, name_eq: 'Joe Blow')
            result = subject.evaluate(s)

            expect(result).to be_an ::ActiveRecord::Relation
            expect(result.to_sql)
            .to match /#{quote_column_name("name")} = 'Joe Blow'/
          end

          it 'SELECTs DISTINCT when distinct: true' do
            s = Search.new(Person, name_eq: 'Joe Blow')
            result = subject.evaluate(s, distinct: true)

            expect(result).to be_an ::ActiveRecord::Relation
            expect(result.to_sql).to match /SELECT DISTINCT/
          end
        end

        describe '#build_correlated_subquery' do
          it 'build correlated subquery for Root STI model' do
            search = Search.new(Person, { articles_title_not_eq: 'some_title' }, context: subject)
            attribute = search.conditions.first.attributes.first
            constraints = subject.build_correlated_subquery(attribute.parent).constraints
            constraint = constraints.first

            expect(constraints.length).to eql 1
            expect(constraint.left.name).to eql 'person_id'
            expect(constraint.left.relation.name).to eql 'articles'
            expect(constraint.right.name).to eql 'id'
            expect(constraint.right.relation.name).to eql 'people'
          end

          it 'build correlated subquery for Child STI model when predicate is not_eq' do
            search = Search.new(Person, { story_articles_title_not_eq: 'some_title' }, context: subject)
            attribute = search.conditions.first.attributes.first
            constraints = subject.build_correlated_subquery(attribute.parent).constraints
            constraint = constraints.first

            expect(constraints.length).to eql 1
            expect(constraint.left.relation.name).to eql 'articles'
            expect(constraint.left.name).to eql 'person_id'
            expect(constraint.right.relation.name).to eql 'people'
            expect(constraint.right.name).to eql 'id'
          end

          it 'build correlated subquery for Child STI model when predicate is eq' do
            search = Search.new(Person, { story_articles_title_not_eq: 'some_title' }, context: subject)
            attribute = search.conditions.first.attributes.first
            constraints = subject.build_correlated_subquery(attribute.parent).constraints
            constraint = constraints.first

            expect(constraints.length).to eql 1
            expect(constraint.left.relation.name).to eql 'articles'
            expect(constraint.left.name).to eql 'person_id'
            expect(constraint.right.relation.name).to eql 'people'
            expect(constraint.right.name).to eql 'id'
          end

          it 'build correlated subquery for multiple conditions (default scope)' do
            search = Search.new(Person, { comments_body_not_eq: 'some_title' })

            # Was
            # SELECT "people".* FROM "people" WHERE "people"."id" NOT IN (
            #   SELECT "comments"."disabled" FROM "comments"
            #   WHERE "comments"."disabled" = "people"."id"
            #     AND NOT ("comments"."body" != 'some_title')
            # ) ORDER BY "people"."id" DESC
            # Should Be
            # SELECT "people".* FROM "people" WHERE "people"."id" NOT IN (
            #   SELECT "comments"."person_id" FROM "comments"
            #   WHERE "comments"."person_id" = "people"."id"
            #     AND NOT ("comments"."body" != 'some_title')
            # ) ORDER BY "people"."id" DESC

            expect(search.result.to_sql).to match /.comments.\..person_id. = .people.\..id./
          end

          it 'handles Arel::Nodes::And with children' do
            # Create a mock Arel::Nodes::And with children for testing
            search = Search.new(Person, { articles_title_not_eq: 'some_title', articles_body_not_eq: 'some_body' }, context: subject)
            attribute = search.conditions.first.attributes.first
            constraints = subject.build_correlated_subquery(attribute.parent).constraints
            constraint = constraints.first

            expect(constraints.length).to eql 1
            expect(constraint.left.name).to eql 'person_id'
            expect(constraint.left.relation.name).to eql 'articles'
            expect(constraint.right.name).to eql 'id'
            expect(constraint.right.relation.name).to eql 'people'
          end

          it 'correctly extracts correlated key from complex AND conditions' do
            # Test with multiple nested conditions to ensure the children traversal works
            search = Search.new(
              Person,
              {
                articles_title_not_eq: 'title',
                articles_body_not_eq: 'body',
                articles_published_eq: true
              },
              context: subject
            )

            attribute = search.conditions.first.attributes.first
            constraints = subject.build_correlated_subquery(attribute.parent).constraints
            constraint = constraints.first

            expect(constraints.length).to eql 1
            expect(constraint.left.relation.name).to eql 'articles'
            expect(constraint.left.name).to eql 'person_id'
            expect(constraint.right.relation.name).to eql 'people'
            expect(constraint.right.name).to eql 'id'
          end

          it 'build correlated subquery for polymorphic & default_scope when predicate is not_cont_all' do
            search = Search.new(Article,
             g: [
               {
                 m: "and",
                 c: [
                   {
                     a: ["recent_notes_note"],
                     p: "not_eq",
                     v: ["some_note"],
                   }
                 ]
               }
             ],
            )

            expect(search.result.to_sql).to match /(.notes.\..note. != \'some_note\')/
          end
        end

        describe 'sharing context across searches' do
          let(:shared_context) { Context.for(Person) }

          before do
            Search.new(Person, { parent_name_eq: 'A' },
              context: shared_context)
            Search.new(Person, { children_name_eq: 'B' },
              context: shared_context)
          end

          describe '#join_sources' do
            it 'returns dependent arel join nodes for all searches run against
            the context' do
              parents, children = shared_context.join_sources
              expect(children.left.name).to eq "children_people"
              expect(parents.left.name).to eq "parents_people"
            end

            it 'can be rejoined to execute a valid query' do
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

        describe '#type_for' do
          it 'returns nil when column does not exist instead of raising NoMethodError' do
            # Create a mock attribute that references a non-existent column
            mock_attr = double('attribute')
            allow(mock_attr).to receive(:valid?).and_return(true)

            mock_arel_attr = double('arel_attribute')
            allow(mock_arel_attr).to receive(:relation).and_return(Person.arel_table)
            allow(mock_arel_attr).to receive(:name).and_return('nonexistent_column')
            allow(mock_attr).to receive(:arel_attribute).and_return(mock_arel_attr)
            allow(mock_attr).to receive(:klass).and_return(Person)

            # This should return nil instead of raising an error
            expect(subject.type_for(mock_attr)).to be_nil
          end
        end
      end
    end
  end
end
