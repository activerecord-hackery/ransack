require 'bundler'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec) do |rspec|
  rspec.rspec_opts = ['--backtrace']
end

task :default => :spec

desc "Open an irb session with Ransack and the sample data used in specs"
task :console do
  require 'irb'
  require 'irb/completion'
  require 'console'
  ARGV.clear
  IRB.start
end