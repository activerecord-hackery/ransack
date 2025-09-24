# frozen_string_literal: true

# RGeo is a spatial data library for Ruby. It focuses on the storage and
# manipulation of spatial data types such as points, lines, and polygons.
#
# RGeo comprises a number of modules. The "rgeo" gem provides a suite of
# standard modules. Additional optional modules are provided by separate
# gems with names of the form "<tt>rgeo-*</tt>".
#
# === Standard modules
#
# These are the standard modules provided by the "rgeo" gem.
#
# * RGeo::Feature contains interface specifications for spatial
#   objects implemented by RGeo. These interfaces closely follow the OGC
#   Simple Features Specifiation (SFS). This module forms the core of RGeo.
#
# * RGeo::CoordSys contains classes for representing spatial
#   reference systems and coordinate transformations.
#
# * RGeo::Cartesian is a gateway for geometric data implementations
#   that operate in Caresian (flat) coordinate systems. It also provides a
#   basic pure ruby Cartesian implementation. This implementation does not
#   cover all the geometric analysis operations defined by the SFS, but it
#   does not require an external C library and is often sufficient for
#   basic applications.
#
# * RGeo::Geos is another Cartesian implementation that wraps the
#   GEOS library to provide a full, high-performance implementation of
#   Cartesian geometry that includes every operation defined in the SFS.
#   It requires GEOS 3.2 or later.
#
# * RGeo::Geographic contains spatial implementations that operate
#   in latitude-longitude coordinates and are well-suited for geographic
#   location based applications. Geographic spatial objects may also be
#   linked to projections.
#
# * RGeo::WKRep contains tools for reading and writing spatial
#   data in the OGC Well-Known Text (WKT) and Well-Known Binary (WKB)
#   representations. It also supports common variants such as the PostGIS
#   EWKT and EWKB representations.
#
# === Optional Modules
#
# Here is a partial list of optional modules available as separate gems.
#
# * <b>rgeo-geojson</b> provides the RGeo::GeoJSON module, containing
#   tools for GeoJSON encoding and decoding of spatial objects.
#
# * <b>rgeo-shapefile</b> provides the RGeo::Shapefile module, containing
#   tools for reading ESRI shapefiles.
#
# * <b>rgeo-activerecord</b> provides the RGeo::ActiveRecord module,
#   containing some ActiveRecord extensions for spatial databases, and a
#   set of common tools for ActiveRecord spatial database adapters.
#
# Several ActiveRecord adapters use RGeo. These include:
#
# * <b>mysqlspatial</b>, an adapter for MySQL spatial extensions based on
#   the mysql adapter. Available as the activerecord-mysqlspatial-adapter
#   gem. <i>This adapter is deprecated due to bugs in the legacy mysql
#   gem. You should use the mysql2spatial adapter instead.</i>
#
# * <b>mysql2spatial</b>, an adapter for MySQL spatial extensions based on
#   the mysql2 adapter. Available as the activerecord-mysql2spatial-adapter
#   gem.
#
# * <b>spatialite</b>, an adapter for the SpatiaLite extension to the
#   Sqlite3 database, and based on the sqlite3 adapter. Available as the
#   activerecord-spatialite-adapter gem.
#
# * <b>postgis</b>, an adapter for the PostGIS extension to the PostgreSQL
#   database, and based on the postgresql adapter. Available as the
#   activerecord-postgis-adapter gem.

require_relative "rgeo/version"
require_relative "rgeo/error"
require_relative "rgeo/feature"
require_relative "rgeo/coord_sys"
require_relative "rgeo/impl_helper"
require_relative "rgeo/wkrep"
require_relative "rgeo/geos"
require_relative "rgeo/cartesian"
require_relative "rgeo/geographic"
