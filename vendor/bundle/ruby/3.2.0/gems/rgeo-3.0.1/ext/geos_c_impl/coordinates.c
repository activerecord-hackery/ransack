#include <geos_c.h>
#include <ruby.h>

VALUE
extract_points_from_coordinate_sequence(const GEOSCoordSequence* coord_sequence,
                                        int zCoordinate)
{
  VALUE result = Qnil;
  VALUE point;
  unsigned int count;
  unsigned int i;
  double val;

  if (GEOSCoordSeq_getSize(coord_sequence, &count)) {
    result = rb_ary_new2(count);
    for (i = 0; i < count; ++i) {
      if (zCoordinate) {
        point = rb_ary_new2(3);
      } else {
        point = rb_ary_new2(2);
      }
      GEOSCoordSeq_getX(coord_sequence, i, &val);
      rb_ary_push(point, rb_float_new(val));
      GEOSCoordSeq_getY(coord_sequence, i, &val);
      rb_ary_push(point, rb_float_new(val));
      if (zCoordinate) {
        GEOSCoordSeq_getZ(coord_sequence, i, &val);
        rb_ary_push(point, rb_float_new(val));
      }
      rb_ary_push(result, point);
    }
  }

  return result;
}

VALUE
extract_points_from_polygon(const GEOSGeometry* polygon, int zCoordinate)
{
  VALUE result = Qnil;

  const GEOSGeometry* ring;
  const GEOSCoordSequence* coord_sequence;
  unsigned int interior_ring_count;
  unsigned int i;

  if (polygon) {
    ring = GEOSGetExteriorRing(polygon);
    coord_sequence = GEOSGeom_getCoordSeq(ring);

    if (coord_sequence) {
      interior_ring_count = GEOSGetNumInteriorRings(polygon);
      result = rb_ary_new2(interior_ring_count + 1); // exterior + inner rings

      rb_ary_push(
        result,
        extract_points_from_coordinate_sequence(coord_sequence, zCoordinate));

      for (i = 0; i < interior_ring_count; ++i) {
        ring = GEOSGetInteriorRingN(polygon, i);
        coord_sequence = GEOSGeom_getCoordSeq(ring);
        if (coord_sequence) {
          rb_ary_push(result,
                      extract_points_from_coordinate_sequence(coord_sequence,
                                                              zCoordinate));
        }
      }
    }
  }
  return result;
}
