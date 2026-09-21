source 'https://rubygems.org'
gemspec

gem 'rake'

rails = ENV['RAILS'] || '7-2-stable'

gem 'faker'
# >= 2.9.5 for CVE-2026-54619 (use-after-free when redefining a SQLite function
# with a different arity). The 1.x line ended at 1.7.3 and never received the
# fix, so the old Rails-version split can no longer be kept on a patched
# version. Rails 7.2 works with sqlite3 2.x, and the gemspec requires
# Active Record >= 7.2, so one constraint now covers every supported version.
gem 'sqlite3', '>= 2.9.5'
gem 'pg'
gem 'activerecord-postgis-adapter'
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

group :test do
  gem 'factory_bot'
  gem 'rspec'
  gem 'simplecov', require: false
end

gem 'rubocop', require: false
gem 'rubocop-rspec', require: false
