require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe 'Redundant Join Prevention' do
        describe 'with nested associations' do
          it 'should not generate redundant LEFT OUTER JOINs when INNER JOINs already exist' do
            # Test case from issue: Comment.joins(article: :author).ransack(article_author_name_eq: 'abc')
            search = Comment.joins(article: :author).ransack(article_author_name_eq: 'test')
            sql = search.result.to_sql
            
            # Should contain only one JOIN to authors table
            authors_joins = sql.scan(/JOIN "authors"/).length
            
            expect(authors_joins).to eq(1), "Expected 1 join to authors table, but found #{authors_joins} in SQL: #{sql}"
            
            # Should not contain both INNER JOIN and LEFT OUTER JOIN to the same table
            expect(sql).not_to match(/INNER JOIN "authors".*LEFT OUTER JOIN "authors"/m), 
              "SQL should not contain both INNER JOIN and LEFT OUTER JOIN to authors table: #{sql}"
          end
          
          it 'should work correctly with simple single-level joins' do
            # Test case from issue: Comment.joins(:article).ransack(article_title_eq: 'abc')
            search = Comment.joins(:article).ransack(article_title_eq: 'test')
            sql = search.result.to_sql
            
            # Should contain only one JOIN to articles table
            articles_joins = sql.scan(/JOIN "articles"/).length
            
            expect(articles_joins).to eq(1), "Expected 1 join to articles table, but found #{articles_joins} in SQL: #{sql}"
          end
        end
      end
    end
  end
end