require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe 'Redundant Join Prevention' do
        describe 'with nested associations' do
          context 'when relation already has INNER JOINs' do
            it 'should not generate redundant LEFT OUTER JOINs for nested associations' do
              # Test case from issue: Comment.joins(article: :author).ransack(article_author_name_eq: 'abc')
              # This was generating both INNER JOIN and LEFT OUTER JOIN to authors table
              search = Comment.joins(article: :author).ransack(article_author_name_eq: 'test')
              sql = search.result.to_sql
              
              # Should contain only one JOIN to authors table
              authors_joins = sql.scan(/JOIN "authors"/).length
              expect(authors_joins).to eq(1), "Expected 1 join to authors table, but found #{authors_joins} in SQL: #{sql}"
              
              # Should not contain LEFT OUTER JOIN with aliased authors table
              expect(sql).not_to match(/LEFT OUTER JOIN "authors" "authors_\w+"/), 
                "SQL should not contain LEFT OUTER JOIN with aliased authors table: #{sql}"
              
              # Should contain WHERE clause referencing authors.name
              expect(sql).to match(/"authors"\."name" = 'test'/), 
                "SQL should contain WHERE clause for authors.name: #{sql}"
            end
            
            it 'should work correctly with simple single-level joins' do
              # Test case from issue: Comment.joins(:article).ransack(article_title_eq: 'abc')
              # This should continue to work as before (only one JOIN to articles)
              search = Comment.joins(:article).ransack(article_title_eq: 'test')
              sql = search.result.to_sql
              
              # Should contain only one JOIN to articles table
              articles_joins = sql.scan(/JOIN "articles"/).length
              expect(articles_joins).to eq(1), "Expected 1 join to articles table, but found #{articles_joins} in SQL: #{sql}"
              
              # Should contain WHERE clause referencing articles.title
              expect(sql).to match(/"articles"\."title" = 'test'/), 
                "SQL should contain WHERE clause for articles.title: #{sql}"
            end
          end
          
          context 'when relation has no existing joins' do
            it 'should generate appropriate LEFT OUTER JOINs for search conditions' do
              # When no existing joins, Ransack should create necessary LEFT OUTER JOINs
              search = Comment.ransack(article_author_name_eq: 'test')
              sql = search.result.to_sql
              
              # Should contain LEFT OUTER JOINs for both articles and authors
              expect(sql).to match(/LEFT OUTER JOIN "articles"/), 
                "SQL should contain LEFT OUTER JOIN for articles: #{sql}"
              expect(sql).to match(/LEFT OUTER JOIN "authors"/), 
                "SQL should contain LEFT OUTER JOIN for authors: #{sql}"
            end
          end
        end
      end
    end
  end
end