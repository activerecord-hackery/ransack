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

RSpec::Core::RakeTask.new(:mongoid) do |rspec|
  ENV['SPEC'] = 'spec/mongoid/**/*_spec.rb'
  rspec.rspec_opts = ['--backtrace']
end

task :default do
  if ENV['DB'] =~ /mongoid/
    Rake::Task["mongoid"].invoke
  else
    Rake::Task["spec"].invoke
  end
end

desc "Open an irb session with Ransack and the sample data used in specs"
task :console do
  require 'pry'
  require File.expand_path('../spec/console.rb', __FILE__)
  ARGV.clear
  Pry.start
end

desc "Open an irb session with Ransack, Mongoid and the sample data used in specs"
task :mongoid_console do
  require 'irb'
  require 'irb/completion'
  require 'pry'
  require 'mongoid'
  require File.expand_path('../lib/ransack.rb', __FILE__)
  require File.expand_path('../spec/mongoid/support/schema.rb', __FILE__)
  ARGV.clear
  Pry.start
end
