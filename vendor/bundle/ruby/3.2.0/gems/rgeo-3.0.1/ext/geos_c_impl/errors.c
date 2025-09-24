
#ifndef RGEO_GEOS_ERROS_INCLUDED
#define RGEO_GEOS_ERROS_INCLUDED

#include <ruby.h>

#include "preface.h"

#ifdef RGEO_GEOS_SUPPORTED

#include "errors.h"
#include "globals.h"

RGEO_BEGIN_C

VALUE rb_eRGeoError;
VALUE rb_eRGeoInvalidGeometry;
VALUE rb_eRGeoParseError;
VALUE rb_eRGeoUnsupportedOperation;
VALUE rb_eGeosError;

void
rgeo_init_geos_errors()
{
  VALUE error_module;

  error_module = rb_define_module_under(rgeo_module, "Error");
  rb_eRGeoError =
    rb_define_class_under(error_module, "RGeoError", rb_eRuntimeError);
  rb_eRGeoInvalidGeometry =
    rb_define_class_under(error_module, "InvalidGeometry", rb_eRGeoError);
  rb_eRGeoUnsupportedOperation =
    rb_define_class_under(error_module, "UnsupportedOperation", rb_eRGeoError);
  rb_eRGeoParseError =
    rb_define_class_under(error_module, "ParseError", rb_eRGeoError);
  rb_eGeosError =
    rb_define_class_under(error_module, "GeosError", rb_eRGeoError);
}

RGEO_END_C

#endif // RGEO_GEOS_SUPPORTED

#endif // RGEO_GEOS_ERROS_INCLUDED
