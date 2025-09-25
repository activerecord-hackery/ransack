# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "ransack/version"

Gem::Specification.new do |s|
  s.name        = "ransack"
  s.version     = Ransack::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ernie Miller", "Ryan Bigg", "Jon Atack", "Sean Carroll", "David Rodríguez"]
  s.email       = ["ernie@erniemiller.org", "radarlistener@gmail.com", "jonnyatack@gmail.com", "magma.craters2h@icloud.com"]
  s.homepage    = "https://github.com/activerecord-hackery/ransack"
  s.summary     = %q{Object-based searching for Active Record.}
  s.description = %q{Powerful object-based searching and filtering for Active Record with advanced features like complex boolean queries, association searching, custom predicates and i18n support.}
  s.required_ruby_version = '>= 3.1'
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
