source "https://rubygems.org"
gemspec

gem 'rake'

rails = ENV['RAILS'] || '4-0-stable'

# '3-2-stable' needs arel '~> 3.0.3'
# '3-1-stable' needs arel '~> 2.2.3'
# '3-0-stable' needs arel '~> 2.0.10' and i18n '~> 0.5.0'

gem 'arel'

case rails
when /\// # A path
  gem 'activesupport', :path => "#{rails}/activesupport"
  gem 'activemodel', :path => "#{rails}/activemodel"
  gem 'activerecord', :path => "#{rails}/activerecord"
  gem 'actionpack', :path => "#{rails}/activerecord"
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
