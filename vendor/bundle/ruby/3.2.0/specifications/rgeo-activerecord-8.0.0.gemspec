# -*- encoding: utf-8 -*-
# stub: rgeo-activerecord 8.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rgeo-activerecord".freeze
  s.version = "8.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Azuma".freeze, "Tee Parham".freeze]
  s.date = "2024-09-11"
  s.description = "RGeo is a geospatial data library for Ruby. RGeo::ActiveRecord is an optional RGeo module providing some spatial extensions to ActiveRecord, as well as common tools used by RGeo-based spatial adapters.".freeze
  s.email = ["dazuma@gmail.com".freeze, "parhameter@gmail.com".freeze, "kfdoggett@gmail.com".freeze]
  s.homepage = "https://github.com/rgeo/rgeo-activerecord".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "An RGeo module providing spatial extensions to ActiveRecord.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 7.0"])
  s.add_runtime_dependency(%q<rgeo>.freeze, [">= 3.0"])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.1"])
  s.add_development_dependency(%q<ffi-geos>.freeze, ["~> 1.2"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.8"])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 1.1"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.0"])
  s.add_development_dependency(%q<rgeo-geojson>.freeze, [">= 1.0.0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0.20.0"])
end
