source 'https://rubygems.org'
gemspec

gem 'rake'

rails = ENV['RAILS'] || '6-0-stable'

gem 'pry'

# Provide timezone information on Windows
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw]

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
  # TestUnit was removed from Ruby 2.2 but still needed for testing Rails 3.x.
  gem 'test-unit', '~> 3.0' if RUBY_VERSION >= '2.2'
  gem 'simplecov', :require => false
end
