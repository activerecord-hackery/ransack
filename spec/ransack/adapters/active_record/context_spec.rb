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

        describe '#extract_correlated_key' do
          it 'handles Arel::Nodes::And with multiple children correctly' do
            # This test specifically targets the bug where extract_correlated_key
            # only checks left/right of And nodes instead of all children

            # Create models that will trigger the issue with polymorphic associations
            # and default scopes creating multiple conditions
            Article.delete_all
            Note.delete_all

            article = Article.create!(title: 'Test Article', body: 'Test body', published: true)
            note = Note.create!(note: 'Test Note', notable: article)

            # This search should trigger the problematic code path where
            # extract_correlated_key gets an And node with multiple children
            search = Article.ransack(
              g: [
                {
                  m: "and",
                  c: [
                    {
                      a: ["notes_note"],
                      p: "not_cont_all",
                      v: ["test"],
                    }
                  ]
                }
              ]
            )

            # Let's see what SQL is actually generated first
            sql = search.result.to_sql
            puts "Generated SQL: #{sql}"

            # The bug would cause this to raise "NoMethodError: undefined method 'eq' for nil"
            # because extract_correlated_key returns nil for And nodes with more than 2 children
            expect { search.result.to_sql }.not_to raise_error
            
            # The SQL should contain proper conditions
            expect(sql).to include('notes')
            expect(sql).to include('NOT (')
          end

          it 'extract_correlated_key method directly returns the correct key for And nodes' do
            # Let's test the method directly to ensure it handles And nodes properly
            context = subject

            # Create a mock And node with multiple children to test the specific bug
            pk = context.send(:primary_key)
            
            # Create equality nodes - first two don't match, third one matches our primary key
            eq1 = Arel::Nodes::Equality.new(Arel::Attributes::Attribute.new(pk.relation, :other_id), Arel::Attributes::Attribute.new(pk.relation, :some_value))
            eq2 = Arel::Nodes::Equality.new(Arel::Attributes::Attribute.new(pk.relation, :another_id), Arel::Attributes::Attribute.new(pk.relation, :another_value))
            eq3 = Arel::Nodes::Equality.new(pk, Arel::Attributes::Attribute.new(pk.relation, :target_id))  # This should match and is in 3rd position

            # Create an And node with multiple children (more than just left/right)
            and_node = Arel::Nodes::And.new([eq1, eq2, eq3])

            # Verify the setup - and_node should have 3 children but left/right only covers first 2
            expect(and_node.children.length).to eq(3)
            expect(and_node.left).to eq(eq1)
            expect(and_node.right).to eq(eq2)
            expect(and_node.children[2]).to eq(eq3)  # This is the one that matches but won't be found by current code

            # Call extract_correlated_key directly - this should fail with current implementation
            result = context.send(:extract_correlated_key, and_node)

            # With the bug, this will be nil because the matching equality is in position 3
            # After the fix, it should find the correct key
            expect(result).not_to be_nil, "extract_correlated_key should find the matching key even when it's not in left/right position"
            expect(result.name).to eq(:target_id)
          end
        end
      end
    end
  end
end
