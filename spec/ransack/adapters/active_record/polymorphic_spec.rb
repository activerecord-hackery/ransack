require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe 'Polymorphic filtering' do
        # This test reproduces the issue described in GitHub issue:
        # "Polymorphic filtering is inconsistent"
        # 
        # PROBLEM:
        # When filtering with `from_id_or_to_id_eq` on polymorphic associations,
        # Ransack throws: "Polymorphic associations do not support computing the class"
        # 
        # However, `id_or_from_id_or_to_id_eq` works fine, which indicates
        # the issue is specifically with OR conditions on polymorphic foreign keys
        #
        # EXPECTED BEHAVIOR:
        # - `from_id_or_to_id_eq: '123'` should work and filter by foreign key values
        # - The query should not need to compute polymorphic classes since we're only
        #   filtering by the foreign key IDs, not joining to the polymorphic associations
        # - OR conditions between polymorphic foreign keys should work like regular FKs
        #
        # CURRENT (BROKEN) BEHAVIOR:
        # - `from_id_or_to_id_eq: '123'` raises ArgumentError about polymorphic classes
        # - The error occurs even though we're not accessing the polymorphic associations
        # - Only workaround is to include a non-polymorphic field in the OR condition
        #
        # ROOT CAUSE:
        # Ransack's attribute resolution logic incorrectly tries to compute the class
        # for polymorphic associations even when only filtering by foreign key values
        context 'with polymorphic associations' do
          let!(:person1) { Person.create!(name: 'Alice', email: 'alice@example.com') }
          let!(:person2) { Person.create!(name: 'Bob', email: 'bob@example.com') }
          let!(:article1) { Article.create!(person: person1, title: 'Test Article', body: 'Test body') }
          
          let!(:message1) { Message.create!(user: person1, from: person1, to: person2, content: 'Hello from person to person') }
          let!(:message2) { Message.create!(user: person1, from: article1, to: person2, content: 'Hello from article to person') }
          let!(:message3) { Message.create!(user: person2, from: person2, to: person1, content: 'Reply from person to person') }
          
          describe 'reproducing the exact issue from GitHub' do
            it 'should fail with from_id_or_to_id_eq using UUID-like string' do
              # This reproduces the exact error from the GitHub issue:
              # Message.ransack(from_id_or_to_id_eq: '3d4464a4-1501-4f30-a892-fa07f72f9fa1').result.count
              # should raise: "Polymorphic associations do not support computing the class"
              expect {
                search = Message.ransack(from_id_or_to_id_eq: '3d4464a4-1501-4f30-a892-fa07f72f9fa1')
                search.result.count
              }.to raise_error(ArgumentError, /Polymorphic associations do not support computing the class/)
            end
            
            it 'should work with id_or_from_id_or_to_id_eq using UUID-like string (the working case)' do
              # This reproduces the working case from the GitHub issue:
              # Message.ransack(id_or_from_id_or_to_id_eq: '3d4464a4-1501-4f30-a892-fa07f72f9fa1').result.count
              # should work and return a count
              expect {
                search = Message.ransack(id_or_from_id_or_to_id_eq: '3d4464a4-1501-4f30-a892-fa07f72f9fa1')
                count = search.result.count
                expect(count).to be >= 0  # Should return a valid count (likely 0 for non-matching UUID)
              }.not_to raise_error
            end
          end
          
          describe 'filtering by polymorphic foreign keys with OR condition' do
            it 'should work with from_id_or_to_id_eq' do
              # This should find messages where either from_id or to_id matches person1's id
              search = Message.ransack(from_id_or_to_id_eq: person1.id)
              result = search.result
              
              # Should find message1 (from: person1) and message3 (to: person1)
              expect(result).to include(message1, message3)
              expect(result).not_to include(message2)
            end
            
            it 'should work with to_id_or_from_id_eq' do
              # This should find messages where either to_id or from_id matches person2's id
              search = Message.ransack(to_id_or_from_id_eq: person2.id)
              result = search.result
              
              # Should find message1 (to: person2), message2 (to: person2), and message3 (from: person2)
              expect(result).to include(message1, message2, message3)
            end
            
            it 'should work with id_or_from_id_or_to_id_eq (the working case from issue)' do
              # This should work as described in the issue
              search = Message.ransack(id_or_from_id_or_to_id_eq: person1.id)
              result = search.result
              
              # Should find message1 (from: person1) and message3 (to: person1)
              # but NOT message1 itself by id since person1.id != message1.id
              expect(result).to include(message1, message3)
              expect(result).not_to include(message2)
            end
          end
          
          describe 'filtering by single polymorphic foreign key' do
            it 'should work with from_id_eq' do
              search = Message.ransack(from_id_eq: person1.id)
              result = search.result
              
              expect(result).to include(message1)
              expect(result).not_to include(message2, message3)
            end
            
            it 'should work with to_id_eq' do
              search = Message.ransack(to_id_eq: person2.id)
              result = search.result
              
              expect(result).to include(message1, message2)
              expect(result).not_to include(message3)
            end
          end
          
          describe 'additional edge cases for polymorphic OR conditions' do
            it 'should fail with user_id_or_from_id_eq' do
              # This combines a regular foreign key with a polymorphic foreign key
              expect {
                search = Message.ransack(user_id_or_from_id_eq: person1.id)
                search.result.count
              }.to raise_error(ArgumentError, /Polymorphic associations do not support computing the class/)
            end
            
            it 'should fail with from_id_or_to_id_or_user_id_eq' do
              # This combines multiple polymorphic and regular foreign keys
              expect {
                search = Message.ransack(from_id_or_to_id_or_user_id_eq: person1.id)
                search.result.count
              }.to raise_error(ArgumentError, /Polymorphic associations do not support computing the class/)
            end
            
            it 'should work with user_id_or_id_eq (no polymorphic keys)' do
              # This should work as it doesn't involve polymorphic associations
              search = Message.ransack(user_id_or_id_eq: person1.id)
              result = search.result
              
              # Should find messages where user_id matches person1.id
              expect(result).to include(message1, message2)
              expect(result).not_to include(message3)
            end
          end
        end
      end
    end
  end
end