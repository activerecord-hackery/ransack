/*
  Point methods for GEOS wrapper
*/

#include "preface.h"

#ifdef RGEO_GEOS_SUPPORTED

#include <geos_c.h>
#include <ruby.h>

#include "coordinates.h"
#include "factory.h"
#include "geometry.h"
#include "globals.h"
#include "point.h"

RGEO_BEGIN_C

static VALUE
method_point_geometry_type(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  if (self_data->geom) {
    result = rgeo_feature_point_module;
  }
  return result;
}

static VALUE
method_point_coordinates(VALUE self)
{
  VALUE result = Qnil;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSCoordSequence* coord_sequence;
  int zCoordinate;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;

  if (self_geom) {
    zCoordinate = RGEO_FACTORY_DATA_PTR(self_data->factory)->flags &
                  RGEO_FACTORYFLAGS_SUPPORTS_Z_OR_M;
    coord_sequence = GEOSGeom_getCoordSeq(self_geom);
    if (coord_sequence) {
      result = rb_ary_pop(
        extract_points_from_coordinate_sequence(coord_sequence, zCoordinate));
    }
  }
  return result;
}

static VALUE
method_point_x(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSCoordSequence* coord_seq;
  double val;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    coord_seq = GEOSGeom_getCoordSeq(self_geom);
    if (coord_seq) {
      if (GEOSCoordSeq_getX(coord_seq, 0, &val)) {
        result = rb_float_new(val);
      }
    }
  }
  return result;
}

static VALUE
method_point_y(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSCoordSequence* coord_seq;
  double val;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    coord_seq = GEOSGeom_getCoordSeq(self_geom);
    if (coord_seq) {
      if (GEOSCoordSeq_getY(coord_seq, 0, &val)) {
        result = rb_float_new(val);
      }
    }
  }
  return result;
}

static VALUE
get_3d_point(VALUE self, int flag)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSCoordSequence* coord_seq;
  double val;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    if (RGEO_FACTORY_DATA_PTR(self_data->factory)->flags & flag) {
      coord_seq = GEOSGeom_getCoordSeq(self_geom);
      if (coord_seq) {
        if (GEOSCoordSeq_getZ(coord_seq, 0, &val)) {
          result = rb_float_new(val);
        }
      }
    }
  }
  return result;
}

static VALUE
method_point_z(VALUE self)
{
  return get_3d_point(self, RGEO_FACTORYFLAGS_SUPPORTS_Z);
}

static VALUE
method_point_m(VALUE self)
{
  return get_3d_point(self, RGEO_FACTORYFLAGS_SUPPORTS_M);
}

static VALUE
method_point_eql(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;

  result = rgeo_geos_klasses_and_factories_eql(self, rhs);
  if (RTEST(result)) {
    self_data = RGEO_GEOMETRY_DATA_PTR(self);
    result = rgeo_geos_geometries_strict_eql(self_data->geom,
                                             RGEO_GEOMETRY_DATA_PTR(rhs)->geom);
  }
  return result;
}

static VALUE
method_point_hash(VALUE self)
{
  st_index_t hash;
  RGeo_GeometryData* self_data;
  VALUE factory;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  factory = self_data->factory;
  hash = rb_hash_start(0);
  hash = rgeo_geos_objbase_hash(factory, rgeo_feature_point_module, hash);
  hash = rgeo_geos_coordseq_hash(self_data->geom, hash);
  return LONG2FIX(rb_hash_end(hash));
}

static VALUE
cmethod_create(VALUE module, VALUE factory, VALUE x, VALUE y, VALUE z)
{
  return rgeo_create_geos_point(factory,
                                rb_num2dbl(x),
                                rb_num2dbl(y),
                                RGEO_FACTORY_DATA_PTR(factory)->flags &
                                    RGEO_FACTORYFLAGS_SUPPORTS_Z_OR_M
                                  ? rb_num2dbl(z)
                                  : 0);
}

void
rgeo_init_geos_point()
{
  VALUE geos_point_methods;

  // Class methods for CAPIPointImpl
  rb_define_module_function(rgeo_geos_point_class, "create", cmethod_create, 4);

  // CAPIPointMethods module
  geos_point_methods =
    rb_define_module_under(rgeo_geos_module, "CAPIPointMethods");
  rb_define_method(geos_point_methods, "rep_equals?", method_point_eql, 1);
  rb_define_method(geos_point_methods, "eql?", method_point_eql, 1);
  rb_define_method(geos_point_methods, "hash", method_point_hash, 0);
  rb_define_method(
    geos_point_methods, "geometry_type", method_point_geometry_type, 0);
  rb_define_method(geos_point_methods, "x", method_point_x, 0);
  rb_define_method(geos_point_methods, "y", method_point_y, 0);
  rb_define_method(geos_point_methods, "z", method_point_z, 0);
  rb_define_method(geos_point_methods, "m", method_point_m, 0);
  rb_define_method(
    geos_point_methods, "coordinates", method_point_coordinates, 0);
}

VALUE
rgeo_create_geos_point(VALUE factory, double x, double y, double z)
{
  VALUE result;
  GEOSCoordSequence* coord_seq;
  GEOSGeometry* geom;

  result = Qnil;
  coord_seq = GEOSCoordSeq_create(1, 3);
  if (coord_seq) {
    if (GEOSCoordSeq_setX(coord_seq, 0, x)) {
      if (GEOSCoordSeq_setY(coord_seq, 0, y)) {
        if (GEOSCoordSeq_setZ(coord_seq, 0, z)) {
          geom = GEOSGeom_createPoint(coord_seq);
          if (geom) {
            result =
              rgeo_wrap_geos_geometry(factory, geom, rgeo_geos_point_class);
          }
        }
      }
    }
  }
  return result;
}

RGEO_END_C

#endif
