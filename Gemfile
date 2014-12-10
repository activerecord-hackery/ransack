source 'https://rubygems.org'
gemspec

gem 'rake'

rails = ENV['RAILS'] || 'master'

if %w(5.0 4.2).include?(rails[0,3]) || rails == 'master'
  gem 'arel', github: 'rails/arel'
end

gem 'polyamorous', '~> 1.1'

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
