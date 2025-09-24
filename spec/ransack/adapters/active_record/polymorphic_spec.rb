require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe 'Polymorphic filtering' do
        # This test reproduces the issue described in GitHub issue:
        # Polymorphic filtering is inconsistent
        # 
        # When filtering with `from_id_or_to_id_eq` on polymorphic associations,
        # Ransack throws: "Polymorphic associations do not support computing the class"
        # 
        # However, `id_or_from_id_or_to_id_eq` works fine, which indicates
        # the issue is specifically with OR conditions on polymorphic foreign keys
        context 'with polymorphic associations' do
          let!(:person1) { Person.create!(name: 'Alice', email: 'alice@example.com') }
          let!(:person2) { Person.create!(name: 'Bob', email: 'bob@example.com') }
          let!(:article1) { Article.create!(person: person1, title: 'Test Article', body: 'Test body') }
          
          let!(:message1) { Message.create!(user: person1, from: person1, to: person2, content: 'Hello from person to person') }
          let!(:message2) { Message.create!(user: person1, from: article1, to: person2, content: 'Hello from article to person') }
          let!(:message3) { Message.create!(user: person2, from: person2, to: person1, content: 'Reply from person to person') }
          
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
        end
      end
    end
  end
end