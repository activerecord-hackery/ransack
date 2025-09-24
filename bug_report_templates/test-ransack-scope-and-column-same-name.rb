# test-ransack-scope-and-column-same-name.rb

# This is a stand-alone test case.

# Run it in your console with: `ruby test-ransack-scope-and-column-same-name.rb`

# If you change the gem dependencies, run it with:
# `rm gemfile* && ruby test-ransack-scope-and-column-same-name.rb`

unless File.exist?('Gemfile')
  File.write('Gemfile', <<-GEMFILE)
    source 'https://rubygems.org'

    # Rails master
    gem 'rails', github: 'rails/rails', branch: '7-1-stable'

    # Rails last release
    # gem 'rails'

    gem 'sqlite3'
    gem 'rspec'
    gem 'ransack', github: 'activerecord-hackery/ransack'
  GEMFILE

  # Install gems locally to avoid permission issues
  system 'bundle config set --local path .bundle'
  system 'bundle install'
end

require 'bundler'
Bundler.setup(:default)

require 'active_record'
require 'logger'
require 'ransack'

begin
  require 'rspec'
rescue LoadError
  # RSpec not available, trying to load with bundler
  puts "RSpec not found, please run with bundle exec or install rspec gem"
  exit 1
end

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
    t.boolean :active, null: false, default: true
  end
end

class User < ActiveRecord::Base
  scope :activated, -> (boolean = true) { where(active: boolean) }

  private

  def self.ransackable_scopes(auth_object = nil)
    %i(activated)
  end
end

RSpec.describe 'Ransack Scope and Column Same Name Bug Report' do
  it 'handles activated scope equals true' do
    sql = User.ransack({ activated: true }).result.to_sql
    puts sql
    expect(sql).to eq(
      "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"active\" = 1"
      )
  end

  it 'handles activated scope equals false' do
    sql = User.ransack({ activated: false }).result.to_sql
    puts sql
    expect(sql).to eq(
      "SELECT \"users\".* FROM \"users\""
      )
  end
end

# Run the specs when executed directly
if __FILE__ == $0
  RSpec::Core::Runner.run([__FILE__])
end
