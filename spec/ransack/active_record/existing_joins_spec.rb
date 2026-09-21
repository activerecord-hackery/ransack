require 'spec_helper'

# A search on a relation that already carries joins — from `joins`,
# `left_outer_joins`, `includes` that will be eager loaded, or a previous
# search — reuses them: no duplicate join, and the condition is bound to the
# alias Active Record gives that join. Before 6.0 Ransack built its join tree
# from the model class and could not see any of them (#824, #1108, #1250,
# #1433, #1437, #1554).
module Ransack
  module ActiveRecord
    describe 'searching a relation that already has joins' do
      def t(name) = quote_table_name(name)
      def c(name) = quote_column_name(name)
      def join_count(sql, table) = sql.scan(/JOIN #{Regexp.escape(t(table))}/).size

      describe 'left_outer_joins' do
        it 'reuses the join instead of adding an aliased copy' do
          sql = Person.left_outer_joins(:articles).where(articles: { title: 'Bar' })
                      .ransack(articles_title_eq: 'Foo').result.to_sql
          expect(join_count(sql, 'articles')).to eq 1
          expect(sql).to include("#{t('articles')}.#{c('title')} = 'Foo'")
        end

        # A duplicate join on a has_many multiplied the rows (#824).
        it 'does not multiply rows on a has_many' do
          relation = Article.left_outer_joins(:comments).ransack(comments_body_cont: 'x').result
          expect(join_count(relation.to_sql, 'comments')).to eq 1
          expect(relation.count).to eq Article.left_outer_joins(:comments).where('comments.body LIKE ?', '%x%').count
        end

        it 'reuses a through join, in either param order' do
          conditions = { comments_person_name_cont: 'foo', tags_name_cont: 'bar' }
          [conditions, conditions.to_a.reverse.to_h].each do |params|
            sql = Article.left_outer_joins(:tags).ransack(params).result.to_sql
            expect(join_count(sql, 'tags')).to eq 1
            expect { Article.left_outer_joins(:tags).ransack(params).result.to_a }.not_to raise_error
          end
        end
      end

      describe 'joins' do
        it 'reuses a one-level join' do
          sql = Person.joins(:articles).where(articles: { title: 'Bar' })
                      .ransack(articles_title_eq: 'Foo').result.to_sql
          expect(join_count(sql, 'articles')).to eq 1
        end

        # Only top-level joins were recognised; a nested one got a redundant
        # aliased copy (#1433).
        it 'reuses a nested join' do
          sql = Comment.joins(article: :person).ransack(article_person_name_eq: 'abc').result.to_sql
          expect(sql).not_to include('LEFT OUTER JOIN')
          expect(sql.scan(/JOIN/).size).to eq 2
          expect(sql).to include("#{t('people')}.#{c('name')} = 'abc'")
        end

        # Two joins to the same table: the condition must land on the alias of
        # the association it names, whatever the join order (#1554).
        it 'binds the condition to the right alias when a table is joined twice' do
          person = Person.create!(name: 'existing-joins-p')
          target = Person.create!(name: 'existing-joins-t')
          recommendation = Recommendation.create!(person: person, target_person: target)

          relation = Recommendation.joins(:person, :target_person)
          expect(relation.ransack(target_person_name_eq: 'existing-joins-t').result).to include(recommendation)
          expect(relation.ransack(target_person_name_eq: 'existing-joins-p').result).not_to include(recommendation)
          expect(relation.ransack(person_name_eq: 'existing-joins-p', target_person_name_eq: 'existing-joins-t').result)
            .to include(recommendation)

          sql = relation.ransack(target_person_name_eq: 'x').result.to_sql
          expect(sql).to include("#{t('target_people_recommendations')}.#{c('name')} = 'x'")
        ensure
          recommendation&.delete
          Person.where(name: %w[existing-joins-p existing-joins-t]).delete_all
        end

        # `where(assoc: { ... })` makes Active Record alias the join to the
        # association name (#1437).
        it 'follows the alias a where hash gives the join' do
          relation = Article.joins(:person).where(person: { name: ['A', 'B'] }).ransack(person_name_eq: 'John').result
          expect(relation.to_sql).to include("#{t('person')}.#{c('name')} = 'John'")
          expect { relation.to_a }.not_to raise_error

          relation = Person.joins(:parent).where(parent: { name: ['A', 'B'] }).ransack(parent_name_eq: 'John').result
          expect(relation.to_sql).to include("#{t('parent')}.#{c('name')} = 'John'")
          expect { relation.to_a }.not_to raise_error
        end
      end

      describe 'includes that will be eager loaded' do
        # The eager load added its own join under pluck (#1108).
        it 'reuses the eager-load join' do
          relation = Person.includes(:articles).where(articles: { title: 'x' }).ransack(articles_body_eq: 'y').result
          plucked = []
          callback = ->(_name, _start, _finish, _id, payload) { plucked << payload[:sql] }
          ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { relation.pluck(:id) }
          sql = plucked.grep(/SELECT/).last

          expect(join_count(sql, 'articles')).to eq 1
          expect(join_count(relation.to_sql, 'articles')).to eq 1
        end
      end

      describe 'a previous search' do
        it 'reuses the join the previous search added' do
          relation = Person.ransack(articles_title_eq: 'Bar').result
          sql = relation.ransack(articles_title_eq: 'Foo').result.to_sql
          expect(join_count(sql, 'articles')).to eq 1
        end

        # Every chained search added another aliased join (#1250).
        it 'does not grow the joins on each chained search' do
          relation = Person.all
          %w[one two three].each do |term|
            relation = relation.ransack(articles_title_cont: term, articles_body_cont: term, m: 'or').result
          end
          expect(join_count(relation.to_sql, 'articles')).to eq 1
        end
      end

      describe 'Context.for with a relation' do
        it 'keeps the relation, joins included' do
          context = Context.for(Person.joins(:articles))
          expect(context.object.joins_values).to eq [:articles]
        end
      end

      describe 'a negative condition on a joined collection' do
        it 'keeps the relation join and adds the subquery' do
          sql = Article.joins(:tags).ransack(tags_name_not_eq: 'x').result.to_sql
          outer_query = sql.split('NOT IN (SELECT').first
          expect(join_count(outer_query, 'tags')).to eq 1
          expect(sql).to include('NOT IN (SELECT')
        end
      end
    end
  end
end
