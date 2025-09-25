require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe 'Deep Association Search Bug Reproduction' do
        
        # Create a scenario that definitely should fail if the bug exists
        describe 'isolated test with restrictive ransackable configuration' do
          # Create new AR models that DON'T use ApplicationRecord's permissive configuration
          before(:all) do
            # Create table for testing if needed
            ActiveRecord::Migration.verbose = false
            ActiveRecord::Schema.define do
              unless connection.table_exists?(:test_users)
                create_table :test_users, force: true do |t|
                  t.string :name
                  t.string :email
                end
              end
              
              unless connection.table_exists?(:test_posts)
                create_table :test_posts, force: true do |t|
                  t.references :test_user, null: false
                  t.string :title
                  t.text :body
                end
              end
              
              unless connection.table_exists?(:test_comments)
                create_table :test_comments, force: true do |t|
                  t.references :test_post, null: false
                  t.text :body
                  t.boolean :disabled, default: false
                end
              end
            end
          end
          
          before do
            # Define models with explicit, restrictive ransackable configuration
            stub_const('TestUser', Class.new(ActiveRecord::Base) do
              self.table_name = 'test_users'
              has_many :test_posts, dependent: :destroy
              
              # Explicit ransackable configuration
              def self.ransackable_attributes(auth_object = nil)
                ['name', 'email']
              end
              
              def self.ransackable_associations(auth_object = nil)
                ['test_posts']
              end
            end)

            stub_const('TestPost', Class.new(ActiveRecord::Base) do
              self.table_name = 'test_posts'
              belongs_to :test_user
              has_many :test_comments, dependent: :destroy
              
              def self.ransackable_attributes(auth_object = nil)
                ['title', 'body']
              end
              
              def self.ransackable_associations(auth_object = nil)
                ['test_user', 'test_comments']
              end
            end)

            stub_const('TestComment', Class.new(ActiveRecord::Base) do
              self.table_name = 'test_comments'
              belongs_to :test_post
              default_scope { where(disabled: false) }
              
              def self.ransackable_attributes(auth_object = nil)
                ['body']
              end
              
              def self.ransackable_associations(auth_object = nil)
                ['test_post']
              end
            end)
            
            # Create test data
            @user1 = TestUser.create!(name: 'John Doe', email: 'john@example.com')
            @user2 = TestUser.create!(name: 'Jane Smith', email: 'jane@example.com')
            
            @post1 = TestPost.create!(test_user: @user1, title: 'Post by John', body: 'Content')
            @post2 = TestPost.create!(test_user: @user2, title: 'Post by Jane', body: 'Content')
            
            @comment1 = TestComment.create!(test_post: @post1, body: 'Johns comment')
            @comment2 = TestComment.create!(test_post: @post2, body: 'Janes comment')
          end

          it 'reproduces the bug: deep association search should fail' do
            # This should fail because:
            # - TestComment.ransackable_associations only includes 'test_post'
            # - TestPost.ransackable_associations includes 'test_user' 
            # - TestUser.ransackable_attributes includes 'email'
            # BUT the association traversal for 'test_post_test_user_email_cont' might not work
            
            expect {
              search = TestComment.ransack(test_post_test_user_email_cont: 'john@example.com')
              results = search.result.to_a
              puts "Search worked! Found #{results.count} results"
              results.each { |r| puts "  - #{r.inspect}" }
            }.to raise_error(Ransack::UntraversableAssociationError, /No association matches/)
          end
          
          it 'should work with proper intermediate association declarations' do
            # Let's modify TestPost to include test_user in ransackable_associations
            TestPost.define_singleton_method(:ransackable_associations) do |auth_object = nil|
              ['test_user', 'test_comments']
            end
            
            # Now it should work
            search = TestComment.ransack(test_post_test_user_email_cont: 'john@example.com')
            results = search.result
            
            expect(results.count).to eq(1)
            expect(results.first).to eq(@comment1)
          end
        end
        
        describe 'examining the context association_path logic' do
          it 'should demonstrate the association_path bug' do
            context = Comment.ransack.context
            
            puts "\n=== Testing association_path behavior ==="
            
            # Test what happens with our specific case
            path_result = context.association_path('article_person_email')
            puts "association_path('article_person_email') = '#{path_result}'"
            
            # The path should be 'article_person' but what if it's cutting off early?
            # Let's manually trace through the logic
            
            base = Comment
            segments = 'article_person_email'.split('_')
            puts "Segments: #{segments.inspect}"
            
            path = []
            association_parts = []
            current_base = base
            
            segments.each_with_index do |segment, i|
              association_parts << segment
              current_path = association_parts.join('_')
              
              # Check if current path is a column on the current base
              has_column = current_base.columns_hash[segments[i..-1].join('_')] != nil
              puts "  Step #{i+1}: checking '#{segments[i..-1].join('_')}' as column on #{current_base.name}: #{has_column}"
              
              # Check if current path is an association
              found_assoc = nil
              begin
                found_assoc = current_base.reflect_on_association(current_path.to_sym)
                puts "    Association '#{current_path}' on #{current_base.name}: #{found_assoc ? found_assoc.klass.name : 'nil'}"
              rescue => e
                puts "    Error checking association: #{e.class.name}: #{e.message}"
              end
              
              if found_assoc
                path += association_parts
                association_parts = []
                current_base = found_assoc.klass
                puts "    -> Advanced to #{current_base.name}, path so far: #{path.join('_')}"
              end
            end
            
            puts "Final path: #{path.join('_')}"
            
            # This test helps us understand the exact logic flow
          end
        end
      end
    end
  end
end