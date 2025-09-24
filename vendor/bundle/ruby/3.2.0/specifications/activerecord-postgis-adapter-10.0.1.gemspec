# -*- encoding: utf-8 -*-
# stub: activerecord-postgis-adapter 10.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "activerecord-postgis-adapter".freeze
  s.version = "10.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "funding_uri" => "https://opencollective.com/rgeo", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Azuma".freeze, "Tee Parham".freeze]
  s.date = "2024-11-15"
  s.description = "ActiveRecord connection adapter for PostGIS. It is based on the stock PostgreSQL adapter, and adds built-in support for the spatial extensions provided by PostGIS. It uses the RGeo library to represent spatial data in Ruby.".freeze
  s.email = ["kfdoggett@gmail.com".freeze, "buonomo.ulysse@gmail.com".freeze, "terminale@gmail.com".freeze]
  s.homepage = "http://github.com/rgeo/activerecord-postgis-adapter".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "ActiveRecord adapter for PostGIS, based on RGeo.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, ["~> 7.2.0"])
  s.add_runtime_dependency(%q<rgeo-activerecord>.freeze, ["~> 8.0.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.4"])
  s.add_development_dependency(%q<minitest-excludes>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<benchmark-ips>.freeze, ["~> 2.12"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.50"])
end
