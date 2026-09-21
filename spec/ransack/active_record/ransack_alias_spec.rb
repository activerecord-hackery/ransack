require 'spec_helper'

# Person has `ransack_alias :term, :name_or_email` and
# `ransack_alias :daddy, :parent_name`; Article belongs_to :person.
module Ransack
  module ActiveRecord
    describe 'ransack_alias' do
      def column(table, name)
        "#{quote_table_name(table)}.#{quote_column_name(name)}"
      end

      it 'expands an alias on the searched model' do
        sql = Person.ransack(term_cont: 'a').result.to_sql
        expect(sql).to include(column('people', 'name'))
        expect(sql).to include(column('people', 'email'))
      end

      # The alias was only looked up on the searched model, so one reached
      # through an association produced a column that does not exist (#1520).
      it 'expands an alias defined on an associated model' do
        sql = Article.ransack(person_term_cont: 'a').result.to_sql
        expect(sql).to include("#{column('people', 'name')} LIKE '%a%'")
        expect(sql).to include("#{column('people', 'email')} LIKE '%a%'")
        expect(sql).not_to include('term')
        expect { Article.ransack!(person_term_cont: 'a').result.to_a }.not_to raise_error
      end

      it 'expands an alias combined with an association attribute' do
        sql = Person.ransack(term_or_parent_name_cont: 'a').result.to_sql
        expect(sql).to include(column('people', 'name'))
        expect(sql).to include(column('parents_people', 'name'))
      end

      # Two aliases in one name were bound as columns and produced SQL that
      # failed at execution (#847).
      it 'expands two aliases in one compound' do
        sql = Person.ransack(term_or_daddy_cont: 'Bob').result.to_sql
        expect(sql).to include(column('people', 'email'))
        expect(sql).to include(column('parents_people', 'name'))
        expect { Person.ransack!(term_or_daddy_cont: 'Bob').result.to_a }.not_to raise_error
      end

      it 'reads the value back under the aliased name through an association' do
        search = Article.ransack(person_term_cont: 'a')
        expect(search.person_term_cont).to eq 'a'
      end

      it 'sorts through an alias on an associated model' do
        sql = Article.ransack(s: 'person_daddy asc').result.to_sql
        expect(sql).to include("ORDER BY #{column('parents_people', 'name')} ASC")
      end

      # An alias whose target does not exist was dropped even under ransack!,
      # because the alias name itself passed the allowlist (#741).
      describe 'an alias pointing at a missing attribute' do
        let(:model) do
          Class.new(Person) do
            def self.name
              'PersonWithBrokenAlias'
            end
            ransack_alias :nick, :nonexistent_column
          end
        end

        it 'is dropped under a permissive search' do
          expect(model.ransack(nick_eq: 'x').result.to_sql).not_to include('nonexistent')
        end

        it 'raises under a strict search' do
          expect { model.ransack!(nick_eq: 'x') }
            .to raise_error(InvalidSearchError, 'Invalid search term nick_eq')
        end
      end

      # Person has a `true_or_false` column and a `terms_and_conditions` column.
      describe 'names that contain a combinator' do
        let(:model) do
          Class.new(Person) do
            def self.name
              'PersonWithCombinatorAliases'
            end
            ransack_alias :true, :name
            ransack_alias :consent, :terms_and_conditions
          end
        end
        let(:article_model) do
          person_model = model
          Class.new(Article) do
            def self.name
              'ArticleWithCombinatorAliases'
            end
            belongs_to :person, class_name: person_model.name, anonymous_class: person_model
          end
        end

        it 'leaves a real attribute alone even when an alias matches its first segment' do
          sql = model.ransack(true_or_false_eq: true).result.to_sql
          expect(sql).to include(column('people', 'true_or_false'))
          expect(sql).not_to include(column('people', 'name'))
        end

        it 'prefixes an associated alias whose target is one attribute as a whole' do
          sql = article_model.ransack(person_consent_eq: true).result.to_sql
          expect(sql).to include(column('people', 'terms_and_conditions'))
          expect { article_model.ransack!(person_consent_eq: true).result.to_a }.not_to raise_error
        end
      end

      it 'does not need the alias itself allowlisted, only its targets' do
        allow(Person).to receive(:ransackable_attributes).and_return(%w[name email])
        sql = Person.ransack!(term_cont: 'a').result.to_sql
        expect(sql).to include(column('people', 'email'))
      end
    end
  end
end
