/*
  Polygon methods for GEOS wrapper
*/

#include "preface.h"

#ifdef RGEO_GEOS_SUPPORTED

#include <geos_c.h>
#include <ruby.h>

#include "coordinates.h"
#include "factory.h"
#include "geometry.h"
#include "globals.h"
#include "line_string.h"
#include "polygon.h"

RGEO_BEGIN_C

static VALUE
method_polygon_eql(VALUE self, VALUE rhs)
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
method_polygon_hash(VALUE self)
{
  st_index_t hash;
  RGeo_GeometryData* self_data;
  VALUE factory;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  factory = self_data->factory;
  hash = rb_hash_start(0);
  hash = rgeo_geos_objbase_hash(factory, rgeo_feature_polygon_module, hash);
  hash = rgeo_geos_polygon_hash(self_data->geom, hash);
  return LONG2FIX(rb_hash_end(hash));
}

static VALUE
method_polygon_geometry_type(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  if (self_data->geom) {
    result = rgeo_feature_polygon_module;
  }
  return result;
}

static VALUE
method_polygon_area(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  double area;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    if (GEOSArea(self_geom, &area)) {
      result = rb_float_new(area);
    }
  }
  return result;
}

static VALUE
method_polygon_centroid(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    result = rgeo_wrap_geos_geometry(
      self_data->factory, GEOSGetCentroid(self_geom), rgeo_geos_point_class);
  }
  return result;
}

static VALUE
method_polygon_point_on_surface(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    result = rgeo_wrap_geos_geometry(
      self_data->factory, GEOSPointOnSurface(self_geom), rgeo_geos_point_class);
  }
  return result;
}

static VALUE
method_polygon_coordinates(VALUE self)
{
  VALUE result = Qnil;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;

  int zCoordinate;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;

  if (self_geom) {
    zCoordinate = RGEO_FACTORY_DATA_PTR(self_data->factory)->flags &
                  RGEO_FACTORYFLAGS_SUPPORTS_Z_OR_M;
    result = extract_points_from_polygon(self_geom, zCoordinate);
  }
  return result;
}

static VALUE
method_polygon_exterior_ring(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    result = rgeo_wrap_geos_geometry_clone(self_data->factory,
                                           GEOSGetExteriorRing(self_geom),
                                           rgeo_geos_linear_ring_class);
  }
  return result;
}

static VALUE
method_polygon_num_interior_rings(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  int num;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    num = GEOSGetNumInteriorRings(self_geom);
    if (num >= 0) {
      result = INT2NUM(num);
    }
  }
  return result;
}

static VALUE
method_polygon_interior_ring_n(VALUE self, VALUE n)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  int i;
  int num;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    i = RB_NUM2INT(n);
    if (i >= 0) {
      num = GEOSGetNumInteriorRings(self_geom);
      if (i < num) {
        result =
          rgeo_wrap_geos_geometry_clone(self_data->factory,
                                        GEOSGetInteriorRingN(self_geom, i),
                                        rgeo_geos_linear_ring_class);
      }
    }
  }
  return result;
}

static VALUE
method_polygon_interior_rings(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  int count;
  VALUE factory;
  int i;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    count = GEOSGetNumInteriorRings(self_geom);
    if (count >= 0) {
      result = rb_ary_new2(count);
      factory = self_data->factory;
      for (i = 0; i < count; ++i) {
        rb_ary_store(
          result,
          i,
          rgeo_wrap_geos_geometry_clone(factory,
                                        GEOSGetInteriorRingN(self_geom, i),
                                        rgeo_geos_linear_ring_class));
      }
    }
  }
  return result;
}

static VALUE
cmethod_create(VALUE module,
               VALUE factory,
               VALUE exterior,
               VALUE interior_array)
{
  VALUE linear_ring_type;
  GEOSGeometry* exterior_geom;
  unsigned int len;
  GEOSGeometry** interior_geoms;
  unsigned int actual_len;
  unsigned int i;
  unsigned int j;
  GEOSGeometry* interior_geom;
  GEOSGeometry* polygon;
  int state = 0;

  Check_Type(interior_array, T_ARRAY);
  linear_ring_type = rgeo_feature_linear_ring_module;
  exterior_geom = rgeo_convert_to_detached_geos_geometry(
    exterior, factory, linear_ring_type, NULL, &state);
  if (state) {
    rb_jump_tag(state);
  }

  len = (unsigned int)RARRAY_LEN(interior_array);
  interior_geoms = ALLOC_N(GEOSGeometry*, len == 0 ? 1 : len);
  if (interior_geoms) {
    actual_len = 0;
    for (i = 0; i < len; ++i) {
      interior_geom =
        rgeo_convert_to_detached_geos_geometry(rb_ary_entry(interior_array, i),
                                               factory,
                                               linear_ring_type,
                                               NULL,
                                               &state);
      if (state) {
        for (j = 0; j < i; j++) {
          GEOSGeom_destroy(interior_geoms[j]);
        }
        GEOSGeom_destroy(exterior_geom);
        FREE(interior_geoms);
        rb_jump_tag(state);
      }
      interior_geoms[actual_len++] = interior_geom;
    }
    if (len == actual_len) {
      polygon =
        GEOSGeom_createPolygon(exterior_geom, interior_geoms, actual_len);
      if (polygon) {
        FREE(interior_geoms);
        // NOTE: we can return safely here, state cannot be other than 0.
        return rgeo_wrap_geos_geometry(
          factory, polygon, rgeo_geos_polygon_class);
      }
    }
    for (i = 0; i < actual_len; ++i) {
      GEOSGeom_destroy(interior_geoms[i]);
    }
    FREE(interior_geoms);
  }
  GEOSGeom_destroy(exterior_geom);
  if (state) {
    rb_jump_tag(state);
  }
  return Qnil;
}

void
rgeo_init_geos_polygon()
{
  VALUE geos_polygon_methods;

  // Class methods for CAPIPolygonImpl
  rb_define_module_function(
    rgeo_geos_polygon_class, "create", cmethod_create, 3);

  // CAPIPolygonMethods module
  geos_polygon_methods =
    rb_define_module_under(rgeo_geos_module, "CAPIPolygonMethods");
  rb_define_method(geos_polygon_methods, "rep_equals?", method_polygon_eql, 1);
  rb_define_method(geos_polygon_methods, "eql?", method_polygon_eql, 1);
  rb_define_method(geos_polygon_methods, "hash", method_polygon_hash, 0);
  rb_define_method(
    geos_polygon_methods, "geometry_type", method_polygon_geometry_type, 0);
  rb_define_method(geos_polygon_methods, "area", method_polygon_area, 0);
  rb_define_method(
    geos_polygon_methods, "centroid", method_polygon_centroid, 0);
  rb_define_method(geos_polygon_methods,
                   "point_on_surface",
                   method_polygon_point_on_surface,
                   0);
  rb_define_method(
    geos_polygon_methods, "exterior_ring", method_polygon_exterior_ring, 0);
  rb_define_method(geos_polygon_methods,
                   "num_interior_rings",
                   method_polygon_num_interior_rings,
                   0);
  rb_define_method(
    geos_polygon_methods, "interior_ring_n", method_polygon_interior_ring_n, 1);
  rb_define_method(
    geos_polygon_methods, "interior_rings", method_polygon_interior_rings, 0);
  rb_define_method(
    geos_polygon_methods, "coordinates", method_polygon_coordinates, 0);
}

st_index_t
rgeo_geos_polygon_hash(const GEOSGeometry* geom, st_index_t hash)
{
  unsigned int len;
  unsigned int i;

  if (geom) {
    hash = rgeo_geos_coordseq_hash(GEOSGetExteriorRing(geom), hash);
    len = GEOSGetNumInteriorRings(geom);
    for (i = 0; i < len; ++i) {
      hash = rgeo_geos_coordseq_hash(GEOSGetInteriorRingN(geom, i), hash);
    }
  }
  return hash;
}

RGEO_END_C

#endif
