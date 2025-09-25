require 'bundler'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec) do |rspec|
  ENV['SPEC'] = 'spec/ransack/**/*_spec.rb'
  # With Rails 3, using `--backtrace` raises 'invalid option' when testing.
  # With Rails 4 and 5 it can be uncommented to see the backtrace:
  #
  # rspec.rspec_opts = ['--backtrace']
end

# RuboCop tasks
begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  # RuboCop not available
end

# Combined test task that runs both specs and RuboCop
desc "Run all tests (specs + RuboCop)"
task :test do
  puts "Running RuboCop..."
  Rake::Task["rubocop"].invoke
  
  puts "\nRunning RSpec tests..."
  Rake::Task["spec"].invoke
end

# Test with PostgreSQL
desc "Run all tests with PostgreSQL"
task :test_pg do
  puts "Running RuboCop..."
  Rake::Task["rubocop"].invoke
  
  puts "\nRunning RSpec tests with PostgreSQL..."
  ENV['DB'] = 'pg'
  Rake::Task["spec"].invoke
end

# Test with MySQL
desc "Run all tests with MySQL"
task :test_mysql do
  puts "Running RuboCop..."
  Rake::Task["rubocop"].invoke
  
  puts "\nRunning RSpec tests with MySQL..."
  ENV['DB'] = 'mysql'
  Rake::Task["spec"].invoke
end

# Helper method to check database availability
def database_available?(adapter)
  case adapter
  when 'pg', 'postgres', 'postgresql'
    begin
      require 'pg'
      PG.connect(host: 'localhost', dbname: 'postgres', user: 'postgres', password: '')
      true
    rescue PG::Error, LoadError
      false
    end
  when 'mysql', 'mysql2'
    begin
      require 'mysql2'
      Mysql2::Client.new(host: 'localhost', username: 'root', password: '')
      true
    rescue Mysql2::Error, LoadError
      false
    end
  else
    true # SQLite is always available
  end
rescue
  false
end

# Test with all available databases
desc "Run all tests with available databases (SQLite, PostgreSQL, MySQL)"
task :test_all do
  puts "Running RuboCop..."
  Rake::Task["rubocop"].invoke
  
  puts "\nRunning RSpec tests with SQLite..."
  ENV.delete('DB')
  Rake::Task["spec"].invoke
  
  if database_available?('pg')
    puts "\nPostgreSQL detected. Running RSpec tests with PostgreSQL..."
    ENV['DB'] = 'pg'
    Rake::Task["spec"].invoke
  else
    puts "\nPostgreSQL not available. Skipping PostgreSQL tests."
  end
  
  if database_available?('mysql')
    puts "\nMySQL detected. Running RSpec tests with MySQL..."
    ENV['DB'] = 'mysql'
    Rake::Task["spec"].invoke
  else
    puts "\nMySQL not available. Skipping MySQL tests."
  end
end

# Test with detected databases only
desc "Run tests with all detected databases"
task :test_detected do
  puts "Detecting available databases..."
  
  available_dbs = []
  available_dbs << 'sqlite' if true # SQLite is always available
  available_dbs << 'postgresql' if database_available?('pg')
  available_dbs << 'mysql' if database_available?('mysql')
  
  puts "Available databases: #{available_dbs.join(', ')}"
  
  puts "\nRunning RuboCop..."
  Rake::Task["rubocop"].invoke
  
  available_dbs.each do |db|
    puts "\nRunning RSpec tests with #{db.capitalize}..."
    ENV['DB'] = db
    Rake::Task["spec"].invoke
  end
end

task :default do
  Rake::Task["test"].invoke
end

desc "Open an irb session with Ransack and the sample data used in specs"
task :console do
  require 'pry'
  require File.expand_path('../spec/console.rb', __FILE__)
  ARGV.clear
  Pry.start
end
