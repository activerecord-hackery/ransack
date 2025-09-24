#include "preface.h"

#ifdef RGEO_GEOS_SUPPORTED

#include <ctype.h>
#include <geos_c.h>
#include <ruby.h>
#include <stdarg.h>
#include <stdio.h>

#include "errors.h"
#include "globals.h"

RGEO_BEGIN_C

VALUE rgeo_module;

VALUE rgeo_feature_module;
VALUE rgeo_feature_geometry_module;
VALUE rgeo_feature_point_module;
VALUE rgeo_feature_line_string_module;
VALUE rgeo_feature_linear_ring_module;
VALUE rgeo_feature_line_module;
VALUE rgeo_feature_polygon_module;
VALUE rgeo_feature_geometry_collection_module;
VALUE rgeo_feature_multi_point_module;
VALUE rgeo_feature_multi_line_string_module;
VALUE rgeo_feature_multi_polygon_module;

VALUE rgeo_geos_module;
VALUE rgeo_geos_geometry_class;
VALUE rgeo_geos_point_class;
VALUE rgeo_geos_line_string_class;
VALUE rgeo_geos_linear_ring_class;
VALUE rgeo_geos_line_class;
VALUE rgeo_geos_polygon_class;
VALUE rgeo_geos_geometry_collection_class;
VALUE rgeo_geos_multi_point_class;
VALUE rgeo_geos_multi_line_string_class;
VALUE rgeo_geos_multi_polygon_class;

// The notice handler is very rarely used by GEOS, only in
// GEOSIsValid_r (check for NOTICE_MESSAGE in GEOS codebase).
// We still set it to make sure we do not miss any implementation
// change. Use `DEBUG=1 rake` to show notice.
static void
notice_handler(const char* fmt, ...)
{
#ifdef DEBUG
  va_list args;
  va_start(args, fmt);
  fprintf(stderr, "GEOS Notice -- ");
  vfprintf(stderr, fmt, args);
  fprintf(stderr, "\n");
  va_end(args);
#endif
}

static void
error_handler(const char* fmt, ...)
{
  // See https://en.cppreference.com/w/c/io/vfprintf
  va_list args1;
  va_start(args1, fmt);
  va_list args2;
  va_copy(args2, args1);
  int size = 1 + vsnprintf(NULL, 0, fmt, args1);
  va_end(args1);
  char geos_full_error[size];
  vsnprintf(geos_full_error, sizeof geos_full_error, fmt, args2);
  va_end(args2);

  // NOTE: strtok is destructive, geos_full_error is not to be used afterwards.
  char* geos_error = strtok(geos_full_error, ":");
  char* geos_message = strtok(NULL, ":");
  while (isspace(*geos_message))
    geos_message++;

  if (streq(geos_error, "UnsupportedOperationException")) {
    rb_raise(rb_eRGeoUnsupportedOperation, "%s", geos_message);
  } else if (streq(geos_error, "IllegalArgumentException")) {
    rb_raise(rb_eRGeoInvalidGeometry, "%s", geos_message);
  } else if (streq(geos_error, "ParseException")) {
    rb_raise(rb_eRGeoParseError, "%s", geos_message);
  } else if (geos_message) {
    rb_raise(rb_eGeosError, "%s: %s", geos_error, geos_message);
  } else {
    rb_raise(rb_eGeosError, "%s", geos_error);
  }
}

void
rgeo_init_geos_globals()
{
  initGEOS(notice_handler, error_handler);

  rgeo_module = rb_define_module("RGeo");
  rb_gc_register_mark_object(rgeo_module);

  rgeo_feature_module = rb_define_module_under(rgeo_module, "Feature");
  rb_gc_register_mark_object(rgeo_feature_module);
  rgeo_feature_geometry_module =
    rb_const_get_at(rgeo_feature_module, rb_intern("Geometry"));
  rb_gc_register_mark_object(rgeo_feature_geometry_module);
  rgeo_feature_point_module =
    rb_const_get_at(rgeo_feature_module, rb_intern("Point"));
  rb_gc_register_mark_object(rgeo_feature_point_module);
  rgeo_feature_line_string_module =
    rb_const_get_at(rgeo_feature_module, rb_intern("LineString"));
  rb_gc_register_mark_object(rgeo_feature_line_string_module);
  rgeo_feature_linear_ring_module =
    rb_const_get_at(rgeo_feature_module, rb_intern("LinearRing"));
  rb_gc_register_mark_object(rgeo_feature_linear_ring_module);
  rgeo_feature_line_module =
    rb_const_get_at(rgeo_feature_module, rb_intern("Line"));
  rb_gc_register_mark_object(rgeo_feature_line_module);
  rgeo_feature_polygon_module =
    rb_const_get_at(rgeo_feature_module, rb_intern("Polygon"));
  rb_gc_register_mark_object(rgeo_feature_polygon_module);
  rgeo_feature_geometry_collection_module =
    rb_const_get_at(rgeo_feature_module, rb_intern("GeometryCollection"));
  rb_gc_register_mark_object(rgeo_feature_geometry_collection_module);
  rgeo_feature_multi_point_module =
    rb_const_get_at(rgeo_feature_module, rb_intern("MultiPoint"));
  rb_gc_register_mark_object(rgeo_feature_multi_point_module);
  rgeo_feature_multi_line_string_module =
    rb_const_get_at(rgeo_feature_module, rb_intern("MultiLineString"));
  rb_gc_register_mark_object(rgeo_feature_multi_line_string_module);
  rgeo_feature_multi_polygon_module =
    rb_const_get_at(rgeo_feature_module, rb_intern("MultiPolygon"));
  rb_gc_register_mark_object(rgeo_feature_multi_polygon_module);

  rgeo_geos_module = rb_define_module_under(rgeo_module, "Geos");
  rb_gc_register_mark_object(rgeo_geos_module);
  rgeo_geos_geometry_class =
    rb_define_class_under(rgeo_geos_module, "CAPIGeometryImpl", rb_cObject);
  rb_gc_register_mark_object(rgeo_geos_geometry_class);
  rgeo_geos_point_class =
    rb_define_class_under(rgeo_geos_module, "CAPIPointImpl", rb_cObject);
  rb_gc_register_mark_object(rgeo_geos_point_class);
  rgeo_geos_line_string_class =
    rb_define_class_under(rgeo_geos_module, "CAPILineStringImpl", rb_cObject);
  rb_gc_register_mark_object(rgeo_geos_line_string_class);
  rgeo_geos_linear_ring_class =
    rb_define_class_under(rgeo_geos_module, "CAPILinearRingImpl", rb_cObject);
  rb_gc_register_mark_object(rgeo_geos_linear_ring_class);
  rgeo_geos_line_class =
    rb_define_class_under(rgeo_geos_module, "CAPILineImpl", rb_cObject);
  rb_gc_register_mark_object(rgeo_geos_line_class);
  rgeo_geos_polygon_class =
    rb_define_class_under(rgeo_geos_module, "CAPIPolygonImpl", rb_cObject);
  rb_gc_register_mark_object(rgeo_geos_polygon_class);
  rgeo_geos_geometry_collection_class = rb_define_class_under(
    rgeo_geos_module, "CAPIGeometryCollectionImpl", rb_cObject);
  rb_gc_register_mark_object(rgeo_geos_geometry_collection_class);
  rgeo_geos_multi_point_class =
    rb_define_class_under(rgeo_geos_module, "CAPIMultiPointImpl", rb_cObject);
  rb_gc_register_mark_object(rgeo_geos_multi_point_class);
  rgeo_geos_multi_line_string_class = rb_define_class_under(
    rgeo_geos_module, "CAPIMultiLineStringImpl", rb_cObject);
  rb_gc_register_mark_object(rgeo_geos_multi_line_string_class);
  rgeo_geos_multi_polygon_class =
    rb_define_class_under(rgeo_geos_module, "CAPIMultiPolygonImpl", rb_cObject);
  rb_gc_register_mark_object(rgeo_geos_multi_polygon_class);
}

RGEO_END_C

#endif
