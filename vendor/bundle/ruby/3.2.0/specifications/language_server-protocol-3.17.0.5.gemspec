# -*- encoding: utf-8 -*-
# stub: language_server-protocol 3.17.0.5 ruby lib

Gem::Specification.new do |s|
  s.name = "language_server-protocol".freeze
  s.version = "3.17.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Fumiaki MATSUSHIMA".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.description = "A Language Server Protocol SDK".freeze
  s.email = ["mtsmfm@gmail.com".freeze]
  s.homepage = "https://github.com/mtsmfm/language_server-protocol-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A Language Server Protocol SDK".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 2.0.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
  s.add_development_dependency(%q<minitest-power_assert>.freeze, [">= 0"])
  s.add_development_dependency(%q<m>.freeze, [">= 0"])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 0"])
end
