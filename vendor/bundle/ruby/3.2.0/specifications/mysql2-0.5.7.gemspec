# -*- encoding: utf-8 -*-
# stub: mysql2 0.5.7 ruby lib
# stub: ext/mysql2/extconf.rb

Gem::Specification.new do |s|
  s.name = "mysql2".freeze
  s.version = "0.5.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/brianmario/mysql2/issues", "changelog_uri" => "https://github.com/brianmario/mysql2/releases/tag/0.5.7", "documentation_uri" => "https://www.rubydoc.info/gems/mysql2/0.5.7", "homepage_uri" => "https://github.com/brianmario/mysql2", "msys2_mingw_dependencies" => "libmariadbclient", "source_code_uri" => "https://github.com/brianmario/mysql2/tree/0.5.7" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brian Lopez".freeze, "Aaron Stone".freeze]
  s.date = "1980-01-02"
  s.email = ["seniorlopez@gmail.com".freeze, "aaron@serendipity.cx".freeze]
  s.extensions = ["ext/mysql2/extconf.rb".freeze]
  s.files = ["ext/mysql2/extconf.rb".freeze]
  s.homepage = "https://github.com/brianmario/mysql2".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A simple, fast Mysql library for Ruby, binding to libmysql".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<bigdecimal>.freeze, [">= 0"])
end
