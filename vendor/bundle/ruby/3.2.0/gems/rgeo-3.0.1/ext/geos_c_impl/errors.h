
#ifndef RGEO_GEOS_ERROS_INCLUDED
#define RGEO_GEOS_ERROS_INCLUDED

#include <ruby.h>

#ifdef RGEO_GEOS_SUPPORTED

RGEO_BEGIN_C

// Main rgeo error type
extern VALUE rb_eRGeoError;
// RGeo::Error::InvalidGeometry
extern VALUE rb_eRGeoInvalidGeometry;
// RGeo::Error::ParseError
extern VALUE rb_eRGeoParseError;
// RGeo::Error::UnsupportedOperation
extern VALUE rb_eRGeoUnsupportedOperation;
// RGeo error specific to the GEOS implementation.
extern VALUE rb_eGeosError;

void
rgeo_init_geos_errors();

RGEO_END_C

#endif // RGEO_GEOS_SUPPORTED

#endif // RGEO_GEOS_ERROS_INCLUDED
