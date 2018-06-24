source 'https://rubygems.org'
gemspec

gem 'rake'

rails = ENV['RAILS'] || '5-0-stable'

gem 'pry'

# Provide timezone information on Windows
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw]

case rails
when /\// # A path
  gem 'activesupport', path: "#{rails}/activesupport"
  gem 'activerecord', path: "#{rails}/activerecord", require: false
  gem 'actionpack', path: "#{rails}/actionpack"
when /^v/ # A tagged version
  git 'git://github.com/rails/rails.git', :tag => rails do
    gem 'activesupport'
    gem 'activemodel'
    gem 'activerecord', require: false
    gem 'actionpack'
  end
  if rails == 'v5.2.0'
    gem 'mysql2', '~> 0.4.4'
  end
else
  git 'git://github.com/rails/rails.git', :branch => rails do
    gem 'activesupport'
    gem 'activemodel'
    gem 'activerecord', require: false
    gem 'actionpack'
  end
  if rails == '3-0-stable'
    gem 'mysql2', '< 0.3'
  end
  if rails == '5-2-stable'
    gem 'mysql2', '~> 0.4.4'
  end
end

if ENV['DB'] =~ /mongoid4/
  gem 'mongoid', '~> 4.0.0', require: false
end

if ENV['DB'] =~ /mongoid5/
  gem 'mongoid', '~> 5.0.0', require: false
end

group :test do
  # TestUnit was removed from Ruby 2.2 but still needed for testing Rails 3.x.
  gem 'test-unit', '~> 3.0' if RUBY_VERSION >= '2.2'
  gem 'simplecov', :require => false
end
