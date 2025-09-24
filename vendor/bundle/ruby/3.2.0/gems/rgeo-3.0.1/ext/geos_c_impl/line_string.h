/*
  Line string methods for GEOS wrapper
*/

#ifndef RGEO_GEOS_LINE_STRING_INCLUDED
#define RGEO_GEOS_LINE_STRING_INCLUDED

#include <geos_c.h>
#include <ruby.h>

RGEO_BEGIN_C

/*
  Initializes the line string module. This should be called after
  the geometry module is initialized.
*/
void
rgeo_init_geos_line_string();

/*
  Determines whether the given GEOS line string is closed.
  Returns Qtrue if true, Qfalse if false, or Qnil on an error.
*/
VALUE
rgeo_is_geos_line_string_closed(const GEOSGeometry* geom);

RGEO_END_C

#endif
