/*
  Geometry base class methods for GEOS wrapper
*/

#include "preface.h"

#ifdef RGEO_GEOS_SUPPORTED

#include <geos_c.h>
#include <ruby.h>
#include <string.h>

#include "errors.h"
#include "factory.h"
#include "geometry.h"
#include "globals.h"

RGEO_BEGIN_C

/**** INTERNAL UTILITY FUNCTIONS ****/

// Determine the dimension of the given geometry. Empty collections have
// dimension -1. Recursively checks collection elemenets.

static int
compute_dimension(const GEOSGeometry* geom)
{
  int result;
  int size;
  int i;
  int dim;

  result = -1;
  if (geom) {
    switch (GEOSGeomTypeId(geom)) {
      case GEOS_POINT:
        result = 0;
        break;
      case GEOS_MULTIPOINT:
        if (!GEOSisEmpty(geom)) {
          result = 0;
        }
        break;
      case GEOS_LINESTRING:
      case GEOS_LINEARRING:
        result = 1;
        break;
      case GEOS_MULTILINESTRING:
        if (!GEOSisEmpty(geom)) {
          result = 1;
        }
        break;
      case GEOS_POLYGON:
        result = 2;
        break;
      case GEOS_MULTIPOLYGON:
        if (!GEOSisEmpty(geom)) {
          result = 2;
        }
        break;
      case GEOS_GEOMETRYCOLLECTION:
        size = GEOSGetNumGeometries(geom);
        for (i = 0; i < size; ++i) {
          dim = compute_dimension(GEOSGetGeometryN(geom, i));
          if (dim > result) {
            result = dim;
          }
        }
        break;
    }
  }
  return result;
}

// Returns a prepared geometry, honoring the preparation policy.

static const GEOSPreparedGeometry*
rgeo_request_prepared_geometry(RGeo_GeometryData* object_data)
{
  const GEOSPreparedGeometry* prep;

  prep = object_data->prep;
  if (prep == (const GEOSPreparedGeometry*)1) {
    object_data->prep = (GEOSPreparedGeometry*)2;
    prep = NULL;
  } else if (prep == (const GEOSPreparedGeometry*)2) {
    if (object_data->geom) {
      prep = GEOSPrepare(object_data->geom);
    } else {
      prep = NULL;
    }
    if (prep) {
      object_data->prep = prep;
    } else {
      object_data->prep = (const GEOSPreparedGeometry*)3;
    }
  } else if (prep == (const GEOSPreparedGeometry*)3) {
    prep = NULL;
  }
  return prep;
}

/**** RUBY METHOD DEFINITIONS ****/

static VALUE
method_geometry_initialized_p(VALUE self)
{
  return RGEO_GEOMETRY_DATA_PTR(self)->geom ? Qtrue : Qfalse;
}

static VALUE
method_geometry_factory(VALUE self)
{
  return RGEO_GEOMETRY_DATA_PTR(self)->factory;
}

static VALUE
method_geometry_set_factory(VALUE self, VALUE factory)
{
  RGEO_GEOMETRY_DATA_PTR(self)->factory = factory;
  return factory;
}

static VALUE
method_geometry_prepared_p(VALUE self)
{
  const GEOSPreparedGeometry* prep;

  prep = RGEO_GEOMETRY_DATA_PTR(self)->prep;
  return (prep && prep != (const GEOSPreparedGeometry*)1 &&
          prep != (const GEOSPreparedGeometry*)2 &&
          prep != (GEOSPreparedGeometry*)3)
           ? Qtrue
           : Qfalse;
}

static VALUE
method_geometry_prepare(VALUE self)
{
  RGeo_GeometryData* self_data;
  const GEOSPreparedGeometry* prep;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  if (self_data->geom) {
    prep = self_data->prep;
    if (!prep || prep == (const GEOSPreparedGeometry*)1 ||
        prep == (const GEOSPreparedGeometry*)2) {
      prep = GEOSPrepare(self_data->geom);
      if (prep) {
        self_data->prep = prep;
      } else {
        self_data->prep = (const GEOSPreparedGeometry*)3;
      }
    }
  }
  return self;
}

static VALUE
method_geometry_dimension(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    result = INT2NUM(compute_dimension(self_geom));
  }
  return result;
}

static VALUE
method_geometry_geometry_type(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  if (self_data->geom) {
    result = rgeo_feature_geometry_module;
  }
  return result;
}

static VALUE
method_geometry_srid(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    result = INT2NUM(GEOSGetSRID(self_geom));
  }
  return result;
}

static VALUE
method_geometry_envelope(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  GEOSGeometry* envelope;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    envelope = GEOSEnvelope(self_geom);
    if (!envelope) {
      envelope = GEOSGeom_createCollection(GEOS_GEOMETRYCOLLECTION, NULL, 0);
    }
    result = rgeo_wrap_geos_geometry(self_data->factory, envelope, Qnil);
  }
  return result;
}

static VALUE
method_geometry_boundary(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  GEOSGeometry* boundary;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    boundary = GEOSBoundary(self_geom);
    if (boundary) {
      result = rgeo_wrap_geos_geometry(self_data->factory, boundary, Qnil);
    }
  }
  return result;
}

static VALUE
method_geometry_as_text(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  RGeo_FactoryData* factory_data;
  VALUE wkt_generator;
  GEOSWKTWriter* wkt_writer;
  char* str;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    factory_data = RGEO_FACTORY_DATA_PTR(self_data->factory);
    wkt_generator = factory_data->wkrep_wkt_generator;
    if (!NIL_P(wkt_generator)) {
      result = rb_funcall(wkt_generator, rb_intern("generate"), 1, self);
    } else {
      wkt_writer = factory_data->wkt_writer;
      if (!wkt_writer) {
        wkt_writer = GEOSWKTWriter_create();
        GEOSWKTWriter_setOutputDimension(wkt_writer, 2);
        GEOSWKTWriter_setTrim(wkt_writer, 1);
        factory_data->wkt_writer = wkt_writer;
      }
      str = GEOSWKTWriter_write(wkt_writer, self_geom);
      if (str) {
        result = rb_str_new2(str);
        GEOSFree(str);
      }
    }
  }
  return result;
}

static VALUE
method_geometry_as_binary(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  RGeo_FactoryData* factory_data;
  VALUE wkb_generator;
  GEOSWKBWriter* wkb_writer;
  size_t size;
  char* str;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    factory_data = RGEO_FACTORY_DATA_PTR(self_data->factory);
    wkb_generator = factory_data->wkrep_wkb_generator;
    if (!NIL_P(wkb_generator)) {
      result = rb_funcall(wkb_generator, rb_intern("generate"), 1, self);
    } else {
      wkb_writer = factory_data->wkb_writer;

      if (!wkb_writer) {
        wkb_writer = GEOSWKBWriter_create();
        GEOSWKBWriter_setOutputDimension(wkb_writer, 2);
        factory_data->wkb_writer = wkb_writer;
      }
      str = (char*)GEOSWKBWriter_write(wkb_writer, self_geom, &size);
      if (str) {
        result = rb_str_new(str, size);
        GEOSFree(str);
      }
    }
  }
  return result;
}

static VALUE
method_geometry_is_empty(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  char val;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    val = GEOSisEmpty(self_geom);
    if (val == 0) {
      result = Qfalse;
    } else if (val == 1) {
      result = Qtrue;
    }
  }
  return result;
}

static VALUE
method_geometry_is_simple(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  char val;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    val = GEOSisSimple(self_geom);
    if (val == 0) {
      result = Qfalse;
    } else if (val == 1) {
      result = Qtrue;
    }
  }
  return result;
}

static VALUE
method_geometry_equals(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSGeometry* rhs_geom;

  // Shortcut when self and rhs are the same object.
  if (self == rhs) {
    return Qtrue;
  }

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    rhs_geom = rgeo_get_geos_geometry_safe(rhs);
    if (rhs_geom) {
      // GEOS has a bug where empty geometries are not spatially equal
      // to each other. Work around this case first.
      if (GEOSisEmpty(self_geom) == 1 && GEOSisEmpty(rhs_geom) == 1) {
        result = Qtrue;
      } else {
        result = GEOSEquals(self_geom, rhs_geom) ? Qtrue : Qfalse;
      }
    }
  }
  return result;
}

static VALUE
method_geometry_eql(VALUE self, VALUE rhs)
{
  // This should be overridden by the subclass.
  return self == rhs ? Qtrue : Qfalse;
}

static VALUE
method_geometry_disjoint(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSGeometry* rhs_geom;
  int state = 0;
#ifdef RGEO_GEOS_SUPPORTS_PREPARED2
  const GEOSPreparedGeometry* prep;
#endif

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    rhs_geom =
      rgeo_convert_to_geos_geometry(self_data->factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }
#ifdef RGEO_GEOS_SUPPORTS_PREPARED2
    prep = rgeo_request_prepared_geometry(self_data);
    if (prep)
      result = GEOSPreparedDisjoint(prep, rhs_geom) ? Qtrue : Qfalse;
    else
#endif
      result = GEOSDisjoint(self_geom, rhs_geom) ? Qtrue : Qfalse;
  }
  return result;
}

static VALUE
method_geometry_intersects(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSGeometry* rhs_geom;
  char val;
  int state = 0;
#ifdef RGEO_GEOS_SUPPORTS_PREPARED1
  const GEOSPreparedGeometry* prep;
#endif

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    rhs_geom =
      rgeo_convert_to_geos_geometry(self_data->factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }
#ifdef RGEO_GEOS_SUPPORTS_PREPARED1
    prep = rgeo_request_prepared_geometry(self_data);
    if (prep)
      val = GEOSPreparedIntersects(prep, rhs_geom);
    else
#endif
      val = GEOSIntersects(self_geom, rhs_geom);
    if (val == 0) {
      result = Qfalse;
    } else if (val == 1) {
      result = Qtrue;
    }
  }
  return result;
}

static VALUE
method_geometry_touches(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSGeometry* rhs_geom;
  char val;
  int state = 0;
#ifdef RGEO_GEOS_SUPPORTS_PREPARED2
  const GEOSPreparedGeometry* prep;
#endif

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    rhs_geom =
      rgeo_convert_to_geos_geometry(self_data->factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }
#ifdef RGEO_GEOS_SUPPORTS_PREPARED2
    prep = rgeo_request_prepared_geometry(self_data);
    if (prep)
      val = GEOSPreparedTouches(prep, rhs_geom);
    else
#endif
      val = GEOSTouches(self_geom, rhs_geom);
    if (val == 0) {
      result = Qfalse;
    } else if (val == 1) {
      result = Qtrue;
    }
  }
  return result;
}

static VALUE
method_geometry_crosses(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSGeometry* rhs_geom;
  char val;
  int state = 0;
#ifdef RGEO_GEOS_SUPPORTS_PREPARED2
  const GEOSPreparedGeometry* prep;
#endif

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    rhs_geom =
      rgeo_convert_to_geos_geometry(self_data->factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }
#ifdef RGEO_GEOS_SUPPORTS_PREPARED2
    prep = rgeo_request_prepared_geometry(self_data);
    if (prep)
      val = GEOSPreparedCrosses(prep, rhs_geom);
    else
#endif
      val = GEOSCrosses(self_geom, rhs_geom);
    if (val == 0) {
      result = Qfalse;
    } else if (val == 1) {
      result = Qtrue;
    }
  }
  return result;
}

static VALUE
method_geometry_within(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSGeometry* rhs_geom;
  char val;
  int state = 0;
#ifdef RGEO_GEOS_SUPPORTS_PREPARED2
  const GEOSPreparedGeometry* prep;
#endif

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    rhs_geom =
      rgeo_convert_to_geos_geometry(self_data->factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }
#ifdef RGEO_GEOS_SUPPORTS_PREPARED2
    prep = rgeo_request_prepared_geometry(self_data);
    if (prep)
      val = GEOSPreparedWithin(prep, rhs_geom);
    else
#endif
      val = GEOSWithin(self_geom, rhs_geom);
    if (val == 0) {
      result = Qfalse;
    } else if (val == 1) {
      result = Qtrue;
    }
  }
  return result;
}

static VALUE
method_geometry_contains(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSGeometry* rhs_geom;
  char val;
  int state = 0;
#ifdef RGEO_GEOS_SUPPORTS_PREPARED1
  const GEOSPreparedGeometry* prep;
#endif

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    rhs_geom =
      rgeo_convert_to_geos_geometry(self_data->factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }
#ifdef RGEO_GEOS_SUPPORTS_PREPARED1
    prep = rgeo_request_prepared_geometry(self_data);
    if (prep)
      val = GEOSPreparedContains(prep, rhs_geom);
    else
#endif
      val = GEOSContains(self_geom, rhs_geom);
    if (val == 0) {
      result = Qfalse;
    } else if (val == 1) {
      result = Qtrue;
    }
  }
  return result;
}

static VALUE
method_geometry_overlaps(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSGeometry* rhs_geom;
  char val;
  int state = 0;
#ifdef RGEO_GEOS_SUPPORTS_PREPARED2
  const GEOSPreparedGeometry* prep;
#endif

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    rhs_geom =
      rgeo_convert_to_geos_geometry(self_data->factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }
#ifdef RGEO_GEOS_SUPPORTS_PREPARED2
    prep = rgeo_request_prepared_geometry(self_data);
    if (prep)
      val = GEOSPreparedOverlaps(prep, rhs_geom);
    else
#endif
      val = GEOSOverlaps(self_geom, rhs_geom);
    if (val == 0) {
      result = Qfalse;
    } else if (val == 1) {
      result = Qtrue;
    }
  }
  return result;
}

static VALUE
method_geometry_relate(VALUE self, VALUE rhs, VALUE pattern)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSGeometry* rhs_geom;
  char val;
  int state = 0;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    rhs_geom =
      rgeo_convert_to_geos_geometry(self_data->factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }

    val = GEOSRelatePattern(self_geom, rhs_geom, StringValuePtr(pattern));
    if (val == 0) {
      result = Qfalse;
    } else if (val == 1) {
      result = Qtrue;
    }
  }
  return result;
}

static VALUE
method_geometry_distance(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  const GEOSGeometry* rhs_geom;
  double dist;
  int state = 0;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    rhs_geom =
      rgeo_convert_to_geos_geometry(self_data->factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }

    if (GEOSDistance(self_geom, rhs_geom, &dist)) {
      result = rb_float_new(dist);
    }
  }
  return result;
}

static VALUE
method_geometry_buffer(VALUE self, VALUE distance)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  VALUE factory;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    factory = self_data->factory;
    result = rgeo_wrap_geos_geometry(
      factory,
      GEOSBuffer(self_geom,
                 rb_num2dbl(distance),
                 RGEO_FACTORY_DATA_PTR(factory)->buffer_resolution),
      Qnil);
  }
  return result;
}

#ifdef RGEO_GEOS_SUPPORTS_DENSIFY
static VALUE
method_geometry_segmentize(VALUE self, VALUE max_segment_length)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  VALUE factory;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    factory = self_data->factory;
    result = rgeo_wrap_geos_geometry(
      factory, GEOSDensify(self_geom, rb_num2dbl(max_segment_length)), Qnil);
  }
  return result;
}
#endif

static VALUE
method_geometry_buffer_with_style(VALUE self,
                                  VALUE distance,
                                  VALUE endCapStyle,
                                  VALUE joinStyle,
                                  VALUE mitreLimit)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  VALUE factory;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    factory = self_data->factory;
    result = rgeo_wrap_geos_geometry(
      factory,
      GEOSBufferWithStyle(self_geom,
                          rb_num2dbl(distance),
                          RGEO_FACTORY_DATA_PTR(factory)->buffer_resolution,
                          RB_NUM2INT(endCapStyle),
                          RB_NUM2INT(joinStyle),
                          rb_num2dbl(mitreLimit)),
      Qnil);
  }
  return result;
}

static VALUE
method_geometry_simplify(VALUE self, VALUE tolerance)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  VALUE factory;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    factory = self_data->factory;
    result = rgeo_wrap_geos_geometry(
      factory, GEOSSimplify(self_geom, rb_num2dbl(tolerance)), Qnil);
  }
  return result;
}

static VALUE
method_geometry_simplify_preserve_topology(VALUE self, VALUE tolerance)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  VALUE factory;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    factory = self_data->factory;
    result = rgeo_wrap_geos_geometry(
      factory,
      GEOSTopologyPreserveSimplify(self_geom, rb_num2dbl(tolerance)),
      Qnil);
  }
  return result;
}

static VALUE
method_geometry_convex_hull(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    result = rgeo_wrap_geos_geometry(
      self_data->factory, GEOSConvexHull(self_geom), Qnil);
  }
  return result;
}

static VALUE
method_geometry_intersection(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  VALUE factory;
  const GEOSGeometry* rhs_geom;
  int state = 0;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    factory = self_data->factory;
    rhs_geom = rgeo_convert_to_geos_geometry(factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }

    result = rgeo_wrap_geos_geometry(
      factory, GEOSIntersection(self_geom, rhs_geom), Qnil);
  }
  return result;
}

static VALUE
method_geometry_union(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  VALUE factory;
  const GEOSGeometry* rhs_geom;
  int state = 0;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    factory = self_data->factory;
    rhs_geom = rgeo_convert_to_geos_geometry(factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }

    result =
      rgeo_wrap_geos_geometry(factory, GEOSUnion(self_geom, rhs_geom), Qnil);
  }
  return result;
}

static VALUE
method_geometry_unary_union(VALUE self)
{
#ifdef RGEO_GEOS_SUPPORTS_UNARYUNION
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;

  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    return rgeo_wrap_geos_geometry(
      self_data->factory, GEOSUnaryUnion(self_geom), Qnil);
  }
#endif

  return Qnil;
}

static VALUE
method_geometry_difference(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  VALUE factory;
  const GEOSGeometry* rhs_geom;
  int state = 0;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    factory = self_data->factory;
    rhs_geom = rgeo_convert_to_geos_geometry(factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }

    result = rgeo_wrap_geos_geometry(
      factory, GEOSDifference(self_geom, rhs_geom), Qnil);
  }
  return result;
}

static VALUE
method_geometry_sym_difference(VALUE self, VALUE rhs)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  VALUE factory;
  const GEOSGeometry* rhs_geom;
  int state = 0;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    factory = self_data->factory;
    rhs_geom = rgeo_convert_to_geos_geometry(factory, rhs, Qnil, &state);
    if (state) {
      rb_jump_tag(state);
    }

    result = rgeo_wrap_geos_geometry(
      factory, GEOSSymDifference(self_geom, rhs_geom), Qnil);
  }
  return result;
}

static VALUE
method_geometry_initialize_copy(VALUE self, VALUE orig)
{
  RGeo_GeometryData* self_data;
  const GEOSPreparedGeometry* prep;
  const GEOSGeometry* geom;
  RGeo_GeometryData* orig_data;
  GEOSGeometry* clone_geom;
  RGeo_FactoryData* factory_data;

  // Clear out any existing value
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  if (self_data->geom) {
    GEOSGeom_destroy(self_data->geom);
    self_data->geom = NULL;
  }
  prep = self_data->prep;
  if (prep && prep != (GEOSPreparedGeometry*)1 &&
      prep != (GEOSPreparedGeometry*)2) {
    GEOSPreparedGeom_destroy(prep);
  }
  self_data->prep = NULL;
  self_data->factory = Qnil;
  self_data->klasses = Qnil;

  // Copy value from orig
  geom = rgeo_get_geos_geometry_safe(orig);
  if (geom) {
    orig_data = RGEO_GEOMETRY_DATA_PTR(orig);
    clone_geom = GEOSGeom_clone(geom);
    if (clone_geom) {
      factory_data = RGEO_FACTORY_DATA_PTR(orig_data->factory);
      GEOSSetSRID(clone_geom, GEOSGetSRID(geom));
      self_data->geom = clone_geom;
      self_data->prep =
        factory_data &&
            ((factory_data->flags & RGEO_FACTORYFLAGS_PREPARE_HEURISTIC) != 0)
          ? (GEOSPreparedGeometry*)1
          : NULL;
      self_data->factory = orig_data->factory;
      self_data->klasses = orig_data->klasses;
    }
  }
  return self;
}

static VALUE
method_geometry_steal(VALUE self, VALUE orig)
{
  RGeo_GeometryData* self_data;
  const GEOSPreparedGeometry* prep;
  const GEOSGeometry* geom;
  RGeo_GeometryData* orig_data;

  geom = rgeo_get_geos_geometry_safe(orig);
  if (geom) {
    // Clear out any existing value
    self_data = RGEO_GEOMETRY_DATA_PTR(self);
    if (self_data->geom) {
      GEOSGeom_destroy(self_data->geom);
    }
    prep = self_data->prep;
    if (prep && prep != (GEOSPreparedGeometry*)1 &&
        prep != (GEOSPreparedGeometry*)2) {
      GEOSPreparedGeom_destroy(prep);
    }

    // Steal value from orig
    orig_data = RGEO_GEOMETRY_DATA_PTR(orig);
    self_data->geom = orig_data->geom;
    self_data->prep = orig_data->prep;
    self_data->factory = orig_data->factory;
    self_data->klasses = orig_data->klasses;

    // Clear out orig
    orig_data->geom = NULL;
    orig_data->prep = NULL;
    orig_data->factory = Qnil;
    orig_data->klasses = Qnil;
  }
  return self;
}

static VALUE
method_geometry_is_valid(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  char val;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    val = GEOSisValid(self_geom);
    if (val == 0) {
      result = Qfalse;
    } else if (val == 1) {
      result = Qtrue;
    }
  }
  return result;
}

static VALUE
method_geometry_invalid_reason(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  char* str;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    // We use NULL there to tell GEOS that we don't care about the position.
    switch (GEOSisValidDetail(self_geom, 0, &str, NULL)) {
      case 0: // invalid
        result = rb_utf8_str_new_cstr(str);
      case 1: // valid
        break;
      case 2: // exception
      default:
        result = rb_utf8_str_new_cstr("Exception");
        break;
    };
    if (str)
      GEOSFree(str);
  }
  return result;
}

static VALUE
method_geometry_invalid_reason_location(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  GEOSGeometry* location = NULL;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    // We use NULL there to tell GEOS that we don't care about the reason.
    switch (GEOSisValidDetail(self_geom, 0, NULL, &location)) {
      case 0: // invalid
        result = rgeo_wrap_geos_geometry(self_data->factory, location, Qnil);
      case 1: // valid
        break;
      case 2: // exception
        break;
      default:
        break;
    };
  }
  return result;
}

static VALUE
method_geometry_make_valid(VALUE self)
{
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  GEOSGeometry* valid_geom;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (!self_geom)
    return Qnil;

  // According to GEOS implementation, MakeValid always returns.
  valid_geom = GEOSMakeValid(self_geom);
  if (!valid_geom) {
    rb_raise(rb_eRGeoInvalidGeometry,
             "%" PRIsVALUE,
             method_geometry_invalid_reason(self));
  }
  return rgeo_wrap_geos_geometry(self_data->factory, valid_geom, Qnil);
}

static VALUE
method_geometry_point_on_surface(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    result = rgeo_wrap_geos_geometry(
      self_data->factory, GEOSPointOnSurface(self_geom), Qnil);
  }
  return result;
}

/**
 * call-seq:
 *   some.polygonize -> RGeo::Feature::GeometryCollection
 *
 * Polygonizes a set of Geometries which contain linework that
 * represents the edges of a planar graph.
 *
 * All types of Geometry are accepted as input;
 * the constituent linework is extracted as the edges to be polygonized.
 *
 * The edges must be correctly noded;
 * that is, they must only meet at their endpoints and not overlap anywhere.
 *
 * @see
 * https://libgeos.org/doxygen/geos__c_8h.html#a9d98e448d3b846d591c726d1c0000d25
 * GEOSPolygonize
 */
static VALUE
method_geometry_polygonize(VALUE self)
{
  VALUE result;
  RGeo_GeometryData* self_data;
  const GEOSGeometry* self_geom;
  GEOSGeometry* geos_polygon_collection;

  result = Qnil;
  self_data = RGEO_GEOMETRY_DATA_PTR(self);
  self_geom = self_data->geom;
  if (self_geom) {
    geos_polygon_collection = GEOSPolygonize(&self_geom, 1);

    if (geos_polygon_collection == NULL) {
      rb_raise(rb_eGeosError, "GEOS can't polygonize this geometry.");
    }

    result = rgeo_wrap_geos_geometry(
      self_data->factory, geos_polygon_collection, Qnil);
  }
  return result;
}

VALUE
rgeo_geos_geometries_strict_eql(const GEOSGeometry* geom1,
                                const GEOSGeometry* geom2)
{
  switch (GEOSEqualsExact(geom1, geom2, 0.0)) {
    case 0:
      return Qfalse;
    case 1:
      return Qtrue;
    case 2:
    default:
      rb_raise(rb_eGeosError, "Cannot test equality.");
  }
}

/**** INITIALIZATION FUNCTION ****/

void
rgeo_init_geos_geometry()
{
  VALUE geos_geometry_methods;

  geos_geometry_methods =
    rb_define_module_under(rgeo_geos_module, "CAPIGeometryMethods");

  rb_define_method(
    geos_geometry_methods, "factory=", method_geometry_set_factory, 1);
  rb_define_method(geos_geometry_methods,
                   "initialize_copy",
                   method_geometry_initialize_copy,
                   1);
  rb_define_method(geos_geometry_methods, "_steal", method_geometry_steal, 1);
  rb_define_method(
    geos_geometry_methods, "initialized?", method_geometry_initialized_p, 0);
  rb_define_method(
    geos_geometry_methods, "factory", method_geometry_factory, 0);
  rb_define_method(
    geos_geometry_methods, "prepared?", method_geometry_prepared_p, 0);
  rb_define_method(
    geos_geometry_methods, "prepare!", method_geometry_prepare, 0);
  rb_define_method(
    geos_geometry_methods, "dimension", method_geometry_dimension, 0);
  rb_define_method(
    geos_geometry_methods, "geometry_type", method_geometry_geometry_type, 0);
  rb_define_method(geos_geometry_methods, "srid", method_geometry_srid, 0);
  rb_define_method(
    geos_geometry_methods, "envelope", method_geometry_envelope, 0);
  rb_define_method(
    geos_geometry_methods, "boundary", method_geometry_boundary, 0);
  rb_define_method(
    geos_geometry_methods, "_as_text", method_geometry_as_text, 0);
  rb_define_method(
    geos_geometry_methods, "as_binary", method_geometry_as_binary, 0);
  rb_define_method(
    geos_geometry_methods, "empty?", method_geometry_is_empty, 0);
  rb_define_method(
    geos_geometry_methods, "simple?", method_geometry_is_simple, 0);
  rb_define_method(geos_geometry_methods, "equals?", method_geometry_equals, 1);
  rb_define_method(geos_geometry_methods, "==", method_geometry_equals, 1);
  rb_define_method(
    geos_geometry_methods, "rep_equals?", method_geometry_eql, 1);
  rb_define_method(geos_geometry_methods, "eql?", method_geometry_eql, 1);
  rb_define_method(
    geos_geometry_methods, "disjoint?", method_geometry_disjoint, 1);
  rb_define_method(
    geos_geometry_methods, "intersects?", method_geometry_intersects, 1);
  rb_define_method(
    geos_geometry_methods, "touches?", method_geometry_touches, 1);
  rb_define_method(
    geos_geometry_methods, "crosses?", method_geometry_crosses, 1);
  rb_define_method(geos_geometry_methods, "within?", method_geometry_within, 1);
  rb_define_method(
    geos_geometry_methods, "contains?", method_geometry_contains, 1);
  rb_define_method(
    geos_geometry_methods, "overlaps?", method_geometry_overlaps, 1);
  rb_define_method(geos_geometry_methods, "relate?", method_geometry_relate, 2);
  rb_define_method(
    geos_geometry_methods, "distance", method_geometry_distance, 1);
  rb_define_method(geos_geometry_methods, "buffer", method_geometry_buffer, 1);
  rb_define_method(geos_geometry_methods,
                   "buffer_with_style",
                   method_geometry_buffer_with_style,
                   4);
  rb_define_method(
    geos_geometry_methods, "simplify", method_geometry_simplify, 1);
  rb_define_method(geos_geometry_methods,
                   "simplify_preserve_topology",
                   method_geometry_simplify_preserve_topology,
                   1);
  rb_define_method(
    geos_geometry_methods, "convex_hull", method_geometry_convex_hull, 0);
  rb_define_method(
    geos_geometry_methods, "intersection", method_geometry_intersection, 1);
  rb_define_method(geos_geometry_methods, "*", method_geometry_intersection, 1);
  rb_define_method(geos_geometry_methods, "union", method_geometry_union, 1);
  rb_define_method(
    geos_geometry_methods, "unary_union", method_geometry_unary_union, 0);
  rb_define_method(geos_geometry_methods, "+", method_geometry_union, 1);
  rb_define_method(
    geos_geometry_methods, "difference", method_geometry_difference, 1);
  rb_define_method(geos_geometry_methods, "-", method_geometry_difference, 1);
  rb_define_method(
    geos_geometry_methods, "sym_difference", method_geometry_sym_difference, 1);
  rb_define_method(
    geos_geometry_methods, "valid?", method_geometry_is_valid, 0);
  rb_define_method(
    geos_geometry_methods, "invalid_reason", method_geometry_invalid_reason, 0);
  rb_define_method(geos_geometry_methods,
                   "invalid_reason_location",
                   method_geometry_invalid_reason_location,
                   0);
  rb_define_method(geos_geometry_methods,
                   "point_on_surface",
                   method_geometry_point_on_surface,
                   0);
  rb_define_method(
    geos_geometry_methods, "make_valid", method_geometry_make_valid, 0);
  rb_define_method(
    geos_geometry_methods, "polygonize", method_geometry_polygonize, 0);
#ifdef RGEO_GEOS_SUPPORTS_DENSIFY
  rb_define_method(
    geos_geometry_methods, "segmentize", method_geometry_segmentize, 1);
#endif
}

RGEO_END_C

#endif
