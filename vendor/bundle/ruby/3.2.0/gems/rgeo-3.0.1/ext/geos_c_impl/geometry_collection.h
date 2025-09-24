/*
  Geometry collection methods for GEOS wrapper
*/

#ifndef RGEO_GEOS_GEOMETRY_COLLECTION_INCLUDED
#define RGEO_GEOS_GEOMETRY_COLLECTION_INCLUDED

#include <geos_c.h>
#include <ruby.h>

RGEO_BEGIN_C

/*
  Initializes the geometry collection module. This should be called after
  the geometry module is initialized.
*/
void
rgeo_init_geos_geometry_collection();

/*
  A tool for building up hash values.
  You must pass in a geos geometry and a seed hash.
  Returns an updated hash.
  This call is useful in sequence, and should be bracketed by calls to
  rb_hash_start and rb_hash_end.
*/
st_index_t
rgeo_geos_geometry_collection_hash(const GEOSGeometry* geom, st_index_t hash);

RGEO_END_C

#endif
