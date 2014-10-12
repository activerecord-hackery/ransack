source 'https://rubygems.org'
gemspec

gem 'rake'

rails = ENV['RAILS'] || 'master'

if rails[0,3] == '4.2' || rails == 'master'
  gem 'arel', github: 'rails/arel', branch: 'master'
end

gem 'polyamorous', '~> 1.1'

# Provide timezone information on Windows
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw]

case rails
when /\// # A path
  gem 'activesupport', path: "#{rails}/activesupport"
  gem 'activerecord', path: "#{rails}/activerecord"
  gem 'actionpack', path: "#{rails}/actionpack"
when /^v/ # A tagged version
  git 'git://github.com/rails/rails.git', :tag => rails do
    gem 'activesupport'
    gem 'activemodel'
    gem 'activerecord'
    gem 'actionpack'
  end
else
  git 'git://github.com/rails/rails.git', :branch => rails do
    gem 'activesupport'
    gem 'activemodel'
    gem 'activerecord'
    gem 'actionpack'
  end
  if rails == '3-0-stable'
    gem 'mysql2', '< 0.3'
  end
end
