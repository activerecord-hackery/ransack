source 'https://rubygems.org'
gemspec

gem 'rake'

rails = ENV['RAILS'] || '7-2-stable'

gem 'faker'
# CVE-2026-54619 (use-after-free when redefining a SQLite function with a
# different arity) is fixed in sqlite3 2.9.5. The 1.x line ended at 1.7.3 and
# never received the fix, so the old Rails-version split could not be kept on a
# patched version; Rails 7.2 runs fine against sqlite3 2.x, so it is gone.
gem 'sqlite3', '>= 2.9.5'
gem 'pg'
gem 'pry'
gem 'byebug'

case rails
when /\// # A path
  gem 'activesupport', path: "#{rails}/activesupport"
  gem 'activemodel', path: "#{rails}/activemodel"
  gem 'activerecord', path: "#{rails}/activerecord", require: false
  gem 'actionpack', path: "#{rails}/actionpack"
  gem 'actionview', path: "#{rails}/actionview"
when /^v/ # A tagged version
  git 'https://github.com/rails/rails.git', tag: rails do
    gem 'activesupport'
    gem 'activemodel'
    gem 'activerecord', require: false
    gem 'actionpack'
  end
else
  git 'https://github.com/rails/rails.git', branch: rails do
    gem 'activesupport'
    gem 'activemodel'
    gem 'activerecord', require: false
    gem 'actionpack'
  end
end
gem 'mysql2'
gem 'trilogy'

group :test do
  gem 'factory_bot'
  gem 'rspec'
  gem 'simplecov', require: false
end

gem 'rubocop', require: false
gem 'rubocop-rspec', require: false
