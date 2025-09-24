/*
  Geometry base class methods for GEOS wrapper
*/

#ifndef RGEO_GEOS_GEOMETRY_INCLUDED
#define RGEO_GEOS_GEOMETRY_INCLUDED

RGEO_BEGIN_C

/*
  Initializes the geometry module. This should be called after the factory
  module is initialized, but before any of the other modules.
*/
void
rgeo_init_geos_geometry();

/*
  Compares two geometries using strict GEOS comparison. return Qtrue
  if they are equal, Qfalse otherwise.
  May raise a `RGeo::Error::GeosError`.
*/
VALUE
rgeo_geos_geometries_strict_eql(const GEOSGeometry* geom1,
                                const GEOSGeometry* geom2);

RGEO_END_C

#endif
