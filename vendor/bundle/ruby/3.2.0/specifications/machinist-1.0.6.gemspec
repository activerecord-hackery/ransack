# -*- encoding: utf-8 -*-
# stub: machinist 1.0.6 ruby lib

Gem::Specification.new do |s|
  s.name = "machinist".freeze
  s.version = "1.0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pete Yandell".freeze]
  s.date = "2009-11-29"
  s.email = "pete@notahat.com".freeze
  s.extra_rdoc_files = ["README.markdown".freeze]
  s.files = ["README.markdown".freeze]
  s.homepage = "http://github.com/notahat/machinist".freeze
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Fixtures aren't fun. Machinist is.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 3

  s.add_development_dependency(%q<rspec>.freeze, [">= 1.2.8"])
end
