# -*- encoding: utf-8 -*-
# stub: rake 13.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rake".freeze
  s.version = "13.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby/rake/issues", "changelog_uri" => "https://github.com/ruby/rake/releases", "documentation_uri" => "https://ruby.github.io/rake", "source_code_uri" => "https://github.com/ruby/rake/releases/v13.3.0" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Hiroshi SHIBATA".freeze, "Eric Hodel".freeze, "Jim Weirich".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.description = "Rake is a Make-like program implemented in Ruby. Tasks and dependencies are\nspecified in standard Ruby syntax.\nRake has the following features:\n  * Rakefiles (rake's version of Makefiles) are completely defined in standard Ruby syntax.\n    No XML files to edit. No quirky Makefile syntax to worry about (is that a tab or a space?)\n  * Users can specify tasks with prerequisites.\n  * Rake supports rule patterns to synthesize implicit tasks.\n  * Flexible FileLists that act like arrays but know about manipulating file names and paths.\n  * Supports parallel execution of tasks.\n".freeze
  s.email = ["hsbt@ruby-lang.org".freeze, "drbrain@segment7.net".freeze, "".freeze]
  s.executables = ["rake".freeze]
  s.files = ["exe/rake".freeze]
  s.homepage = "https://github.com/ruby/rake".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Rake is a Make-like program implemented in Ruby".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version
end
