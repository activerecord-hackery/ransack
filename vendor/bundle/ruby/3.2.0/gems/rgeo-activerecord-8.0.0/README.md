## RGeo::ActiveRecord

[![Gem version](https://img.shields.io/gem/v/rgeo-activerecord)](https://rubygems.org/gems/rgeo-activerecord)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/rgeo/rgeo-activerecord/test.yml?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/a2c8d3082dbc1b223cd2/maintainability)](https://codeclimate.com/github/rgeo/rgeo-activerecord/maintainability)

RGeo::ActiveRecord is an optional [RGeo](http://github.com/rgeo/rgeo) module
providing spatial extensions for ActiveRecord, as well as a set of helpers for
writing spatial ActiveRecord adapters based on RGeo.

### Summary

RGeo is a key component for writing location-aware applications in the Ruby
programming language. At its core is an implementation of the industry
standard OGC Simple Features Specification, which provides data
representations of geometric objects such as points, lines, and polygons,
along with a set of geometric analysis operations. See the README for the
"rgeo" gem for more information.

RGeo::ActiveRecord is an optional RGeo add-on module providing spatial
extensions for ActiveRecord, as well as a set of helpers for writing spatial
ActiveRecord adapters based on RGeo.

### Installation

Gemfile:

```ruby
gem 'rgeo-activerecord'
```

Version `8.0+` supports ActiveRecord 7.x with `rgeo` 3.0+

Version `7.0+` supports ActiveRecord 5.x, 6.x, and 7.x with `rgeo` 1.0+

Version `6.2+` supports ActiveRecord 5.x and 6.x with `rgeo` 1.0+

Version `6.1` supports ActiveRecord 5.x and 6.0 with `rgeo` 1.0+.

Version `6.0` supports ActiveRecord 5.x with `rgeo` 1.x.

Version `5.0` supports ActiveRecord 5.0 and 5.1, with `rgeo` 0.6.

Version `4.0` supports ActiveRecord 4.2.

Version `1.1.0` supports ActiveRecord 4.0 and 4.1

Version `0.6.0` supports earlier versions of ruby and ActiveRecord:

- Ruby 1.8.7 or later
- ActiveRecord 3.0.3 - 3.2.x
- rgeo 0.3.20 or later
- arel 2.0.6 or later

### Spatial Factories for Columns

**_This is an introduction. More details are available in the [wiki entry](https://github.com/rgeo/rgeo-activerecord/wiki/Spatial-Factory-Store)._**

Register spatial factories in the `SpatialFactoryStore` singleton class to parse spatial data. Each spatial column
in your models will use the `SpatialFactoryStore` to parse the stored WKB into an RGeo Feature. The factory from the `SpatialFactoryStore` is chosen based on metadata from the spatial column and the attributes with which the factory was registered to the store. For example, you can set a factory for point types, for types matching a specific SRID, having
a Z coordinate, or any combination of attributes.

The supported keys when registering a spatial type are listed here with their expected values:

```
geo_type: string  # geometry, point, polygon, line_string, geometry_collection,
                  # multi_line_string, multi_point, multi_polygon
has_m:    boolean # true, false
has_z:    boolean # true, false
sql_type: string  # geometry, geography
srid:     int     # (any valid SRID)
```

The default factories are `RGeo::Geographic.spherical_factory` for
geographic types, and `RGeo::Cartesian.preferred_factory` for geometric types.

Here is an example setup:

```rb
RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  # By default, use the GEOS implementation for spatial columns.
  config.default = RGeo::Geos.factory

  # But use a geographic implementation for point columns.
  config.register(RGeo::Geographic.spherical_factory(srid: 4326), geo_type: "point")
end
```

_NOTE: `rgeo_factory_generator` and related methods were removed in version 4.0, since column types
are no longer tied to their database column in ActiveRecord 4.2._

### Spatial Queries

RGeo-ActiveRecord provides an Arel interface to use functions commonly found in spatial databases. The interface also allows for the creation of your own spatial functions if they are not defined.

Here is an example using `st_contains`:

```rb
point = RGeo::Geos.factory(srid: 0).point(1,1)

buildings = Building.arel_table
containing_buiildings = Building.where(buildings[:geom].st_contains(point))
```

or using the `Arel.spatial` node:

```rb
point = "SRID=0;POINT(1,1)"

buildings = Building.arel_table
containing_buiildings = Building.where(buildings[:geom].st_contains(Arel.spatial(point)))
```

_Note: If you pass a WKT representation into an st_function, you should prepend the string with SRID=your_srid, otherwise the database will assume SRID=0 which may cause errors on certain operations._

### RGeo Dependency

See the README for the [rgeo](https://github.com/rgeo/rgeo) gem, a dependency, for further
installation information.

### Development and support

This README is the official documentation.

RDoc documentation is available at http://rdoc.info/gems/rgeo-activerecord

Source code is hosted on Github at http://github.com/rgeo/rgeo-activerecord

Contributions are welcome. Fork the project on Github.

Report bugs on Github issues at
http://github.com/rgeo/rgeo-activerecord/issues

Support available on the rgeo-users google group at
http://groups.google.com/group/rgeo-users

### Acknowledgments

[Daniel Azuma](http://www.daniel-azuma.com) created RGeo.
[Tee Parham](http://twitter.com/teeparham) is a former maintainer.
[Keith Doggett](http://www.github.com/keithdoggett) is a current maintainer.
[Ulysse Buonomo](http://www.github.com/BuonOmo) is a current maintainer.

Development is supported by:

- [Klaxit](https://www.klaxit.com)
- Goldfish Ads

### License

Copyright 2020 Daniel Azuma, Tee Parham

https://github.com/rgeo/rgeo-activerecord/blob/master/LICENSE.txt
