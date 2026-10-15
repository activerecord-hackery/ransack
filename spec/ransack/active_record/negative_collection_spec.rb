require 'spec_helper'

# A negative condition on a collection is built as a correlated subquery,
# and the join Ransack had added for the association is dropped. The
# condition keeps the association and builds the subquery from it again each
# time the search is evaluated, and every other negative condition on the
# same association builds its own from it too. In 6.0.0 the association's
# parent was forgotten when the join was dropped, so a second call to
# `result`, or a second negative condition on the same collection, raised
# NoMethodError (#1745).
module Ransack
  module ActiveRecord
    describe 'negative conditions on a collection' do
      def t(name) = quote_table_name(name)
      def c(name) = quote_column_name(name)
      def subquery_count(sql) = sql.scan(/IN \(SELECT/).size
      def outer_query(sql) = sql.split('IN (SELECT').first

      # Every call gives the same SQL, and the SQL runs.
      def expect_stable(search, opts = {})
        sqls = Array.new(3) { search.result(opts).to_sql }
        expect(sqls.uniq.size).to eq 1
        expect { search.result(opts).to_a }.not_to raise_error
        sqls.first
      end

      describe 'evaluating the search more than once' do
        it 'gives the same SQL on a has_and_belongs_to_many' do
          sql = expect_stable(Article.ransack(tags_name_not_in: ['ruby']))
          expect(sql).to include('NOT IN (SELECT')
          expect(outer_query(sql)).not_to include('JOIN')
        end

        it 'gives the same SQL on a has_many' do
          sql = expect_stable(Person.ransack(articles_title_not_eq: 'Draft'))
          expect(subquery_count(sql)).to eq 1
          expect(sql).to include("#{t('articles')}.#{c('person_id')} = #{t('people')}.#{c('id')}")
        end

        it 'gives the same SQL when the collection has a default scope' do
          sql = expect_stable(Person.ransack(comments_body_not_eq: 'x'))
          expect(sql).to include("#{t('comments')}.#{c('person_id')} = #{t('people')}.#{c('id')}")
        end

        it 'gives the same SQL on a polymorphic has_many' do
          sql = expect_stable(Article.ransack(notes_note_not_eq: 'x'))
          expect(sql).to include("#{t('notes')}.#{c('notable_id')} = #{t('articles')}.#{c('id')}")
        end

        it 'gives the same SQL through a nested has_and_belongs_to_many' do
          expect_stable(Article.ransack(comments_tags_name_not_eq: 'x'))
        end

        %w[
          not_eq not_in not_cont not_start not_end not_i_cont
          not_eq_any not_eq_all not_cont_any not_cont_all
        ].each do |predicate|
          it "gives the same SQL for #{predicate}" do
            value = predicate.end_with?('_in', '_any', '_all') ? %w[a b] : 'a'
            sql = expect_stable(Person.ransack("articles_title_#{predicate}" => value))
            expect(sql).to include('NOT IN (SELECT')
          end
        end

        it 'gives the same SQL for not_null: true' do
          sql = expect_stable(Person.ransack(articles_title_not_null: true))
          expect(sql).to include("#{t('people')}.#{c('id')} IN (SELECT")
        end

        it 'gives the same SQL for not_null: false' do
          sql = expect_stable(Person.ransack(articles_title_not_null: false))
          expect(sql).to include('NOT IN (SELECT')
        end

        it 'gives the same SQL with a sort on the model' do
          sql = expect_stable(Person.ransack(articles_title_not_eq: 'Draft', s: 'name asc'))
          expect(sql).to include("ORDER BY #{t('people')}.#{c('name')} ASC")
        end

        it 'gives the same SQL with distinct' do
          sql = expect_stable(Person.ransack(articles_title_not_eq: 'Draft'), distinct: true)
          expect(sql).to include('SELECT DISTINCT')
        end

        it 'gives the same SQL with a positive condition on another association' do
          sql = expect_stable(Person.ransack(articles_title_not_eq: 'Draft', comments_body_eq: 'x'))
          expect(sql).to include("LEFT OUTER JOIN #{t('comments')}")
          expect(sql).not_to include("JOIN #{t('articles')}")
        end

        # The positive condition locks the join, so it stays alongside the
        # subquery.
        it 'gives the same SQL with a positive condition on the same association' do
          sql = expect_stable(Person.ransack(articles_title_not_eq: 'Draft', articles_body_eq: 'x'))
          expect(sql).to include("LEFT OUTER JOIN #{t('articles')}")
          expect(subquery_count(sql)).to eq 1
        end

        it 'gives the same SQL combined with or' do
          sql = expect_stable(Person.ransack(articles_title_not_eq: 'Draft', name_eq: 'x', m: 'or'))
          expect(sql).to include(' OR ')
        end

        it 'gives the same SQL on a relation that already joins the collection' do
          sql = expect_stable(Article.joins(:tags).ransack(tags_name_not_eq: 'x'))
          expect(outer_query(sql).scan(/JOIN #{Regexp.escape(t('tags'))}/).size).to eq 1
        end

        it 'gives the same SQL on a search sharing its context' do
          context = Context.for(Person)
          search = Search.new(Person, { articles_title_not_eq: 'Draft' }, context: context)
          expect_stable(search)
        end
      end

      describe 'several negative conditions on the same collection' do
        it 'builds a subquery for each condition' do
          sql = expect_stable(Person.ransack(articles_title_not_eq: 'Draft', articles_body_not_cont: 'spam'))
          expect(subquery_count(sql)).to eq 2
          expect(outer_query(sql)).not_to include('JOIN')
        end

        it 'builds a subquery for each attribute of an _or_ condition' do
          sql = expect_stable(Person.ransack(articles_title_or_articles_body_not_eq: 'x'))
          expect(subquery_count(sql)).to eq 2
          expect(sql).to include(' OR ')
        end

        it 'builds a subquery for each attribute of an _and_ condition' do
          sql = expect_stable(Person.ransack(articles_title_and_articles_body_not_eq: 'x'))
          expect(subquery_count(sql)).to eq 2
        end

        it 'builds a subquery for each condition across groupings' do
          search = Person.ransack(
            m: 'or',
            g: [{ articles_title_not_eq: 'a' }, { articles_body_not_eq: 'b' }]
          )
          sql = expect_stable(search)
          expect(subquery_count(sql)).to eq 2
        end

        it 'builds a subquery for each condition on a has_and_belongs_to_many' do
          sql = expect_stable(Article.ransack(tags_name_not_eq: 'a', tags_name_not_in: %w[b c]))
          expect(subquery_count(sql)).to eq 2
        end
      end

      describe 'the records returned' do
        let(:suffix)   { SecureRandom.hex(4) }
        let!(:ruby)    { Tag.create!(name: "ruby-#{suffix}") }
        let!(:rails)   { Tag.create!(name: "rails-#{suffix}") }
        let!(:tagged_ruby)  { Article.create!(title: "ruby #{suffix}").tap { |a| a.tags << ruby } }
        let!(:tagged_rails) { Article.create!(title: "rails #{suffix}").tap { |a| a.tags << rails } }
        let!(:untagged)     { Article.create!(title: "none #{suffix}") }

        let!(:drafter)  { Person.create!(name: "drafter #{suffix}").tap { |p| p.articles.create!(title: 'Draft', body: 'ok') } }
        let!(:spammer)  { Person.create!(name: "spammer #{suffix}").tap { |p| p.articles.create!(title: 'Post', body: 'spam here') } }
        let!(:writer)   { Person.create!(name: "writer #{suffix}").tap { |p| p.articles.create!(title: 'Post', body: 'ok') } }
        let!(:idle)     { Person.create!(name: "idle #{suffix}") }

        # Rows persist across examples, and other specs count them.
        after do
          [tagged_ruby, tagged_rails].each { |article| article.tags.clear }
          [tagged_ruby, tagged_rails, untagged, ruby, rails].each(&:delete)
          people = [drafter, spammer, writer, idle]
          Article.unscoped.where(person_id: people.map(&:id)).delete_all
          people.each(&:delete)
        end

        it 'are the same on every call (the #1745 repro)' do
          search = Article.ransack(tags_name_not_in: [ruby.name], title_end: suffix)
          first = search.result.to_a
          second = search.result.to_a
          expect(first).to match_array [tagged_rails, untagged]
          expect(second).to match_array first
        end

        it 'exclude a record with any matching associated record on every call' do
          search = Person.ransack(articles_title_not_eq: 'Draft', name_end: suffix)
          2.times do
            expect(search.result.to_a).to match_array [spammer, writer, idle]
          end
        end

        it 'exclude records matching either of two conditions on the same collection' do
          search = Person.ransack(articles_title_not_eq: 'Draft', articles_body_not_cont: 'spam', name_end: suffix)
          2.times do
            expect(search.result.to_a).to match_array [writer, idle]
          end
        end

        it 'include records matching neither attribute of an _or_ condition' do
          search = Person.ransack(articles_title_or_articles_body_not_eq: 'Draft', name_end: suffix)
          expect(search.result.to_a).to match_array [drafter, spammer, writer, idle]

          search = Person.ransack(articles_title_and_articles_body_not_eq: 'Draft', name_end: suffix)
          expect(search.result.to_a).to match_array [spammer, writer, idle]
        end

        it 'keep the same order and count when the result is reused' do
          search = Person.ransack(articles_title_not_eq: 'Draft', name_end: suffix, s: 'name asc')
          expect(search.result.pluck(:name)).to eq ["idle #{suffix}", "spammer #{suffix}", "writer #{suffix}"]
          expect(search.result.count).to eq 3
          expect(search.result.order_values).to eq search.result.order_values
        end
      end
    end

    describe Context do
      describe '#remove_association' do
        let(:context) { Context.for(Person) }
        let(:search)  { Search.new(Person, { articles_title_not_eq: 'Draft' }, context: context) }
        let(:association) { search.conditions.first.attributes.first.parent }

        it 'keeps the subquery buildable once the join is removed' do
          before_removal = context.build_correlated_subquery(association).to_sql
          context.remove_association(association)
          expect(context.build_correlated_subquery(association).to_sql).to eq before_removal
        end

        it 'drops the join from the relation' do
          context.remove_association(association)
          expect(context.object.left_outer_joins_values).to be_empty
        end

        it 'is safe to call again' do
          2.times { context.remove_association(association) }
          expect(context.build_correlated_subquery(association)).to be_a Arel::SelectManager
        end

        # A later binding must not reuse the removed node: its join is gone
        # from the relation.
        it 'does not hand the removed association to a later binding' do
          context.remove_association(association)
          attribute = Nodes::Attribute.new(context, 'articles_body')
          context.bind(attribute, attribute.name)
          expect(attribute.parent).not_to equal association
          expect(attribute.parent.reflection.name).to eq :articles
        end

        it 'leaves a locked association in place' do
          context.lock_association(association)
          context.remove_association(association)
          expect(context.object.left_outer_joins_values).not_to be_empty
        end
      end
    end
  end
end
