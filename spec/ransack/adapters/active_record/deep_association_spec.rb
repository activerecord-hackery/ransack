require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe 'Deep Association Search Bug from Issue' do
        
        describe 'test with restrictive ransackable configuration to reproduce bug' do
          before do
            # Clear any existing data
            Comment.delete_all
            Article.delete_all  
            Person.delete_all
            
            # Create test data
            @john = Person.create!(name: 'John Doe', email: 'john@example.com')
            @jane = Person.create!(name: 'Jane Smith', email: 'jane@example.com')
            
            @johns_post = Article.create!(person: @john, title: 'Johns Article', body: 'Content by John')
            @janes_post = Article.create!(person: @jane, title: 'Janes Article', body: 'Content by Jane')
            
            @johns_comment = Comment.create!(article: @johns_post, person: @john, body: 'Johns comment on his post')
            @janes_comment = Comment.create!(article: @janes_post, person: @jane, body: 'Janes comment on her post')
          end

          it 'should reproduce the issue with models that have missing intermediate ransackable associations - DEBUG' do
            # Debug version with more detailed tracing
            
            # Temporarily override Article's ransackable_associations to NOT include 'person'
            Article.define_singleton_method(:ransackable_associations) do |auth_object = nil|
              puts "Article.ransackable_associations called with auth_object: #{auth_object.inspect}"
              result = ['comments', 'tags', 'notes', 'recent_notes']  # Notice 'person' is missing!
              puts "Article.ransackable_associations returning: #{result.inspect}"
              result
            end
            
            begin
              puts "\n=== DEBUGGING: Testing with Article missing 'person' in ransackable_associations ==="
              
              search = Comment.ransack(article_person_email_cont: 'john@example.com')
              context = search.context
              
              # Test the intermediate steps
              puts "1. Testing Comment.get_association('article')"
              comment_article_assoc = context.send(:get_association, 'article', Comment)
              puts "   Result: #{comment_article_assoc ? comment_article_assoc.name : 'nil'}"
              
              puts "2. Testing Article.get_association('person') - this should fail"
              if comment_article_assoc
                article_person_assoc = context.send(:get_association, 'person', comment_article_assoc.klass)
                puts "   Result: #{article_person_assoc ? article_person_assoc.name : 'nil'}"
              end
              
              puts "3. Testing attribute_method?('article_person_email', Comment)"
              attr_method_result = context.attribute_method?('article_person_email', Comment)
              puts "   Result: #{attr_method_result}"
              
              puts "4. Attempting to execute the search"
              results = search.result.to_a
              puts "   Results count: #{results.count}"
              
              # This should fail if security is working correctly
              expect(attr_method_result).to be false
              
            ensure
              # Restore the original method
              Article.define_singleton_method(:ransackable_associations) do |auth_object = nil|
                authorizable_ransackable_associations
              end
            end
          end

          it 'should reproduce the issue with Comment missing article ransackable association' do
            # Similarly, if Comment doesn't declare 'article' as ransackable
            
            Comment.define_singleton_method(:ransackable_associations) do |auth_object = nil|
              ['person']  # Missing 'article'!
            end
            
            begin
              puts "\n=== Testing with Comment missing 'article' in ransackable_associations ==="
              
              search = Comment.ransack(article_person_email_cont: 'john@example.com')
              
              expect {
                results = search.result.to_a
                puts "Unexpected success: found #{results.count} results"
              }.to raise_error(Ransack::UntraversableAssociationError)
              
            ensure  
              # Restore
              Comment.define_singleton_method(:ransackable_associations) do |auth_object = nil|
                authorizable_ransackable_associations
              end
            end
          end

          it 'should work when all associations are properly declared' do
            # This should work with the default ApplicationRecord configuration
            search = Comment.ransack(article_person_email_cont: 'john@example.com') 
            results = search.result
            
            expect(results.count).to eq(1)
            expect(results.first).to eq(@johns_comment)
            
            # Verify the SQL is correct
            sql = results.to_sql.downcase
            expect(sql).to include('join')
            expect(sql).to include('articles')
            expect(sql).to include('people') 
            expect(sql).to include('email')
          end

          it 'should test the exact error condition from Ransack 4.3.0' do
            # Version 4.3.0 changed error handling - maybe this is where the issue lies
            
            Comment.define_singleton_method(:ransackable_associations) do |auth_object = nil|
              []  # No associations allowed
            end
            
            begin
              search = Comment.ransack(article_person_email_cont: 'john@example.com')
              
              # In 4.3.0, this should raise InvalidSearchError instead of ArgumentError
              expect {
                search.result.to_a
              }.to raise_error(Ransack::UntraversableAssociationError)
              
            ensure
              Comment.define_singleton_method(:ransackable_associations) do |auth_object = nil|
                authorizable_ransackable_associations
              end
            end
          end

          it 'should test edge case: Person missing email in ransackable_attributes' do
            # What if the final attribute isn't ransackable?
            
            Person.define_singleton_method(:ransackable_attributes) do |auth_object = nil|
              ['id', 'name']  # Missing 'email'!
            end
            
            begin
              search = Comment.ransack(article_person_email_cont: 'john@example.com')
              
              # This might not raise an error but return no results
              results = search.result.to_a
              puts "Results when email not ransackable: #{results.count}"
              
              # The search might succeed but return no results
              expect(results.count).to eq(0)
              
            ensure
              Person.define_singleton_method(:ransackable_attributes) do |auth_object = nil|
                authorizable_ransackable_attributes
              end
            end
          end
        end
      end
    end
  end
end