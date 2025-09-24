/*
  Per-interpreter globals.
  Most of these are cached references to commonly used classes, modules,
  and symbols so we don't have to do a lot of constant lookups and calls
  to rb_intern.
*/

#ifndef RGEO_GEOS_GLOBALS_INCLUDED
#define RGEO_GEOS_GLOBALS_INCLUDED

#include <geos_c.h>

RGEO_BEGIN_C

extern VALUE rgeo_module;

extern VALUE rgeo_feature_module;
extern VALUE rgeo_feature_geometry_module;
extern VALUE rgeo_feature_point_module;
extern VALUE rgeo_feature_line_string_module;
extern VALUE rgeo_feature_linear_ring_module;
extern VALUE rgeo_feature_line_module;
extern VALUE rgeo_feature_polygon_module;
extern VALUE rgeo_feature_geometry_collection_module;
extern VALUE rgeo_feature_multi_point_module;
extern VALUE rgeo_feature_multi_line_string_module;
extern VALUE rgeo_feature_multi_polygon_module;

extern VALUE rgeo_geos_module;
extern VALUE rgeo_geos_geometry_class;
extern VALUE rgeo_geos_point_class;
extern VALUE rgeo_geos_line_string_class;
extern VALUE rgeo_geos_linear_ring_class;
extern VALUE rgeo_geos_line_class;
extern VALUE rgeo_geos_polygon_class;
extern VALUE rgeo_geos_geometry_collection_class;
extern VALUE rgeo_geos_multi_point_class;
extern VALUE rgeo_geos_multi_line_string_class;
extern VALUE rgeo_geos_multi_polygon_class;

void
rgeo_init_geos_globals();

RGEO_END_C

#endif
