#!/usr/bin/env ruby

# Simple test runner to demonstrate the polymorphic filtering issue
# Run with: ruby test_polymorphic_issue.rb

require 'minitest/autorun'
require_relative 'lib/ransack'
require_relative 'spec/support/schema'

# Initialize the database and schema
Schema.create

class TestPolymorphicFiltering < Minitest::Test
  def setup
    # Create test data
    @person1 = Person.create!(name: 'Alice', email: 'alice@example.com')
    @person2 = Person.create!(name: 'Bob', email: 'bob@example.com')
    @article1 = Article.create!(person: @person1, title: 'Test Article', body: 'Test body')
    
    @message1 = Message.create!(user: @person1, from: @person1, to: @person2, content: 'Hello from person to person')
    @message2 = Message.create!(user: @person1, from: @article1, to: @person2, content: 'Hello from article to person')
    @message3 = Message.create!(user: @person2, from: @person2, to: @person1, content: 'Reply from person to person')
  end
  
  def test_failing_case_from_id_or_to_id_eq
    puts "Testing failing case: from_id_or_to_id_eq"
    
    # This should fail with "Polymorphic associations do not support computing the class"
    assert_raises(ArgumentError, /Polymorphic associations do not support computing the class/) do
      search = Message.ransack(from_id_or_to_id_eq: @person1.id)
      search.result.count
    end
    
    puts "✓ Correctly failed with expected error"
  end
  
  def test_working_case_id_or_from_id_or_to_id_eq
    puts "Testing working case: id_or_from_id_or_to_id_eq"
    
    # This should work as mentioned in the issue
    search = Message.ransack(id_or_from_id_or_to_id_eq: @person1.id)
    count = search.result.count
    
    assert count.is_a?(Integer)
    puts "✓ Correctly worked, returned count: #{count}"
  end
  
  def test_single_polymorphic_key_works
    puts "Testing single polymorphic key: from_id_eq"
    
    # This should work fine
    search = Message.ransack(from_id_eq: @person1.id)
    result = search.result.to_a
    
    assert_includes result, @message1
    refute_includes result, @message2
    refute_includes result, @message3
    puts "✓ Single polymorphic key filtering works correctly"
  end
end

puts "=" * 60
puts "POLYMORPHIC FILTERING ISSUE REPRODUCTION TEST"
puts "=" * 60
puts
puts "This demonstrates the inconsistent behavior described in the GitHub issue:"
puts "- Single polymorphic foreign key filtering works (from_id_eq)"
puts "- OR with non-polymorphic field works (id_or_from_id_or_to_id_eq)"  
puts "- OR between polymorphic foreign keys fails (from_id_or_to_id_eq)"
puts
puts "Expected: All should work since we're only filtering by foreign key values"
puts "Actual: OR between polymorphic FKs throws polymorphic class computation error"
puts