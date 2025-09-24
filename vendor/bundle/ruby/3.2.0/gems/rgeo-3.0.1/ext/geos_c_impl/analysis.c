/*
  Analysis methos for GEOS wrapper
*/

#include "preface.h"

#ifdef RGEO_GEOS_SUPPORTED

#include <geos_c.h>
#include <ruby.h>

#include "analysis.h"
#include "errors.h"
#include "factory.h"
#include "globals.h"

RGEO_BEGIN_C

/*
 * call-seq:
 *   RGeo::Geos::Analysis.ccw? -> true or false
 *
 * Checks direction for a ring, returns +true+ if counter-clockwise, +false+
 * otherwise.
 */
#ifdef RGEO_GEOS_SUPPORTS_ISCCW
VALUE
rgeo_geos_analysis_ccw_p(VALUE self, VALUE ring)
{
  const RGeo_GeometryData* ring_data;
  const GEOSCoordSequence* coord_seq;
  char is_ccw;

  rgeo_check_geos_object(ring);

  ring_data = RGEO_GEOMETRY_DATA_PTR(ring);

  coord_seq = GEOSGeom_getCoordSeq(ring_data->geom);
  if (!coord_seq) {
    rb_raise(rb_eGeosError, "Could not retrieve CoordSeq from given ring.");
  }
  if (!GEOSCoordSeq_isCCW(coord_seq, &is_ccw)) {
    rb_raise(rb_eGeosError, "Could not determine if the CoordSeq is CCW.");
  }

  return is_ccw ? Qtrue : Qfalse;
}
#endif // RGEO_GEOS_SUPPORTS_ISCCW

/**
 * call-seq:
 *   RGeo::Geos::Analysis.ccw_supported? -> true or false
 *
 * Checks if the RGEO_GEOS_SUPPORTS_ISCCW macro is defined, returns +true+
 * if it is, +false+ otherwise
 */
VALUE
rgeo_geos_analysis_supports_ccw(VALUE self)
{
#ifdef RGEO_GEOS_SUPPORTS_ISCCW
  return Qtrue;
#else
  return Qfalse;
#endif
}

void
rgeo_init_geos_analysis()
{
  VALUE geos_analysis_module;

  geos_analysis_module = rb_define_module_under(rgeo_geos_module, "Analysis");
  rb_define_singleton_method(
    geos_analysis_module, "ccw_supported?", rgeo_geos_analysis_supports_ccw, 0);
#ifdef RGEO_GEOS_SUPPORTS_ISCCW
  rb_define_singleton_method(
    geos_analysis_module, "ccw?", rgeo_geos_analysis_ccw_p, 1);
#endif // RGEO_GEOS_SUPPORTS_ISCCW
}

RGEO_END_C

#endif
