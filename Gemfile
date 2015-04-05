source 'https://rubygems.org'
gemspec

gem 'rake'

rails = ENV['RAILS'] || '4-2-stable'

if rails == 'master'
  gem 'arel', github: 'rails/arel'
  gem 'polyamorous', github: 'activerecord-hackery/polyamorous'
else
  gem 'polyamorous', '~> 1.2'
end

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
end

if ENV['DB'] =~ /mongodb/
  gem 'mongoid', '~> 4.0.0', require: false
end

# Removed from Ruby 2.2 but needed for testing Rails 3.x.
group :test do
  gem 'test-unit', '~> 3.0' if RUBY_VERSION >= '2.2'
end
