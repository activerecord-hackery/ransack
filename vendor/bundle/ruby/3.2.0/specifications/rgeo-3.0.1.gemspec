# -*- encoding: utf-8 -*-
# stub: rgeo 3.0.1 ruby lib
# stub: ext/geos_c_impl/extconf.rb

Gem::Specification.new do |s|
  s.name = "rgeo".freeze
  s.version = "3.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Azuma".freeze, "Tee Parham".freeze]
  s.date = "2023-11-15"
  s.description = "RGeo is a geospatial data library for Ruby. It provides an implementation of the Open Geospatial Consortium's Simple Features Specification, used by most standard spatial/geographic data storage systems such as PostGIS. A number of add-on modules are also available to help with writing location-based applications using Ruby-based frameworks such as Ruby On Rails.".freeze
  s.email = ["dazuma@gmail.com".freeze, "parhameter@gmail.com".freeze, "kfdoggett@gmail.com".freeze, "buonomo.ulysse@gmail.com".freeze]
  s.extensions = ["ext/geos_c_impl/extconf.rb".freeze]
  s.files = ["ext/geos_c_impl/extconf.rb".freeze]
  s.homepage = "https://github.com/rgeo/rgeo".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.7".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "RGeo is a geospatial data library for Ruby.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<ffi-geos>.freeze, ["~> 2.2"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.11"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.36.0"])
  s.add_development_dependency(%q<ruby_memcheck>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
end
