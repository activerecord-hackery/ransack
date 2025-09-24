/*
  Point methods for GEOS wrapper
*/

#ifndef RGEO_GEOS_POINT_INCLUDED
#define RGEO_GEOS_POINT_INCLUDED

#include <ruby.h>

RGEO_BEGIN_C

/*
  Initializes the point module. This should be called after
  the geometry module is initialized.
*/
void
rgeo_init_geos_point();

/*
  Creates a 3d point and returns the ruby object.
*/
VALUE
rgeo_create_geos_point(VALUE factory, double x, double y, double z);

RGEO_END_C

#endif
