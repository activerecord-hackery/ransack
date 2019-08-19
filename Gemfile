source 'https://rubygems.org'
gemspec

gem 'rake'

rails = ENV['RAILS'] || '6-0-stable'

gem 'faker', '~> 0.9.5'
gem 'sqlite3', ::Gem::Version.new(rails.gsub(/^v/, '')) >= ::Gem::Version.new('6-0-stable') ? '~> 1.4.1' : '~> 1.3.3'
gem 'pg', '~> 1.0'
gem 'pry', '0.10'
gem 'byebug'

case rails
when /\// # A path
  gem 'activesupport', path: "#{rails}/activesupport"
  gem 'activerecord', path: "#{rails}/activerecord", require: false
  gem 'actionpack', path: "#{rails}/actionpack"
when /^v/ # A tagged version
  git 'https://github.com/rails/rails.git', :tag => rails do
    gem 'activesupport'
    gem 'activemodel'
    gem 'activerecord', require: false
    gem 'actionpack'
  end
else
  git 'https://github.com/rails/rails.git', :branch => rails do
    gem 'activesupport'
    gem 'activemodel'
    gem 'activerecord', require: false
    gem 'actionpack'
  end
end
gem 'mysql2', '~> 0.5.2'

group :test do
  gem 'machinist', '~> 1.0.6'
  gem 'rspec', '~> 3'
  # TestUnit was removed from Ruby 2.2 but still needed for testing Rails 3.x.
  gem 'test-unit', '~> 3.0' if RUBY_VERSION >= '2.2'
  gem 'simplecov', :require => false
end
