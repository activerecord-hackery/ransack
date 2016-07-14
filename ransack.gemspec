# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ransack/version"

Gem::Specification.new do |s|
  s.name        = "ransack"
  s.version     = Ransack::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ernie Miller", "Ryan Bigg", "Jon Atack"]
  s.email       = ["ernie@erniemiller.org", "radarlistener@gmail.com", "jonnyatack@gmail.com"]
  s.homepage    = "https://github.com/activerecord-hackery/ransack"
  s.summary     = %q{Object-based searching for Active Record and Mongoid (currently).}
  s.description = %q{Ransack is the successor to the MetaSearch gem. It improves and expands upon MetaSearch's functionality, but does not have a 100%-compatible API.}
  s.required_ruby_version = '>= 1.9'
  s.license     = 'MIT'

  s.rubyforge_project = "ransack"

  s.add_dependency 'actionpack', '>= 3.0'
  s.add_dependency 'activerecord', '>= 3.0'
  s.add_dependency 'activesupport', '>= 3.0'
  s.add_dependency 'i18n'
  s.add_dependency 'polyamorous', '~> 1.3'
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'machinist', '~> 1.0.6'
  s.add_development_dependency 'faker', '~> 0.9.5'
  s.add_development_dependency 'sqlite3', '~> 1.3.3'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'mysql2', '0.3.20'
  s.add_development_dependency 'pry', '0.10'

  s.files         = `git ls-files`.split("\n")

  s.test_files    = `git ls-files -- {test,spec,features}/*`
                    .split("\n")

  s.executables   = `git ls-files -- bin/*`
                    .split("\n")
                    .map { |f| File.basename(f) }

  s.require_paths = ["lib"]
end
