# test-in-or-blank-predicate.rb

# Run it in your console with: `ruby test-in-or-blank-predicate.rb`
# This demonstrates the new in_or_blank predicate functionality

unless File.exist?('Gemfile')
  File.write('Gemfile', <<-GEMFILE)
    source 'https://rubygems.org'

    # Rails master
    gem 'rails', github: 'rails/rails', branch: '7-1-stable'

    # Rails last release
    # gem 'rails'

    gem 'sqlite3'
    gem 'ransack', path: '.'
  GEMFILE

  system 'bundle install'
end

require 'bundler'
Bundler.setup(:default)

require 'active_record'
require 'minitest/autorun'
require 'logger'
require 'ransack'

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Display versions.
message = "Running test case with Ruby #{RUBY_VERSION}, Active Record #{
  ::ActiveRecord::VERSION::STRING}, Arel #{Arel::VERSION} and #{
  ::ActiveRecord::Base.connection.adapter_name}"
line = '=' * message.length
puts line, message, line

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.string :status
  end
end

class User < ActiveRecord::Base
  def self.ransackable_attributes(_auth_object = nil)
    ["name", "status"]
  end
end

class InOrBlankTest < Minitest::Test
  def setup
    User.delete_all
    @active_user = User.create!(name: 'John', status: 'active')
    @pending_user = User.create!(name: 'Jane', status: 'pending')
    @inactive_user = User.create!(name: 'Bob', status: 'inactive')
    @null_user = User.create!(name: 'Alice', status: nil)
    @empty_user = User.create!(name: 'Charlie', status: '')
    
    puts "\nTest data created:"
    User.all.each { |u| puts "  #{u.name}: #{u.status.inspect}" }
  end

  def test_in_or_blank_predicate
    puts "\n=== Testing in_or_blank predicate ==="
    
    # Test with multiple values
    search = User.ransack({ status_in_or_blank: ['active', 'pending'] })
    sql = search.result.to_sql
    results = search.result
    
    puts "\nQuery: status_in_or_blank with ['active', 'pending']"
    puts "SQL: #{sql}"
    puts "Results:"
    results.each { |u| puts "  #{u.name}: #{u.status.inspect}" }
    
    # Should include active, pending, null, and empty status users
    assert_equal 4, results.count
    assert_includes results, @active_user
    assert_includes results, @pending_user
    assert_includes results, @null_user
    assert_includes results, @empty_user
    assert_not_includes results, @inactive_user
    
    puts "✓ Test passed: Found #{results.count} users (active, pending, null, empty)"
  end

  def test_in_or_blank_single_value
    puts "\n=== Testing in_or_blank with single value ==="
    
    search = User.ransack({ status_in_or_blank: ['active'] })
    results = search.result
    
    puts "\nQuery: status_in_or_blank with ['active']"
    puts "SQL: #{search.result.to_sql}"
    puts "Results:"
    results.each { |u| puts "  #{u.name}: #{u.status.inspect}" }
    
    # Should include active, null, and empty status users
    assert_equal 3, results.count
    assert_includes results, @active_user
    assert_includes results, @null_user
    assert_includes results, @empty_user
    
    puts "✓ Test passed: Found #{results.count} users (active, null, empty)"
  end

  def test_in_or_blank_empty_array
    puts "\n=== Testing in_or_blank with empty array ==="
    
    search = User.ransack({ status_in_or_blank: [] })
    results = search.result
    
    puts "\nQuery: status_in_or_blank with []"
    puts "SQL: #{search.result.to_sql}"
    puts "Result count: #{results.count}"
    
    # Should return all users when no filtering condition is provided
    assert_equal 5, results.count
    
    puts "✓ Test passed: Empty array returns all users"
  end

  def test_comparison_with_regular_in
    puts "\n=== Comparing in_or_blank vs regular in ==="
    
    regular_in = User.ransack({ status_in: ['active', 'pending'] }).result
    in_or_blank = User.ransack({ status_in_or_blank: ['active', 'pending'] }).result
    
    puts "\nRegular 'in' results:"
    regular_in.each { |u| puts "  #{u.name}: #{u.status.inspect}" }
    puts "Count: #{regular_in.count}"
    
    puts "\n'in_or_blank' results:"
    in_or_blank.each { |u| puts "  #{u.name}: #{u.status.inspect}" }
    puts "Count: #{in_or_blank.count}"
    
    assert_equal 2, regular_in.count # Only active and pending
    assert_equal 4, in_or_blank.count # active, pending, null, and empty
    
    puts "✓ Test passed: in_or_blank includes blank values, regular in doesn't"
  end
end