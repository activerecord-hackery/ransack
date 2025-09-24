/*
  Geometry collection methods for GEOS wrapper
*/

#include "preface.h"

#ifdef RGEO_GEOS_SUPPORTED

#include <geos_c.h>
#include <ruby.h>

#include "coordinates.h"
#include "errors.h"
#include "factory.h"
#include "geometry.h"
#include "geometry_collection.h"
#include "globals.h"
#include "line_string.h"
#include "polygon.h"

RGEO_BEGIN_C

/**** INTERNAL IMPLEMENTATION OF CREATE ****/

// Main implementation of the "create" class method for geometry collections.
// You must pass in the correct GEOS geometry type ID.

static VALUE
create_geometry_collection(VALUE module, int type, VALUE factory, VALUE array)
{
  VALUE result;
  unsigned int len;
  GEOSGeometry** geoms;
  VALUE klass;
  unsigned int i;
  unsigned int j;
  VALUE klasses;
  VALUE cast_type;
  GEOSGeometry* geom;
  GEOSGeometry* collection;
  int state = 0;

  result = Qnil;
  Check_Type(array, T_ARRAY);
  len = (unsigned int)RARRAY_LEN(array);
  geoms = ALLOC_N(GEOSGeometry*, len == 0 ? 1 : len);
  if (!geoms) {
    rb_raise(rb_eRGeoError, "not enough memory available");
  }

  klasses = Qnil;
  cast_type = Qnil;
  switch (type) {
    case GEOS_MULTIPOINT:
      cast_type = rgeo_feature_point_module;
      break;
    case GEOS_MULTILINESTRING:
      cast_type = rgeo_feature_line_string_module;
      break;
    case GEOS_MULTIPOLYGON:
      cast_type = rgeo_feature_polygon_module;
      break;
  }
  for (i = 0; i < len; ++i) {
    geom = rgeo_convert_to_detached_geos_geometry(
      rb_ary_entry(array, i), factory, cast_type, &klass, &state);
    if (state) {
      for (j = 0; j < i; j++) {
        GEOSGeom_destroy(geoms[j]);
      }
      FREE(geoms);
      rb_jump_tag(state);
    }

    geoms[i] = geom;
    if (!NIL_P(klass) && NIL_P(klasses)) {
      klasses = rb_ary_new2(len);
      for (j = 0; j < i; ++j) {
        rb_ary_push(klasses, Qnil);
      }
    }
    if (!NIL_P(klasses)) {
      rb_ary_push(klasses, klass);
    }
  }
  collection = GEOSGeom_createCollection(type, geoms, len);
  if (collection) {
    result = rgeo_wrap_geos_geometry(factory, collection, module);
    RGEO_GEOMETRY_DATA_PTR(result)->klasses = klasses;
  }

  // NOTE: We are assuming that GEOS will do its own cleanup of the
  // element geometries if it fails to create the collection, so we
  // are not doing that ourselves. If that turns out not to be the
  // case, this will be a memory leak.
  FREE(geoms);
  if (state) {
    rb_jump_tag(state);
  }

  return result;
}

/**** RUBY METHOD DEFINITIONS ****/

static VALUE
method_geometry_collection_eql(VALUE self, VALUE rhs)
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
method_geometry_collection_hash(VALUE self)
{
  st_index_t hash;
  RGeo_GeometryData* self_data;
  VALUE factory;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  factory = self_data->factory;
  hash = rb_hash_start(0);
  hash = rgeo_geos_objbase_hash(
    factory, rgeo_feature_geometry_collection_module, hash);
  hash = rgeo_geos_geometry_collection_hash(self_data->geom, hash);
  return LONG2FIX(rb_hash_end(hash));
}

static VALUE
method_geometry_collection_geometry_type(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  if (self_data->geom) {
    result = rgeo_feature_geometry_collection_module;
  }
  return result;
}

static VALUE
method_geometry_collection_num_geometries(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    result = INT2NUM(GEOSGetNumGeometries(self_geom));
  }
  return result;
}

static VALUE
impl_geometry_n(VALUE self, VALUE n, char allow_negatives)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  VALUE klasses;
  int i;
  int len;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    klasses = self_data->klasses;
    i = RB_NUM2INT(n);
    if (allow_negatives || i >= 0) {
      len = GEOSGetNumGeometries(self_geom);
      if (i < 0) {
        i += len;
      }
      if (i >= 0 && i < len) {
        result = rgeo_wrap_geos_geometry_clone(
          self_data->factory,
          GEOSGetGeometryN(self_geom, i),
          NIL_P(klasses) ? Qnil : rb_ary_entry(klasses, i));
      }
    }
  }
  return result;
}

static VALUE
method_geometry_collection_geometry_n(VALUE self, VALUE n)
{
  return impl_geometry_n(self, n, 0);
}

static VALUE
method_geometry_collection_brackets(VALUE self, VALUE n)
{
  return impl_geometry_n(self, n, 1);
}

static VALUE
method_geometry_collection_each(VALUE self)
{
  RETURN_ENUMERATOR(
    self, 0, 0); /* return enum_for(__callee__) unless block_given? */

  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  int len;
  VALUE klasses;
  int i;
  VALUE elem;
  const GEOSGeometry* elem_geom;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);

  self_geom = self_data->geom;
  if (self_geom) {
    len = GEOSGetNumGeometries(self_geom);
    if (len > 0) {
      klasses = self_data->klasses;
      for (i = 0; i < len; ++i) {
        elem_geom = GEOSGetGeometryN(self_geom, i);
        elem = rgeo_wrap_geos_geometry_clone(
          self_data->factory,
          elem_geom,
          NIL_P(klasses) ? Qnil : rb_ary_entry(klasses, i));
        if (!NIL_P(elem)) {
          rb_yield(elem);
        }
      }
    }
  }
  return self;
}

static VALUE
method_multi_point_geometry_type(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  if (self_data->geom) {
    result = rgeo_feature_multi_point_module;
  }
  return result;
}

static VALUE
method_multi_point_hash(VALUE self)
{
  st_index_t hash;
  RGeo_GeometryData* self_data;
  VALUE factory;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  factory = self_data->factory;
  hash = rb_hash_start(0);
  hash = rgeo_geos_objbase_hash(factory, rgeo_feature_multi_point_module, hash);
  hash = rgeo_geos_geometry_collection_hash(self_data->geom, hash);
  return LONG2FIX(rb_hash_end(hash));
}

static VALUE
method_multi_point_coordinates(VALUE self)
{
  VALUE result = Qnil;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSCoordSequence* coord_sequence;

  const GEOSGeometry* point;
  unsigned int count;
  unsigned int i;
  int zCoordinate;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;

  if (self_geom) {
    zCoordinate = RGEO_FACTORY_DATA_PTR(self_data->factory)->flags &
                  RGEO_FACTORYFLAGS_SUPPORTS_Z_OR_M;

    count = GEOSGetNumGeometries(self_geom);
    result = rb_ary_new2(count);
    for (i = 0; i < count; ++i) {
      point = GEOSGetGeometryN(self_geom, i);
      coord_sequence = GEOSGeom_getCoordSeq(point);
      rb_ary_push(result,
                  rb_ary_pop(extract_points_from_coordinate_sequence(
                    coord_sequence, zCoordinate)));
    }
  }

  return result;
}

static VALUE
method_multi_line_string_geometry_type(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  if (self_data->geom) {
    result = rgeo_feature_multi_line_string_module;
  }
  return result;
}

static VALUE
method_multi_line_string_hash(VALUE self)
{
  st_index_t hash;
  RGeo_GeometryData* self_data;
  VALUE factory;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  factory = self_data->factory;
  hash = rb_hash_start(0);
  hash = rgeo_geos_objbase_hash(
    factory, rgeo_feature_multi_line_string_module, hash);
  hash = rgeo_geos_geometry_collection_hash(self_data->geom, hash);
  return LONG2FIX(rb_hash_end(hash));
}

static VALUE
method_geometry_collection_node(VALUE self)
{
  VALUE result = Qnil;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  GEOSGeometry* noded;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;

  noded = GEOSNode(self_geom);
  result = rgeo_wrap_geos_geometry(self_data->factory, noded, Qnil);

  return result;
}

static VALUE
method_multi_line_string_coordinates(VALUE self)
{
  VALUE result = Qnil;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSCoordSequence* coord_sequence;

  const GEOSGeometry* line_string;
  unsigned int count;
  unsigned int i;
  int zCoordinate;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;

  if (self_geom) {
    zCoordinate = RGEO_FACTORY_DATA_PTR(self_data->factory)->flags &
                  RGEO_FACTORYFLAGS_SUPPORTS_Z_OR_M;
    count = GEOSGetNumGeometries(self_geom);
    result = rb_ary_new2(count);
    for (i = 0; i < count; ++i) {
      line_string = GEOSGetGeometryN(self_geom, i);
      coord_sequence = GEOSGeom_getCoordSeq(line_string);
      rb_ary_push(
        result,
        extract_points_from_coordinate_sequence(coord_sequence, zCoordinate));
    }
  }

  return result;
}

static VALUE
method_multi_line_string_length(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  double len;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    if (GEOSLength(self_geom, &len)) {
      result = rb_float_new(len);
    }
  }
  return result;
}

static VALUE
method_multi_line_string_is_closed(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  int len;
  int i;
  const GEOSGeometry* geom;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    result = Qtrue;
    len = GEOSGetNumGeometries(self_geom);
    if (len > 0) {
      for (i = 0; i < len; ++i) {
        geom = GEOSGetGeometryN(self_geom, i);
        if (geom) {
          result = rgeo_is_geos_line_string_closed(self_geom);
          if (result != Qtrue) {
            break;
          }
        }
      }
    }
  }
  return result;
}

static VALUE
method_multi_polygon_geometry_type(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  if (self_data->geom) {
    result = rgeo_feature_multi_polygon_module;
  }
  return result;
}

static VALUE
method_multi_polygon_hash(VALUE self)
{
  st_index_t hash;
  RGeo_GeometryData* self_data;
  VALUE factory;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  factory = self_data->factory;
  hash = rb_hash_start(0);
  hash =
    rgeo_geos_objbase_hash(factory, rgeo_feature_multi_polygon_module, hash);
  hash = rgeo_geos_geometry_collection_hash(self_data->geom, hash);
  return LONG2FIX(rb_hash_end(hash));
}

static VALUE
method_multi_polygon_coordinates(VALUE self)
{
  VALUE result = Qnil;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;

  const GEOSGeometry* poly;
  unsigned int count;
  unsigned int i;
  int zCoordinate;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;

  if (self_geom) {
    zCoordinate = RGEO_FACTORY_DATA_PTR(self_data->factory)->flags &
                  RGEO_FACTORYFLAGS_SUPPORTS_Z_OR_M;
    count = GEOSGetNumGeometries(self_geom);
    result = rb_ary_new2(count);
    for (i = 0; i < count; ++i) {
      poly = GEOSGetGeometryN(self_geom, i);
      rb_ary_push(result, extract_points_from_polygon(poly, zCoordinate));
    }
  }

  return result;
}

static VALUE
method_multi_polygon_area(VALUE self)
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
method_multi_polygon_centroid(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    result = rgeo_wrap_geos_geometry(
      self_data->factory, GEOSGetCentroid(self_geom), Qnil);
  }
  return result;
}

static VALUE
cmethod_geometry_collection_create(VALUE module, VALUE factory, VALUE array)
{
  return create_geometry_collection(
    module, GEOS_GEOMETRYCOLLECTION, factory, array);
}

static VALUE
cmethod_multi_point_create(VALUE module, VALUE factory, VALUE array)
{
  return create_geometry_collection(module, GEOS_MULTIPOINT, factory, array);
}

static VALUE
cmethod_multi_line_string_create(VALUE module, VALUE factory, VALUE array)
{
  return create_geometry_collection(
    module, GEOS_MULTILINESTRING, factory, array);
}

static VALUE
cmethod_multi_polygon_create(VALUE module, VALUE factory, VALUE array)
{
  return create_geometry_collection(module, GEOS_MULTIPOLYGON, factory, array);
}

/**** INITIALIZATION FUNCTION ****/

void
rgeo_init_geos_geometry_collection()
{
  VALUE geos_geometry_collection_methods;
  VALUE geos_multi_point_methods;
  VALUE geos_multi_line_string_methods;
  VALUE geos_multi_polygon_methods;

  // Class methods for geometry collection classes
  rb_define_module_function(rgeo_geos_geometry_collection_class,
                            "create",
                            cmethod_geometry_collection_create,
                            2);
  rb_define_module_function(
    rgeo_geos_multi_point_class, "create", cmethod_multi_point_create, 2);
  rb_define_module_function(rgeo_geos_multi_line_string_class,
                            "create",
                            cmethod_multi_line_string_create,
                            2);
  rb_define_module_function(
    rgeo_geos_multi_polygon_class, "create", cmethod_multi_polygon_create, 2);

  // Methods for GeometryCollectionImpl
  geos_geometry_collection_methods =
    rb_define_module_under(rgeo_geos_module, "CAPIGeometryCollectionMethods");
  rb_define_method(geos_geometry_collection_methods,
                   "rep_equals?",
                   method_geometry_collection_eql,
                   1);
  rb_define_method(geos_geometry_collection_methods,
                   "eql?",
                   method_geometry_collection_eql,
                   1);
  rb_define_method(geos_geometry_collection_methods,
                   "hash",
                   method_geometry_collection_hash,
                   0);
  rb_define_method(geos_geometry_collection_methods,
                   "geometry_type",
                   method_geometry_collection_geometry_type,
                   0);
  rb_define_method(geos_geometry_collection_methods,
                   "num_geometries",
                   method_geometry_collection_num_geometries,
                   0);
  rb_define_method(geos_geometry_collection_methods,
                   "size",
                   method_geometry_collection_num_geometries,
                   0);
  rb_define_method(geos_geometry_collection_methods,
                   "geometry_n",
                   method_geometry_collection_geometry_n,
                   1);
  rb_define_method(geos_geometry_collection_methods,
                   "[]",
                   method_geometry_collection_brackets,
                   1);
  rb_define_method(geos_geometry_collection_methods,
                   "each",
                   method_geometry_collection_each,
                   0);
  rb_define_method(geos_geometry_collection_methods,
                   "node",
                   method_geometry_collection_node,
                   0);

  // Methods for MultiPointImpl
  geos_multi_point_methods =
    rb_define_module_under(rgeo_geos_module, "CAPIMultiPointMethods");
  rb_define_method(geos_multi_point_methods,
                   "geometry_type",
                   method_multi_point_geometry_type,
                   0);
  rb_define_method(
    geos_multi_point_methods, "hash", method_multi_point_hash, 0);
  rb_define_method(
    geos_multi_point_methods, "coordinates", method_multi_point_coordinates, 0);

  // Methods for MultiLineStringImpl
  geos_multi_line_string_methods =
    rb_define_module_under(rgeo_geos_module, "CAPIMultiLineStringMethods");
  rb_define_method(geos_multi_line_string_methods,
                   "geometry_type",
                   method_multi_line_string_geometry_type,
                   0);
  rb_define_method(geos_multi_line_string_methods,
                   "length",
                   method_multi_line_string_length,
                   0);
  rb_define_method(geos_multi_line_string_methods,
                   "closed?",
                   method_multi_line_string_is_closed,
                   0);
  rb_define_method(
    geos_multi_line_string_methods, "hash", method_multi_line_string_hash, 0);
  rb_define_method(geos_multi_line_string_methods,
                   "coordinates",
                   method_multi_line_string_coordinates,
                   0);

  // Methods for MultiPolygonImpl
  geos_multi_polygon_methods =
    rb_define_module_under(rgeo_geos_module, "CAPIMultiPolygonMethods");
  rb_define_method(geos_multi_polygon_methods,
                   "geometry_type",
                   method_multi_polygon_geometry_type,
                   0);
  rb_define_method(
    geos_multi_polygon_methods, "area", method_multi_polygon_area, 0);
  rb_define_method(
    geos_multi_polygon_methods, "centroid", method_multi_polygon_centroid, 0);
  rb_define_method(
    geos_multi_polygon_methods, "hash", method_multi_polygon_hash, 0);
  rb_define_method(geos_multi_polygon_methods,
                   "coordinates",
                   method_multi_polygon_coordinates,
                   0);
}

/**** OTHER PUBLIC FUNCTIONS ****/

st_index_t
rgeo_geos_geometry_collection_hash(const GEOSGeometry* geom, st_index_t hash)
{
  const GEOSGeometry* sub_geom;
  int type;
  unsigned int len;
  unsigned int i;

  if (geom) {
    len = GEOSGetNumGeometries(geom);
    for (i = 0; i < len; ++i) {
      sub_geom = GEOSGetGeometryN(geom, i);
      if (sub_geom) {
        type = GEOSGeomTypeId(sub_geom);
        if (type >= 0) {
          hash = hash ^ type;
          switch (type) {
            case GEOS_POINT:
            case GEOS_LINESTRING:
            case GEOS_LINEARRING:
              hash = rgeo_geos_coordseq_hash(sub_geom, hash);
              break;
            case GEOS_POLYGON:
              hash = rgeo_geos_polygon_hash(sub_geom, hash);
              break;
            case GEOS_GEOMETRYCOLLECTION:
            case GEOS_MULTIPOINT:
            case GEOS_MULTILINESTRING:
            case GEOS_MULTIPOLYGON:
              hash = rgeo_geos_geometry_collection_hash(sub_geom, hash);
              break;
          }
        }
      }
    }
  }
  return hash;
}

RGEO_END_C

#endif
