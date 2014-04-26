source 'https://rubygems.org'
gemspec

gem 'rake'

rails = ENV['RAILS'] || '4-1-stable'

gem 'polyamorous', '~> 1.0.0'

case rails
when /\// # A path
  gem 'activesupport', path: "#{rails}/activesupport"
  gem 'activemodel', path: "#{rails}/activemodel"
  gem 'activerecord', path: "#{rails}/activerecord"
  gem 'actionpack', path: "#{rails}/activerecord"
when /^v/ # A tagged version
  git 'git://github.com/rails/rails.git', tag: rails do
    gem 'activesupport'
    gem 'activemodel'
    gem 'activerecord'
    gem 'actionpack'
  end
else
  git 'git://github.com/rails/rails.git', branch: rails do
    gem 'activesupport'
    gem 'activemodel'
    gem 'activerecord'
    gem 'actionpack'
  end
  if rails == '3-0-stable'
    gem 'mysql2', '< 0.3'
  end
end
