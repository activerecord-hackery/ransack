/*
  Preface header for GEOS wrapper
*/

#ifdef HAVE_GEOS_C_H
#ifdef HAVE_GEOSSETSRID_R
#define RGEO_GEOS_SUPPORTED
#endif
#endif

#ifdef HAVE_GEOSPREPAREDCONTAINS_R
#define RGEO_GEOS_SUPPORTS_PREPARED1
#endif
#ifdef HAVE_GEOSPREPAREDDISJOINT_R
#define RGEO_GEOS_SUPPORTS_PREPARED2
#endif
#ifdef HAVE_GEOSWKTWWRITER_SETOUTPUTDIMENSION_R
#define RGEO_GEOS_SUPPORTS_SETOUTPUTDIMENSION
#endif
#ifdef HAVE_GEOSUNARYUNION_R
#define RGEO_GEOS_SUPPORTS_UNARYUNION
#endif
#ifdef HAVE_GEOSCOORDSEQ_ISCCW_R
#define RGEO_GEOS_SUPPORTS_ISCCW
#endif
#ifdef HAVE_GEOSDENSIFY
#define RGEO_GEOS_SUPPORTS_DENSIFY
#endif
#ifdef HAVE_RB_GC_MARK_MOVABLE
#define mark rb_gc_mark_movable
#else
#define mark rb_gc_mark
#endif

#ifdef __cplusplus
#define RGEO_BEGIN_C                                                           \
  extern "C"                                                                   \
  {
#define RGEO_END_C }
#else
#define RGEO_BEGIN_C
#define RGEO_END_C
#endif

// https://ozlabs.org/~rusty/index.cgi/tech/2008-04-01.html
#define streq(a, b) (!strcmp((a), (b)))

// When using ruby ALLOC* macros, we are using ruby_xmalloc, which counterpart
// is ruby_xfree. This macro helps enforcing that by showing us the way.
#define FREE ruby_xfree
