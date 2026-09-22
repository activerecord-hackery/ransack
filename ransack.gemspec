# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "ransack/version"

Gem::Specification.new do |s|
  s.name        = "ransack"
  s.version     = Ransack::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ernie Miller", "Ryan Bigg", "Jon Atack", "Sean Carroll", "David Rodríguez"]
  s.email       = ["ernie@erniemiller.org", "radarlistener@gmail.com", "jonnyatack@gmail.com", "sean@immersive-app.com", "magma.craters2h@icloud.com"]
  s.homepage    = "https://github.com/activerecord-hackery/ransack"
  s.summary     = %q{Object-based searching for Active Record.}
  s.description = %q{Powerful object-based searching and filtering for Active Record with advanced features like complex boolean queries, association searching, custom predicates and i18n support.}
  # Ruby 3.1 reached end of life in March 2025 and its ecosystem has moved on
  # (no sqlite3 with the CVE-2026-54619 fix supports it). Raising this floor
  # is a breaking change and belongs in a major release only.
  s.required_ruby_version = '>= 3.2'
  s.license     = 'MIT'
  
  s.metadata = {
    'changelog_uri' => "#{s.homepage}/releases/tag/v#{s.version}"
  }

  s.metadata['changelog_uri'] = 'https://github.com/activerecord-hackery/ransack/blob/main/CHANGELOG.md'

  s.add_dependency 'activerecord', '>= 7.2'
  s.add_dependency 'activesupport', '>= 7.2'
  s.add_dependency 'i18n'

  s.files         = Dir["README.md", "LICENSE", "lib/**/*"]
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
