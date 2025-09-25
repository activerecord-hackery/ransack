require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe 'Deep Association Bug Fixed Test' do
        before do
          Comment.delete_all
          Article.delete_all  
          Person.delete_all
          
          @john = Person.create!(name: 'John Doe', email: 'john@example.com')
          @jane = Person.create!(name: 'Jane Smith', email: 'jane@example.com')
          
          @johns_post = Article.create!(person: @john, title: 'Johns Article', body: 'Content by John')
          @janes_post = Article.create!(person: @jane, title: 'Janes Article', body: 'Content by Jane')
          
          @johns_comment = Comment.create!(article: @johns_post, person: @john, body: 'Johns comment on his post')
          @janes_comment = Comment.create!(article: @janes_post, person: @jane, body: 'Janes comment on her post')
        end

        it 'should properly reject invalid deep association conditions' do
          # Override Article to not allow person association
          original_method = Article.method(:ransackable_associations)
          Article.define_singleton_method(:ransackable_associations) do |auth_object = nil|
            ['comments', 'tags', 'notes', 'recent_notes']  # Missing 'person'!
          end
          
          begin
            search = Comment.ransack(article_person_email_cont: 'john@example.com')
            
            # The security check should prevent condition creation
            expect(search.base.conditions.size).to eq(0)
            
            # Should return all records (no filtering applied)
            results = search.result.to_a
            expect(results.count).to eq(2)  # Both comments returned
            
          ensure
            Article.define_singleton_method(:ransackable_associations, original_method)
          end
        end

        it 'should work correctly when associations are properly configured' do
          # With default ApplicationRecord configuration, this should work
          search = Comment.ransack(article_person_email_cont: 'john@example.com')
          
          # Should create 1 valid condition
          expect(search.base.conditions.size).to eq(1)
          expect(search.base.conditions.first.valid?).to be true
          
          # Should return only John's comment
          results = search.result.to_a
          expect(results.count).to eq(1)
          expect(results.first).to eq(@johns_comment)
        end
      end
    end
  end
end