# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "polyamorous/version"

Gem::Specification.new do |s|
  s.name        = "polyamorous"
  s.version     = Polyamorous::VERSION
  s.authors     = ["Ernie Miller", "Ryan Bigg", "Jon Atack", "Xiang Li"]
  s.email       = ["ernie@erniemiller.org", "radarlistener@gmail.com", "jonnyatack@gmail.com", "bigxiang@gmail.com"]
  s.homepage    = "https://github.com/activerecord-hackery/ransack/tree/master/polyamorous"
  s.license     = "MIT"
  s.summary     = %q{
    Loves/is loved by polymorphic belongs_to associations, Ransack, Squeel, MetaSearch...
  }
  s.description = %q{
    This is just an extraction from Ransack/Squeel. You probably don't want to use this
    directly. It extends ActiveRecord's associations to support polymorphic belongs_to
    associations.
  }

  s.add_dependency 'activerecord', '>= 5.2.1'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
