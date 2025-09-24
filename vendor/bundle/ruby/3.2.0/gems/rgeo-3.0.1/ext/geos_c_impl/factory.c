/*
  Factory and utility functions for GEOS wrapper
*/

#include "preface.h"

#ifdef RGEO_GEOS_SUPPORTED

#include <geos_c.h>
#include <ruby.h>

#include "errors.h"
#include "factory.h"
#include "geometry.h"
#include "geometry_collection.h"
#include "globals.h"
#include "line_string.h"
#include "point.h"
#include "polygon.h"
#include "ruby_more.h"

RGEO_BEGIN_C

/**** RUBY AND GEOS CALLBACKS ****/

// Destroy function for factory data. We destroy any serialization
// objects that have been created for the factory before freeing
// the factory data itself.

static void
destroy_factory_func(void* data)
{
  RGeo_FactoryData* factory_data;

  factory_data = (RGeo_FactoryData*)data;
  if (factory_data->wkt_reader) {
    GEOSWKTReader_destroy(factory_data->wkt_reader);
  }
  if (factory_data->wkb_reader) {
    GEOSWKBReader_destroy(factory_data->wkb_reader);
  }
  if (factory_data->wkt_writer) {
    GEOSWKTWriter_destroy(factory_data->wkt_writer);
  }
  if (factory_data->wkb_writer) {
    GEOSWKBWriter_destroy(factory_data->wkb_writer);
  }
  if (factory_data->psych_wkt_reader) {
    GEOSWKTReader_destroy(factory_data->psych_wkt_reader);
  }
  if (factory_data->marshal_wkb_reader) {
    GEOSWKBReader_destroy(factory_data->marshal_wkb_reader);
  }
  if (factory_data->psych_wkt_writer) {
    GEOSWKTWriter_destroy(factory_data->psych_wkt_writer);
  }
  if (factory_data->marshal_wkb_writer) {
    GEOSWKBWriter_destroy(factory_data->marshal_wkb_writer);
  }
  FREE(factory_data);
}

// Destroy function for geometry data. We destroy the internal
// GEOS geometry (if present) before freeing the data itself.

static void
destroy_geometry_func(void* data)
{
  RGeo_GeometryData* geometry_data;
  const GEOSPreparedGeometry* prep;

  geometry_data = (RGeo_GeometryData*)data;
  if (geometry_data->geom) {
    GEOSGeom_destroy(geometry_data->geom);
  }
  prep = geometry_data->prep;
  if (prep && prep != (const GEOSPreparedGeometry*)1 &&
      prep != (const GEOSPreparedGeometry*)2 &&
      prep != (const GEOSPreparedGeometry*)3) {
    GEOSPreparedGeom_destroy(prep);
  }
  FREE(geometry_data);
}

// Mark function for factory data. This marks the wkt and wkb generator
// handles so they don't get collected.

static void
mark_factory_func(void* data)
{
  RGeo_FactoryData* factory_data;

  factory_data = (RGeo_FactoryData*)data;
  if (!NIL_P(factory_data->wkrep_wkt_generator)) {
    mark(factory_data->wkrep_wkt_generator);
  }
  if (!NIL_P(factory_data->wkrep_wkb_generator)) {
    mark(factory_data->wkrep_wkb_generator);
  }
  if (!NIL_P(factory_data->wkrep_wkt_parser)) {
    mark(factory_data->wkrep_wkt_parser);
  }
  if (!NIL_P(factory_data->wkrep_wkb_parser)) {
    mark(factory_data->wkrep_wkb_parser);
  }
  if (!NIL_P(factory_data->coord_sys_obj)) {
    mark(factory_data->coord_sys_obj);
  }
}

// Mark function for geometry data. This marks the factory and klasses
// held by the geometry so those don't get collected.

static void
mark_geometry_func(void* data)
{
  RGeo_GeometryData* geometry_data;

  geometry_data = (RGeo_GeometryData*)data;
  if (!NIL_P(geometry_data->factory)) {
    mark(geometry_data->factory);
  }
  if (!NIL_P(geometry_data->klasses)) {
    mark(geometry_data->klasses);
  }
}

#ifdef HAVE_RB_GC_MARK_MOVABLE
static void
compact_factory_func(void* data)
{
  RGeo_FactoryData* factory_data;

  factory_data = (RGeo_FactoryData*)data;
  if (!NIL_P(factory_data->wkrep_wkt_generator)) {
    factory_data->wkrep_wkt_generator =
      rb_gc_location(factory_data->wkrep_wkt_generator);
  }
  if (!NIL_P(factory_data->wkrep_wkb_generator)) {
    factory_data->wkrep_wkb_generator =
      rb_gc_location(factory_data->wkrep_wkb_generator);
  }
  if (!NIL_P(factory_data->wkrep_wkt_parser)) {
    factory_data->wkrep_wkt_parser =
      rb_gc_location(factory_data->wkrep_wkt_parser);
  }
  if (!NIL_P(factory_data->wkrep_wkb_parser)) {
    factory_data->wkrep_wkb_parser =
      rb_gc_location(factory_data->wkrep_wkb_parser);
  }
  if (!NIL_P(factory_data->coord_sys_obj)) {
    factory_data->coord_sys_obj = rb_gc_location(factory_data->coord_sys_obj);
  }
}

static void
compact_geometry_func(void* data)
{
  RGeo_GeometryData* geometry_data;

  geometry_data = (RGeo_GeometryData*)data;
  if (!NIL_P(geometry_data->factory)) {
    geometry_data->factory = rb_gc_location(geometry_data->factory);
  }
  if (!NIL_P(geometry_data->klasses)) {
    geometry_data->klasses = rb_gc_location(geometry_data->klasses);
  }
}
#endif

const rb_data_type_t rgeo_factory_type = { .wrap_struct_name = "RGeo/Factory",
                                           .function = {
                                             .dmark = mark_factory_func,
                                             .dfree = destroy_factory_func,
#ifdef HAVE_RB_GC_MARK_MOVABLE
                                             .dcompact = compact_factory_func,
#endif
                                           } };

const rb_data_type_t rgeo_geometry_type = { .wrap_struct_name = "RGeo/Geometry",
                                            .function = {
                                              .dmark = mark_geometry_func,
                                              .dfree = destroy_geometry_func,
#ifdef HAVE_RB_GC_MARK_MOVABLE
                                              .dcompact = compact_geometry_func,
#endif
                                            } };

/**** RUBY METHOD DEFINITIONS ****/

static VALUE
method_factory_srid(VALUE self)
{
  return INT2NUM(RGEO_FACTORY_DATA_PTR(self)->srid);
}

static VALUE
method_factory_buffer_resolution(VALUE self)
{
  return INT2NUM(RGEO_FACTORY_DATA_PTR(self)->buffer_resolution);
}

static VALUE
method_factory_flags(VALUE self)
{
  return INT2NUM(RGEO_FACTORY_DATA_PTR(self)->flags);
}

VALUE
method_factory_supports_z_p(VALUE self)
{
  return RGEO_FACTORY_DATA_PTR(self)->flags & RGEO_FACTORYFLAGS_SUPPORTS_Z
           ? Qtrue
           : Qfalse;
}

VALUE
method_factory_supports_m_p(VALUE self)
{
  return RGEO_FACTORY_DATA_PTR(self)->flags & RGEO_FACTORYFLAGS_SUPPORTS_M
           ? Qtrue
           : Qfalse;
}

VALUE
method_factory_supports_z_or_m_p(VALUE self)
{
  return RGEO_FACTORY_DATA_PTR(self)->flags & RGEO_FACTORYFLAGS_SUPPORTS_Z_OR_M
           ? Qtrue
           : Qfalse;
}

VALUE
method_factory_prepare_heuristic_p(VALUE self)
{
  return RGEO_FACTORY_DATA_PTR(self)->flags &
             RGEO_FACTORYFLAGS_PREPARE_HEURISTIC
           ? Qtrue
           : Qfalse;
}

static VALUE
method_factory_parse_wkt(VALUE self, VALUE str)
{
  RGeo_FactoryData* self_data;
  GEOSWKTReader* wkt_reader;
  VALUE result;
  GEOSGeometry* geom;

  Check_Type(str, T_STRING);
  self_data = RGEO_FACTORY_DATA_PTR(self);
  wkt_reader = self_data->wkt_reader;
  if (!wkt_reader) {
    wkt_reader = GEOSWKTReader_create();
    self_data->wkt_reader = wkt_reader;
  }
  result = Qnil;
  if (wkt_reader) {
    geom = GEOSWKTReader_read(wkt_reader, RSTRING_PTR(str));
    if (geom) {
      result = rgeo_wrap_geos_geometry(self, geom, Qnil);
    }
  }
  return result;
}

static VALUE
method_factory_parse_wkb(VALUE self, VALUE str)
{
  RGeo_FactoryData* self_data;
  GEOSWKBReader* wkb_reader;
  VALUE result;
  GEOSGeometry* geom;
  char* c_str;

  Check_Type(str, T_STRING);
  self_data = RGEO_FACTORY_DATA_PTR(self);
  wkb_reader = self_data->wkb_reader;
  if (!wkb_reader) {
    wkb_reader = GEOSWKBReader_create();
    self_data->wkb_reader = wkb_reader;
  }
  result = Qnil;
  if (wkb_reader) {
    c_str = RSTRING_PTR(str);
    if (c_str[0] == '\x00' || c_str[0] == '\x01')
      geom = GEOSWKBReader_read(
        wkb_reader, (unsigned char*)c_str, (size_t)RSTRING_LEN(str));
    else
      geom = GEOSWKBReader_readHEX(
        wkb_reader, (unsigned char*)c_str, (size_t)RSTRING_LEN(str));
    if (geom) {
      result = rgeo_wrap_geos_geometry(self, geom, Qnil);
    }
  }
  return result;
}

static VALUE
method_factory_read_for_marshal(VALUE self, VALUE str)
{
  RGeo_FactoryData* self_data;
  GEOSWKBReader* wkb_reader;
  VALUE result;
  GEOSGeometry* geom;

  Check_Type(str, T_STRING);
  self_data = RGEO_FACTORY_DATA_PTR(self);
  wkb_reader = self_data->marshal_wkb_reader;
  if (!wkb_reader) {
    wkb_reader = GEOSWKBReader_create();
    self_data->marshal_wkb_reader = wkb_reader;
  }
  result = Qnil;
  if (wkb_reader) {
    geom = GEOSWKBReader_read(
      wkb_reader, (unsigned char*)RSTRING_PTR(str), (size_t)RSTRING_LEN(str));
    if (geom) {
      result = rgeo_wrap_geos_geometry(self, geom, Qnil);
    }
  }
  return result;
}

static VALUE
method_factory_read_for_psych(VALUE self, VALUE str)
{
  RGeo_FactoryData* self_data;
  GEOSWKTReader* wkt_reader;
  VALUE result;
  GEOSGeometry* geom;

  Check_Type(str, T_STRING);
  self_data = RGEO_FACTORY_DATA_PTR(self);
  wkt_reader = self_data->psych_wkt_reader;
  if (!wkt_reader) {
    wkt_reader = GEOSWKTReader_create();
    self_data->psych_wkt_reader = wkt_reader;
  }
  result = Qnil;
  if (wkt_reader) {
    geom = GEOSWKTReader_read(wkt_reader, RSTRING_PTR(str));
    if (geom) {
      result = rgeo_wrap_geos_geometry(self, geom, Qnil);
    }
  }
  return result;
}

#ifndef RGEO_GEOS_SUPPORTS_SETOUTPUTDIMENSION
static VALUE marshal_wkb_generator;
#endif

static VALUE
method_factory_write_for_marshal(VALUE self, VALUE obj)
{
  RGeo_FactoryData* self_data;
  GEOSWKBWriter* wkb_writer;
  const GEOSGeometry* geom;
  VALUE result;
  char* str;
  size_t size;
  char has_3d;

  self_data = RGEO_FACTORY_DATA_PTR(self);
  has_3d = self_data->flags & RGEO_FACTORYFLAGS_SUPPORTS_Z_OR_M;
#ifndef RGEO_GEOS_SUPPORTS_SETOUTPUTDIMENSION
  if (has_3d) {
    if (NIL_P(marshal_wkb_generator)) {
      marshal_wkb_generator =
        rb_funcall(rb_const_get_at(rgeo_geos_module, rb_intern("Utils")),
                   rb_intern("marshal_wkb_generator"),
                   0);
    }
    return rb_funcall(marshal_wkb_generator, rb_intern("generate"), 1, obj);
  }
#endif
  wkb_writer = self_data->marshal_wkb_writer;
  if (!wkb_writer) {
    wkb_writer = GEOSWKBWriter_create();
    GEOSWKBWriter_setOutputDimension(wkb_writer, 2);
    if (has_3d) {
      GEOSWKBWriter_setOutputDimension(wkb_writer, 3);
    }
    self_data->marshal_wkb_writer = wkb_writer;
  }
  result = Qnil;
  if (wkb_writer) {
    geom = rgeo_get_geos_geometry_safe(obj);
    if (geom) {
      str = (char*)GEOSWKBWriter_write(wkb_writer, geom, &size);
      if (str) {
        result = rb_str_new(str, size);
        GEOSFree(str);
      }
    }
  }
  return result;
}

#ifndef RGEO_GEOS_SUPPORTS_SETOUTPUTDIMENSION
static VALUE psych_wkt_generator;
#endif

static VALUE
method_factory_write_for_psych(VALUE self, VALUE obj)
{
  RGeo_FactoryData* self_data;
  GEOSWKTWriter* wkt_writer;
  const GEOSGeometry* geom;
  VALUE result;
  char* str;
  char has_3d;

  self_data = RGEO_FACTORY_DATA_PTR(self);
  has_3d = self_data->flags & RGEO_FACTORYFLAGS_SUPPORTS_Z_OR_M;
#ifndef RGEO_GEOS_SUPPORTS_SETOUTPUTDIMENSION
  if (has_3d) {
    if (NIL_P(psych_wkt_generator)) {
      psych_wkt_generator =
        rb_funcall(rb_const_get_at(rgeo_geos_module, rb_intern("Utils")),
                   rb_intern("psych_wkt_generator"),
                   0);
    }
    return rb_funcall(psych_wkt_generator, rb_intern("generate"), 1, obj);
  }
#endif
  wkt_writer = self_data->psych_wkt_writer;
  if (!wkt_writer) {
    wkt_writer = GEOSWKTWriter_create();
    GEOSWKTWriter_setOutputDimension(wkt_writer, 2);
    GEOSWKTWriter_setTrim(wkt_writer, 1);
    if (has_3d) {
      GEOSWKTWriter_setOutputDimension(wkt_writer, 3);
    }
    self_data->psych_wkt_writer = wkt_writer;
  }
  result = Qnil;
  if (wkt_writer) {
    geom = rgeo_get_geos_geometry_safe(obj);
    if (geom) {
      str = GEOSWKTWriter_write(wkt_writer, geom);
      if (str) {
        result = rb_str_new2(str);
        GEOSFree(str);
      }
    }
  }
  return result;
}

static VALUE
cmethod_factory_geos_version(VALUE klass)
{
  return rb_str_new2(GEOS_VERSION);
}

static VALUE
cmethod_factory_supports_unary_union(VALUE klass)
{
#ifdef RGEO_GEOS_SUPPORTS_UNARYUNION
  return Qtrue;
#else
  return Qfalse;
#endif
}

static VALUE
cmethod_factory_create(VALUE klass,
                       VALUE flags,
                       VALUE srid,
                       VALUE buffer_resolution,
                       VALUE wkt_generator,
                       VALUE wkb_generator,
                       VALUE coord_sys_obj)
{
  VALUE result;
  RGeo_FactoryData* data;

  result = Qnil;
  data = ALLOC(RGeo_FactoryData);
  if (data) {
    data->flags = RB_NUM2INT(flags);
    data->srid = RB_NUM2INT(srid);
    data->buffer_resolution = RB_NUM2INT(buffer_resolution);
    data->wkt_reader = NULL;
    data->wkb_reader = NULL;
    data->wkt_writer = NULL;
    data->wkb_writer = NULL;
    data->psych_wkt_reader = NULL;
    data->marshal_wkb_reader = NULL;
    data->psych_wkt_writer = NULL;
    data->marshal_wkb_writer = NULL;
    data->wkrep_wkt_generator = wkt_generator;
    data->wkrep_wkb_generator = wkb_generator;
    data->wkrep_wkt_parser = Qnil;
    data->wkrep_wkb_parser = Qnil;
    data->coord_sys_obj = coord_sys_obj;
    result = TypedData_Wrap_Struct(klass, &rgeo_factory_type, data);
  }
  return result;
}

static VALUE
alloc_factory(VALUE klass)
{
  return cmethod_factory_create(
    klass, INT2NUM(0), INT2NUM(0), INT2NUM(0), Qnil, Qnil, Qnil);
}

static VALUE
method_factory_initialize_copy(VALUE self, VALUE orig)
{
  RGeo_FactoryData* self_data;
  RGeo_FactoryData* orig_data;

  // Clear out existing data
  self_data = RGEO_FACTORY_DATA_PTR(self);
  if (self_data->wkt_reader) {
    GEOSWKTReader_destroy(self_data->wkt_reader);
    self_data->wkt_reader = NULL;
  }
  if (self_data->wkb_reader) {
    GEOSWKBReader_destroy(self_data->wkb_reader);
    self_data->wkb_reader = NULL;
  }
  if (self_data->wkt_writer) {
    GEOSWKTWriter_destroy(self_data->wkt_writer);
    self_data->wkt_writer = NULL;
  }
  if (self_data->wkb_writer) {
    GEOSWKBWriter_destroy(self_data->wkb_writer);
    self_data->wkb_writer = NULL;
  }
  if (self_data->psych_wkt_reader) {
    GEOSWKTReader_destroy(self_data->psych_wkt_reader);
    self_data->psych_wkt_reader = NULL;
  }
  if (self_data->marshal_wkb_reader) {
    GEOSWKBReader_destroy(self_data->marshal_wkb_reader);
    self_data->marshal_wkb_reader = NULL;
  }
  if (self_data->psych_wkt_writer) {
    GEOSWKTWriter_destroy(self_data->psych_wkt_writer);
    self_data->psych_wkt_writer = NULL;
  }
  if (self_data->marshal_wkb_writer) {
    GEOSWKBWriter_destroy(self_data->marshal_wkb_writer);
    self_data->marshal_wkb_writer = NULL;
  }
  self_data->wkrep_wkt_generator = Qnil;
  self_data->wkrep_wkb_generator = Qnil;
  self_data->wkrep_wkt_parser = Qnil;
  self_data->wkrep_wkb_parser = Qnil;
  self_data->coord_sys_obj = Qnil;

  // Copy new data from original object
  if (RGEO_FACTORY_TYPEDDATA_P(orig)) {
    orig_data = RGEO_FACTORY_DATA_PTR(orig);
    self_data->flags = orig_data->flags;
    self_data->srid = orig_data->srid;
    self_data->buffer_resolution = orig_data->buffer_resolution;
    self_data->wkrep_wkt_generator = orig_data->wkrep_wkt_generator;
    self_data->wkrep_wkb_generator = orig_data->wkrep_wkb_generator;
    self_data->wkrep_wkt_parser = orig_data->wkrep_wkt_parser;
    self_data->wkrep_wkb_parser = orig_data->wkrep_wkb_parser;
    self_data->coord_sys_obj = orig_data->coord_sys_obj;
  }
  return self;
}

static VALUE
method_set_wkrep_parsers(VALUE self, VALUE wkt_parser, VALUE wkb_parser)
{
  RGeo_FactoryData* self_data;

  self_data = RGEO_FACTORY_DATA_PTR(self);
  self_data->wkrep_wkt_parser = wkt_parser;
  self_data->wkrep_wkb_parser = wkb_parser;

  return self;
}

static VALUE
method_get_coord_sys(VALUE self)
{
  return RGEO_FACTORY_DATA_PTR(self)->coord_sys_obj;
}

static VALUE
method_get_wkt_generator(VALUE self)
{
  return RGEO_FACTORY_DATA_PTR(self)->wkrep_wkt_generator;
}

static VALUE
method_get_wkb_generator(VALUE self)
{
  return RGEO_FACTORY_DATA_PTR(self)->wkrep_wkb_generator;
}

static VALUE
method_get_wkt_parser(VALUE self)
{
  return RGEO_FACTORY_DATA_PTR(self)->wkrep_wkt_parser;
}

static VALUE
method_get_wkb_parser(VALUE self)
{
  return RGEO_FACTORY_DATA_PTR(self)->wkrep_wkb_parser;
}

static VALUE
alloc_geometry(VALUE klass)
{
  return rgeo_wrap_geos_geometry(Qnil, NULL, klass);
}

/**** INITIALIZATION FUNCTION ****/

void
rgeo_init_geos_factory()
{
  VALUE geos_factory_class;

#ifndef RGEO_GEOS_SUPPORTS_SETOUTPUTDIMENSION
  /* We favor rb_gc_register_address over rb_gc_register_mark_object because
   * the value changes at runtime */
  psych_wkt_generator = Qnil;
  rb_gc_register_address(&psych_wkt_generator);
  marshal_wkb_generator = Qnil;
  rb_gc_register_address(&marshal_wkb_generator);
#endif

  geos_factory_class =
    rb_define_class_under(rgeo_geos_module, "CAPIFactory", rb_cObject);
  rb_define_alloc_func(geos_factory_class, alloc_factory);
  // Add C constants to the factory.
  rb_define_const(geos_factory_class,
                  "FLAG_SUPPORTS_Z",
                  INT2FIX(RGEO_FACTORYFLAGS_SUPPORTS_Z));
  rb_define_const(geos_factory_class,
                  "FLAG_SUPPORTS_M",
                  INT2FIX(RGEO_FACTORYFLAGS_SUPPORTS_M));
  rb_define_const(geos_factory_class,
                  "FLAG_SUPPORTS_Z_OR_M",
                  INT2FIX(RGEO_FACTORYFLAGS_SUPPORTS_Z_OR_M));
  rb_define_const(geos_factory_class,
                  "FLAG_PREPARE_HEURISTIC",
                  INT2FIX(RGEO_FACTORYFLAGS_PREPARE_HEURISTIC));
  // Add C methods to the factory.
  rb_define_method(
    geos_factory_class, "initialize_copy", method_factory_initialize_copy, 1);
  rb_define_method(
    geos_factory_class, "_parse_wkt_impl", method_factory_parse_wkt, 1);
  rb_define_method(
    geos_factory_class, "_parse_wkb_impl", method_factory_parse_wkb, 1);
  rb_define_method(geos_factory_class, "_srid", method_factory_srid, 0);
  rb_define_method(geos_factory_class,
                   "_buffer_resolution",
                   method_factory_buffer_resolution,
                   0);
  rb_define_method(geos_factory_class, "_flags", method_factory_flags, 0);
  rb_define_method(
    geos_factory_class, "supports_z?", method_factory_supports_z_p, 0);
  rb_define_method(
    geos_factory_class, "supports_m?", method_factory_supports_m_p, 0);
  rb_define_method(geos_factory_class,
                   "supports_z_or_m?",
                   method_factory_supports_z_or_m_p,
                   0);
  rb_define_method(geos_factory_class,
                   "prepare_heuristic?",
                   method_factory_prepare_heuristic_p,
                   0);
  rb_define_method(
    geos_factory_class, "_set_wkrep_parsers", method_set_wkrep_parsers, 2);
  rb_define_method(geos_factory_class, "_coord_sys", method_get_coord_sys, 0);
  rb_define_method(
    geos_factory_class, "_wkt_generator", method_get_wkt_generator, 0);
  rb_define_method(
    geos_factory_class, "_wkb_generator", method_get_wkb_generator, 0);
  rb_define_method(geos_factory_class, "_wkt_parser", method_get_wkt_parser, 0);
  rb_define_method(geos_factory_class, "_wkb_parser", method_get_wkb_parser, 0);
  rb_define_method(
    geos_factory_class, "read_for_marshal", method_factory_read_for_marshal, 1);
  rb_define_method(geos_factory_class,
                   "write_for_marshal",
                   method_factory_write_for_marshal,
                   1);
  rb_define_method(
    geos_factory_class, "read_for_psych", method_factory_read_for_psych, 1);
  rb_define_method(
    geos_factory_class, "write_for_psych", method_factory_write_for_psych, 1);
  rb_define_module_function(
    geos_factory_class, "_create", cmethod_factory_create, 6);
  rb_define_module_function(
    geos_factory_class, "_geos_version", cmethod_factory_geos_version, 0);
  rb_define_module_function(geos_factory_class,
                            "_supports_unary_union?",
                            cmethod_factory_supports_unary_union,
                            0);

  // Define allocation methods for global class types
  rb_define_alloc_func(rgeo_geos_geometry_class, alloc_geometry);
  rb_define_alloc_func(rgeo_geos_point_class, alloc_geometry);
  rb_define_alloc_func(rgeo_geos_line_string_class, alloc_geometry);
  rb_define_alloc_func(rgeo_geos_linear_ring_class, alloc_geometry);
  rb_define_alloc_func(rgeo_geos_line_class, alloc_geometry);
  rb_define_alloc_func(rgeo_geos_polygon_class, alloc_geometry);
  rb_define_alloc_func(rgeo_geos_geometry_collection_class, alloc_geometry);
  rb_define_alloc_func(rgeo_geos_multi_point_class, alloc_geometry);
  rb_define_alloc_func(rgeo_geos_multi_line_string_class, alloc_geometry);
  rb_define_alloc_func(rgeo_geos_multi_polygon_class, alloc_geometry);
}

/**** OTHER PUBLIC FUNCTIONS ****/

VALUE
rgeo_wrap_geos_geometry(VALUE factory, GEOSGeometry* geom, VALUE klass)
{
  VALUE result;
  RGeo_FactoryData* factory_data;
  VALUE klasses;
  VALUE inferred_klass;
  char is_collection;
  RGeo_GeometryData* data;

  result = Qnil;
  if (geom || !NIL_P(klass)) {
    factory_data = NIL_P(factory) ? NULL : RGEO_FACTORY_DATA_PTR(factory);

    // We don't allow "empty" points, so replace such objects with
    // an empty collection.
    if (geom && factory) {
      if (GEOSGeomTypeId(geom) == GEOS_POINT &&
          GEOSGetNumCoordinates(geom) == 0) {
        GEOSGeom_destroy(geom);
        geom = GEOSGeom_createCollection(GEOS_GEOMETRYCOLLECTION, NULL, 0);
        klass = rgeo_geos_geometry_collection_class;
      }
    }

    klasses = Qnil;
    if (TYPE(klass) != T_CLASS) {
      inferred_klass = Qnil;
      is_collection = 0;
      switch (GEOSGeomTypeId(geom)) {
        case GEOS_POINT:
          inferred_klass = rgeo_geos_point_class;
          break;
        case GEOS_LINESTRING:
          inferred_klass = rgeo_geos_line_string_class;
          break;
        case GEOS_LINEARRING:
          inferred_klass = rgeo_geos_linear_ring_class;
          break;
        case GEOS_POLYGON:
          inferred_klass = rgeo_geos_polygon_class;
          break;
        case GEOS_MULTIPOINT:
          inferred_klass = rgeo_geos_multi_point_class;
          is_collection = 1;
          break;
        case GEOS_MULTILINESTRING:
          inferred_klass = rgeo_geos_multi_line_string_class;
          is_collection = 1;
          break;
        case GEOS_MULTIPOLYGON:
          inferred_klass = rgeo_geos_multi_polygon_class;
          is_collection = 1;
          break;
        case GEOS_GEOMETRYCOLLECTION:
          inferred_klass = rgeo_geos_geometry_collection_class;
          is_collection = 1;
          break;
        default:
          inferred_klass = rgeo_geos_geometry_class;
          break;
      }
      if (TYPE(klass) == T_ARRAY && is_collection) {
        klasses = klass;
      }
      klass = inferred_klass;
    }
    data = ALLOC(RGeo_GeometryData);
    if (data) {
      if (geom) {
        GEOSSetSRID(geom, factory_data->srid);
      }
      data->geom = geom;
      data->prep =
        factory_data &&
            ((factory_data->flags & RGEO_FACTORYFLAGS_PREPARE_HEURISTIC) != 0)
          ? (GEOSPreparedGeometry*)1
          : NULL;
      data->factory = factory;
      data->klasses = klasses;
      result = TypedData_Wrap_Struct(klass, &rgeo_geometry_type, data);
    }
  }
  return result;
}

VALUE
rgeo_wrap_geos_geometry_clone(VALUE factory,
                              const GEOSGeometry* geom,
                              VALUE klass)
{
  VALUE result;
  GEOSGeometry* clone_geom;

  result = Qnil;
  if (geom) {
    clone_geom = GEOSGeom_clone(geom);
    if (clone_geom) {
      result = rgeo_wrap_geos_geometry(factory, clone_geom, klass);
    }
  }
  return result;
}

const GEOSGeometry*
rgeo_convert_to_geos_geometry(VALUE factory, VALUE obj, VALUE type, int* state)
{
  VALUE object;

  if (NIL_P(type) && RGEO_GEOMETRY_TYPEDDATA_P(obj) &&
      RGEO_GEOMETRY_DATA_PTR(obj)->factory == factory) {
    object = obj;
  } else {
    object =
      rb_funcall(rgeo_feature_module, rb_intern("cast"), 3, obj, factory, type);
  }
  if (NIL_P(object)) {
    rb_protect(
      rb_exc_raise_value,
      rb_exc_new_cstr(rb_eRGeoInvalidGeometry,
                      "Unable to cast the geometry to the GEOS Factory"),
      state);
  }

  if (*state) {
    return NULL;
  }

  if (!rgeo_is_geos_object(object)) {
    rb_protect(rb_exc_raise_value,
               rb_exc_new_cstr(rb_eRGeoError, "Not a GEOS Geometry object."),
               state);
  }

  if (*state) {
    return NULL;
  }

  return RGEO_GEOMETRY_DATA_PTR(object)->geom;
}

GEOSGeometry*
rgeo_convert_to_detached_geos_geometry(VALUE obj,
                                       VALUE factory,
                                       VALUE type,
                                       VALUE* klasses,
                                       int* state)
{
  VALUE object;
  GEOSGeometry* geom;
  RGeo_GeometryData* object_data;
  const GEOSPreparedGeometry* prep;

  if (klasses) {
    *klasses = Qnil;
  }

  object = rb_protect_funcall(rgeo_feature_module,
                              rb_intern("cast"),
                              state,
                              5,
                              obj,
                              factory,
                              type,
                              ID2SYM(rb_intern("force_new")),
                              ID2SYM(rb_intern("keep_subtype")));

  if (NIL_P(object)) {
    rb_protect(
      rb_exc_raise_value,
      rb_exc_new_cstr(rb_eRGeoInvalidGeometry,
                      "Unable to cast the geometry to the GEOS Factory"),
      state);
  }
  if (*state) {
    return NULL;
  }

  if (!rgeo_is_geos_object(object)) {
    rb_protect(rb_exc_raise_value,
               rb_exc_new_cstr(rb_eRGeoError, "Not a GEOS Geometry object."),
               state);
  }
  if (*state) {
    return NULL;
  }

  object_data = RGEO_GEOMETRY_DATA_PTR(object);
  geom = object_data->geom;
  if (klasses) {
    *klasses = object_data->klasses;
    if (NIL_P(*klasses)) {
      *klasses = CLASS_OF(object);
    }
  }
  prep = object_data->prep;
  if (prep && prep != (GEOSPreparedGeometry*)1 &&
      prep != (GEOSPreparedGeometry*)2) {
    GEOSPreparedGeom_destroy(prep);
  }
  object_data->geom = NULL;
  object_data->prep = NULL;
  object_data->factory = Qnil;
  object_data->klasses = Qnil;

  return geom;
}

char
rgeo_is_geos_object(VALUE obj)
{
  return RGEO_GEOMETRY_TYPEDDATA_P(obj) ? 1 : 0;
}

void
rgeo_check_geos_object(VALUE obj)
{
  if (!rgeo_is_geos_object(obj)) {
    rb_raise(rb_eRGeoError, "Not a GEOS Geometry object.");
  }
}

const GEOSGeometry*
rgeo_get_geos_geometry_safe(VALUE obj)
{
  return RGEO_GEOMETRY_TYPEDDATA_P(obj)
           ? (const GEOSGeometry*)(RGEO_GEOMETRY_DATA_PTR(obj)->geom)
           : NULL;
}

VALUE
rgeo_geos_coordseqs_eql(const GEOSGeometry* geom1,
                        const GEOSGeometry* geom2,
                        char check_z)
{
  VALUE result;
  const GEOSCoordSequence* cs1;
  const GEOSCoordSequence* cs2;
  unsigned int len1;
  unsigned int len2;
  unsigned int i;
  double val1, val2;

  result = Qnil;
  if (geom1 && geom2) {
    cs1 = GEOSGeom_getCoordSeq(geom1);
    cs2 = GEOSGeom_getCoordSeq(geom2);
    if (cs1 && cs2) {
      len1 = 0;
      len2 = 0;
      if (GEOSCoordSeq_getSize(cs1, &len1) &&
          GEOSCoordSeq_getSize(cs2, &len2)) {
        if (len1 == len2) {
          result = Qtrue;
          for (i = 0; i < len1; ++i) {
            if (GEOSCoordSeq_getX(cs1, i, &val1) &&
                GEOSCoordSeq_getX(cs2, i, &val2)) {
              if (val1 == val2) {
                if (GEOSCoordSeq_getY(cs1, i, &val1) &&
                    GEOSCoordSeq_getY(cs2, i, &val2)) {
                  if (val1 == val2) {
                    if (check_z) {
                      val1 = 0;
                      if (!GEOSCoordSeq_getZ(cs1, i, &val1)) {
                        result = Qnil;
                        break;
                      }
                      val2 = 0;
                      if (!GEOSCoordSeq_getZ(cs2, i, &val2)) {
                        result = Qnil;
                        break;
                      }
                      if (val1 != val2) {
                        result = Qfalse;
                        break;
                      }
                    }
                  } else { // Y coords are different
                    result = Qfalse;
                    break;
                  }
                } else { // Failed to get Y coords
                  result = Qnil;
                  break;
                }
              } else { // X coords are different
                result = Qfalse;
                break;
              }
            } else { // Failed to get X coords
              result = Qnil;
              break;
            }
          }      // Iteration over coords
        } else { // Lengths are different
          result = Qfalse;
        }
      }
    }
  }
  return result;
}

VALUE
rgeo_geos_klasses_and_factories_eql(VALUE obj1, VALUE obj2)
{
  VALUE result;
  VALUE factory;

  result = Qnil;
  if (rb_obj_class(obj1) != rb_obj_class(obj2)) {
    result = Qfalse;
  } else {
    factory = RGEO_GEOMETRY_DATA_PTR(obj1)->factory;
    /* No need to cache the internal here (https://ips.fastruby.io/4x) */
    result = rb_funcall(
      factory, rb_intern("eql?"), 1, RGEO_GEOMETRY_DATA_PTR(obj2)->factory);
  }
  return result;
}

typedef struct
{
  st_index_t seed_hash;
  double x;
  double y;
  double z;
} RGeo_Coordseq_Hash_Struct;

st_index_t
rgeo_geos_coordseq_hash(const GEOSGeometry* geom, st_index_t hash)
{
  const GEOSCoordSequence* cs;
  unsigned int len;
  unsigned int i;
  RGeo_Coordseq_Hash_Struct hash_struct;

  if (geom) {
    cs = GEOSGeom_getCoordSeq(geom);
    if (cs) {
      if (GEOSCoordSeq_getSize(cs, &len)) {
        for (i = 0; i < len; ++i) {
          if (GEOSCoordSeq_getX(cs, i, &hash_struct.x)) {
            if (GEOSCoordSeq_getY(cs, i, &hash_struct.y)) {
              if (!GEOSCoordSeq_getZ(cs, i, &hash_struct.z)) {
                hash_struct.z = 0;
              }
              hash_struct.seed_hash = hash;
              hash =
                rb_memhash(&hash_struct, sizeof(RGeo_Coordseq_Hash_Struct));
            }
          }
        }
      }
    }
  }
  return hash;
}

typedef struct
{
  st_index_t seed_hash;
  st_index_t h1;
  st_index_t h2;
} RGeo_Objbase_Hash_Struct;

st_index_t
rgeo_geos_objbase_hash(VALUE factory, VALUE type_module, st_index_t hash)
{
  ID hash_method;
  RGeo_Objbase_Hash_Struct hash_struct;

  hash_method = rb_intern("hash");
  hash_struct.seed_hash = hash;
  hash_struct.h1 = FIX2LONG(rb_funcall(factory, hash_method, 0));
  hash_struct.h2 = FIX2LONG(rb_funcall(type_module, hash_method, 0));
  return rb_memhash(&hash_struct, sizeof(RGeo_Objbase_Hash_Struct));
}

RGEO_END_C

#endif
