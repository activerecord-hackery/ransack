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

      # Active Record renders the eager load after the joins Ransack adds, so
      # a join Ransack nested under an eager-loaded one read a table that was
      # not joined yet (#1767).
      describe 'a join nested under an eager-loaded join' do
        before(:all) do
          connection = ::ActiveRecord::Base.lease_connection
          connection.create_table(:eager_authors, force: true)
          connection.create_table(:eager_profiles, force: true) { |t| t.integer :author_id }
          connection.create_table(:eager_articles, force: true) { |t| t.integer :author_id }
        end

        after(:all) do
          connection = ::ActiveRecord::Base.lease_connection
          %i[eager_authors eager_profiles eager_articles].each { |table| connection.drop_table(table, if_exists: true) }
        end

        before do
          stub_const('EagerAuthor', Class.new(ApplicationRecord) {
            self.table_name = 'eager_authors'
            has_one :profile, class_name: 'EagerProfile', foreign_key: :author_id
          })
          stub_const('EagerProfile', Class.new(ApplicationRecord) {
            self.table_name = 'eager_profiles'
            belongs_to :author, class_name: 'EagerAuthor'
          })
          stub_const('EagerArticle', Class.new(ApplicationRecord) {
            self.table_name = 'eager_articles'
            belongs_to :author, class_name: 'EagerAuthor'
          })
        end

        it 'joins the nested table after the eager-loaded one' do
          sql = EagerArticle.eager_load(:author).ransack(author_profile_id_not_null: true).result.to_sql
          expect(sql.index("JOIN #{t('eager_profiles')}")).to be > sql.index("JOIN #{t('eager_authors')}")
          expect(EagerArticle.eager_load(:author).ransack(author_profile_id_not_null: true).result.limit(10).size).to eq 0
        end

        it 'finds the records the nested condition matches' do
          with_profile = EagerArticle.create!(author: EagerAuthor.create!.tap { |a| EagerProfile.create!(author: a) })
          without_profile = EagerArticle.create!(author: EagerAuthor.create!)

          result = EagerArticle.eager_load(:author).ransack(author_profile_id_not_null: true).result.to_a
          expect(result).to eq [with_profile]
          expect(result.first.association(:author)).to be_loaded
          expect(EagerArticle.eager_load(:author).ransack(author_profile_id_null: true).result.to_a).to eq [without_profile]
        ensure
          [EagerArticle, EagerProfile, EagerAuthor].each(&:delete_all)
        end

        it 'reuses the eager-loaded join' do
          sql = EagerArticle.eager_load(:author).ransack(author_id_gt: 0, author_profile_id_not_null: true).result.to_sql
          expect(join_count(sql, 'eager_authors')).to eq 1
          expect(join_count(sql, 'eager_profiles')).to eq 1
        end

        it 'sorts on the nested table' do
          relation = EagerArticle.eager_load(:author).ransack(s: 'author_profile_id desc').result
          expect { relation.to_a }.not_to raise_error
        end

        it 'works with includes that will be eager loaded' do
          relation = EagerArticle.includes(:author).references(:author).ransack(author_profile_id_not_null: true).result
          expect { relation.to_a }.not_to raise_error
        end

        it 'works under an eager-loaded has_many' do
          relation = Person.eager_load(:articles).ransack(articles_comments_body_cont: 'x').result
          sql = relation.to_sql
          expect(sql.index("JOIN #{t('comments')}")).to be > sql.index("JOIN #{t('articles')}")
          expect(join_count(sql, 'articles')).to eq 1
          expect(relation.to_a).to match_array Person.joins(articles: :comments).where('comments.body LIKE ?', '%x%').distinct.to_a
        end

        it 'aliases a nested join back to the searched table' do
          relation = Organization.eager_load(:address).ransack(address_organization_name_cont: 'x').result
          expect(relation.to_sql).to include("JOIN #{t('organizations')} #{t('organizations_addresses')}").or include("JOIN #{t('organizations')} AS #{t('organizations_addresses')}")
          expect { relation.to_a }.not_to raise_error
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
