require 'spec_helper'

# A negative condition on a collection is built as a correlated subquery
# over the association's table. The subquery keeps the join's own conditions
# along with the correlation: the type column of a polymorphic association,
# and the target's default scope. Before, it kept only the correlation, so a
# row the association does not reach (a note on another model with the same
# id, a disabled comment) still excluded the record (#1747).
module Ransack
  module ActiveRecord
    describe 'the correlated subquery for a negative condition on a collection' do
      def t(name) = quote_table_name(name)
      def c(name) = quote_column_name(name)

      let(:suffix) { SecureRandom.hex(4) }

      # Rows persist across examples, and other specs count them.
      after do
        Note.unscoped.where('note LIKE ?', "%#{suffix}%").delete_all
        Comment.unscoped.where('body LIKE ?', "%#{suffix}%").delete_all
        Article.unscoped.where('title LIKE ?', "%#{suffix}%").delete_all
        Person.unscoped.where('name LIKE ?', "%#{suffix}%").delete_all
      end

      describe 'on a polymorphic has_many' do
        let!(:article) { Article.create!(title: "polymorphic #{suffix}") }
        let(:note)     { "spam #{suffix}" }

        def articles(params)
          Article.ransack(params.merge(title_eq: article.title)).result.to_a
        end

        it 'checks the type column' do
          sql = Article.ransack(notes_note_not_eq: 'x').result.to_sql
          expect(sql).to include("#{t('notes')}.#{c('notable_type')} = 'Article'")
        end

        it 'ignores a note on another model with the same id' do
          Note.create!(notable_type: 'Person', notable_id: article.id, note: note)
          expect(articles(notes_note_not_eq: note)).to eq [article]
        end

        it 'still excludes a record with a matching note of its own' do
          Note.create!(notable: article, note: note)
          expect(articles(notes_note_not_eq: note)).to be_empty
        end

        it 'checks the type column for not_in and not_cont' do
          Note.create!(notable_type: 'Person', notable_id: article.id, note: note)
          expect(articles(notes_note_not_in: [note])).to eq [article]
          expect(articles(notes_note_not_cont: suffix)).to eq [article]
        end

        it 'checks the type column for not_null' do
          Note.create!(notable_type: 'Person', notable_id: article.id, note: note)
          expect(articles(notes_note_not_null: true)).to be_empty
          expect(articles(notes_note_not_null: false)).to eq [article]
        end

        it 'checks the type column from the other side' do
          person = Person.create!(name: "polymorphic #{suffix}")
          Note.create!(notable_type: 'Article', notable_id: person.id, note: note)
          result = Person.ransack(notes_note_not_eq: note, name_eq: person.name).result.to_a
          expect(result).to eq [person]
        end
      end

      describe 'on a has_many whose target has a default scope' do
        let!(:person) { Person.create!(name: "scoped #{suffix}") }
        let(:body)    { "body #{suffix}" }

        def people(params)
          Person.ransack(params.merge(name_eq: person.name)).result.to_a
        end

        it 'applies the default scope' do
          sql = Person.ransack(comments_body_not_eq: 'x').result.to_sql
          expect(sql).to match(/NOT IN \(SELECT .*#{Regexp.escape("#{t('comments')}.#{c('disabled')}")} = /)
        end

        it 'ignores a record the default scope hides' do
          Comment.create!(person: person, body: body, disabled: true)
          expect(people(comments_body_not_eq: body)).to eq [person]
        end

        it 'still excludes a record with a matching visible comment' do
          Comment.create!(person: person, body: body)
          expect(people(comments_body_not_eq: body)).to be_empty
        end

        # The default scope's value is a bind; the subquery is embedded as a
        # string, so the value has to be inlined rather than left as `?`.
        it 'inlines the default scope value' do
          sql = Person.ransack(comments_body_not_eq: 'x').result.to_sql
          subquery = sql[/NOT IN \(SELECT .*\)/]
          expect(subquery).not_to include('?')
          expect(subquery).not_to match(/\$\d/)
        end
      end

      describe 'on a has_many whose target has a literal default scope' do
        it 'keeps the literal in the subquery' do
          sql = Person.ransack(articles_title_not_eq: 'x').result.to_sql
          expect(sql[/NOT IN \(SELECT .*\)/]).to include("('default_scope' = 'default_scope')")
        end

        it 'correlates once' do
          sql = Person.ransack(articles_title_not_eq: 'x').result.to_sql
          correlation = "#{t('articles')}.#{c('person_id')} = #{t('people')}.#{c('id')}"
          expect(sql.scan(correlation).size).to eq 1
        end
      end

      describe 'on a has_and_belongs_to_many' do
        it 'is unchanged' do
          sql = Article.ransack(tags_name_not_eq: 'x').result.to_sql
          expect(sql).to include(
            "#{t('articles')}.#{c('id')} NOT IN (SELECT #{t('articles_tags')}.#{c('article_id')} " \
            "FROM #{t('articles_tags')} INNER JOIN #{t('tags')} ON #{t('tags')}.#{c('id')} = #{t('articles_tags')}.#{c('tag_id')} " \
            "WHERE #{t('articles_tags')}.#{c('article_id')} = #{t('articles')}.#{c('id')} AND NOT ("
          )
        end
      end
    end
  end
end
