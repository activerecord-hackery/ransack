/*
  Polygon methods for GEOS wrapper
*/

#ifndef RGEO_GEOS_POLYGON_INCLUDED
#define RGEO_GEOS_POLYGON_INCLUDED

#include <geos_c.h>
#include <ruby.h>

RGEO_BEGIN_C

/*
  Initializes the polygon module. This should be called after
  the geometry module is initialized.
*/
void
rgeo_init_geos_polygon();

/*
  Compares the values of two GEOS polygons. The two given geometries MUST
  be polygon types.
  Returns Qtrue if the polygons are equal, Qfalse if they are inequal, or
  Qnil if an error occurs.
*/
VALUE
rgeo_geos_polygons_eql(const GEOSGeometry* geom1,
                       const GEOSGeometry* geom2,
                       char check_z);

/*
  A tool for building up hash values.
  You must pass in a geos geometry, and a seed hash.
  Returns an updated hash.
  This call is useful in sequence, and should be bracketed by calls to
  rb_hash_start and rb_hash_end.
*/
st_index_t
rgeo_geos_polygon_hash(const GEOSGeometry* geom, st_index_t hash);

RGEO_END_C

#endif
