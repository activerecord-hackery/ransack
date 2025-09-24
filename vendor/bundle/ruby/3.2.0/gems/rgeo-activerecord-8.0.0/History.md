### 8.0.0 / 2024-09-11

* Drop support for legacy dependencies (tagliala)
* Support ActiveRecord 7.2 (tagliala)

### 7.0.1 / 2021-02-23

* Fix malformed Arel queries using `as` (ugisozols)

### 7.0.0 / 2020-12-15

* Update visit_* methods and Arel interface to support RGeo features.
* Rework SpatialFactoryStore to support hierarchical matches and fallbacks.

### 6.2.2 / 2020-11-20

* Removed `Arel::Visitor::DepthFirst` for ActiveRecord 6.1 compatibility (kamipo)

### 6.2.1 / 2019-07-01

* Include GeometryMixin in Cartesian modules (#52, andreasknoepfle)


### 6.2.0 / 2019-05-09

* Allow ActiveRecord 6.0 (#50, corneverbruggen)


### 6.1.0 / 2018-12-01

* Allow rgeo 2.0


### 6.0.0 / 2017-12-02

* Require rgeo 1.0


### 5.1.1 / 2017-10-02

* Fix #st_area #43

### 5.1.0 / 2017-02-27

* Allow ActiveRecord 5.x

### 5.0.1 / 2016-12-31

* Remove autoload hack
* Fix ruby warning - uninitialized variable

### 5.0.0 / 2016-07-01

* Require ActiveRecord 5.0

### 4.0.5 / 2015-12-29

* Fix #geometric_type_from_name for :geometrycollection

### 4.0.4 / 2015-12-29

* Restore rgeo/active_record.rb

### 4.0.3 / 2015-12-28

* Fix json parser for rgeo-geojson 0.4.0+

### 4.0.2 / 2015-12-28

* Remove unnecessary root namespacing
* Remove unnecessary namespace qualifiers
* Remove rgeo/active_record.rb

### 4.0.1 / 2015-12-25

* Rubocop style cleanup #31
* Do not distribute test files with gem

### 4.0.0 / 2015-05-24

* Remove GeoTableDefinitions, GeoConnectionAdapter

### 3.0.0 / 2015-05-09

* Remove AdapterTestHelper module
* Remove RGeoFactorySettings
* Remove #set_rgeo_factory_for_column, #rgeo_factory_for_column, etc
* Add SpatialFactoryStore (see https://github.com/rgeo/rgeo-activerecord/commit/b1da5cb222)

### 2.1.1 / 2015-03-18

* Fix collector calls for arel 6.0 API

### 2.1.0 / 2015-02-07

* Update visit API for arel 6.0
* Remove attribute caching (removed in AR 4.2)
* Remove support for `spatial: true` index option (use standard `using: :gist`)

### 2.0.0 / 2014-12-02

* Dump schema using new style hash - https://github.com/rgeo/rgeo-activerecord/pull/18
* Require ActiveRecord 4.2

### 1.2.0 / 2014-08-21

* Support ActiveRecord 4.2

### 1.1.0 / 2014-06-17

* Relax rgeo gem dependency

### 1.0.0 / 2014-05-06

* Require ruby 1.9.3+
* Require ActiveRecord 4+
* General refactoring and cleanup

### 0.6.0 / 2014-05-06

* Support Rails 4, Arel 4

### 0.5.0 / 2013-02-27

*   No changes. Rereleased as 0.5.0 final.


### 0.5.0.beta2 / 2013-02-04

*   Revert change made to SpatialIndexDefinition in beta1.
*   Fix some deprecations in the post-test cache cleanup.


### 0.5.0.beta1 / 2013-02-04

*   Updates for compatibility with Rails 4 and support of Rails 4 oriented
    adapters.
*   Testing tool is better factored to allow customization of cleanup


### 0.4.6 / 2012-12-11

*   You can now provide both a default and an override database config file in
    the test helper.
*   The gemspec no longer includes the timestamp in the version, so that
    bundler can pull from github. (Reported by corneverbruggen)


### 0.4.5 / 2012-04-13

*   Task hacker failed ungracefully when attempting to hack a nonexistent
    task. Fixed.


### 0.4.4 / 2012-04-12

*   Support cartesian bounding boxes in queries.


### 0.4.3 / 2012-02-22

*   Some fixes for Rails 3.2 compatibility.


### 0.4.2 / 2012-01-09

*   Added an "rgeo-activerecord.rb" wrapper so bundler's auto-require will
    work without modification. (Reported by Mauricio Pasquier Juan.)
*   Fixed unit tests so they actually pass...


### 0.4.1 / 2011-10-26

*   Fixed wrong variable name crash in rgeo_factory_for_column (patch by Andy
    Allan).


### 0.4.0 / 2011-08-15

*   Several compatibility fixes for Rails 3.1.
*   Revamped factory setter mechanism with a system that should be more
    robust.
*   Some general code cleanup.


### 0.3.4 / 2011-05-23

*   Uses the mixin feature of RGeo 0.3 to add an as_json method to all
    geometry objects. This should allow ActiveRecord's JSON serialization to
    function for models with geometry fields. (Reported by thenetduck and
    tonyc on github.)


### 0.3.3 / 2011-04-11

*   A .gemspec file is now available for gem building and bundler git
    integration.


### 0.3.2 / 2011-02-28

*   Fixed a bug that sometimes caused spatial column detection to fail, which
    could result in exceptions or incorrect spatial queries.


### 0.3.1 / 2011-02-28

*   Fixed a bug that could cause some spatial ActiveRecord adapters to fail to
    create multiple spatial columns in a migration.


### 0.3.0 / 2011-01-26

*   Experimental support for complex spatial queries. (Requires Arel 2.1,
    which is expected to be released with Rails 3.1.) Currently, only a
    low-level Arel-based interface is supported.
*   Better support for geography types in PostGIS.
*   Adapters can now define additional column constructors.
*   Support for spatial column constructors on change_table.
*   Fixed column type inference for some cases where the column included Z
    and/or M.
*   IS NULL predicates now work properly with spatial types.
*   Preferred attribute type is now :spatial rather than :geometry.
*   The gem version is now accessible via an api.
*   Some code reorganization.


### 0.2.4 / 2011-01-13

*   Fixed a problem that caused a hang during rake db:rollback, as well as
    probably certain other functions that use ActiveRecord::Base directly
    rather than a subclass. (Reported by Alexander Graefe.)


### 0.2.3 / 2011-01-07

*   Updated gem dependencies to include Arel 2.0.6, since some earlier Arel
    versions weren't working. (Reported by Pirmin Kalberer.)


### 0.2.2 / 2011-01-06

*   Some adjustments to the Arel integration for future Arel compatibility.
    (Thanks to Aaron Patterson.)
*   Support code for hacking ActiveRecord's rake tasks.


### 0.2.1 / 2010-12-27

*   Support for RGeo features as nodes in the Arel AST.
*   Basic utility Arel visitor methods for handling spatial equality nodes in
    where-expressions.


### 0.2.0 / 2010-12-07

*   Initial public alpha release. Spun rgeo-activerecord off from the core
    rgeo gem.
*   Support for setting factory by column.


For earlier history, see the History file for the rgeo gem.
