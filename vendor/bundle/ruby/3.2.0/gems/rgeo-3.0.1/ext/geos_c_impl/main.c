/*
  Main initializer for GEOS wrapper
*/

#include "preface.h"

#ifdef RGEO_GEOS_SUPPORTED

#include <geos_c.h>
#include <ruby.h>

#include "analysis.h"
#include "errors.h"
#include "factory.h"
#include "geometry.h"
#include "geometry_collection.h"
#include "globals.h"
#include "line_string.h"
#include "point.h"
#include "polygon.h"
#include "ruby_more.h"

#endif

RGEO_BEGIN_C

void
Init_geos_c_impl()
{
#ifdef RGEO_GEOS_SUPPORTED
  rgeo_init_geos_globals();
  rgeo_init_geos_factory();
  rgeo_init_geos_geometry();
  rgeo_init_geos_point();
  rgeo_init_geos_line_string();
  rgeo_init_geos_polygon();
  rgeo_init_geos_geometry_collection();
  rgeo_init_geos_analysis();
  rgeo_init_geos_errors();
#endif
}

RGEO_END_C
