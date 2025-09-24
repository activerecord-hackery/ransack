/*
        Utilities for the ruby CAPI
*/

#ifndef RGEO_GEOS_RUBY_MORE_INCLUDED
#define RGEO_GEOS_RUBY_MORE_INCLUDED

#include <ruby.h>

RGEO_BEGIN_C

VALUE
rb_protect_funcall(VALUE recv, ID mid, int* state, int n, ...);

/*
  Raises an error based on the exception passed in, but also returns
  a VALUE rather than void. This is so we can pass it into rb_protect
  without getting type mismatch warnings.
*/
VALUE
rb_exc_raise_value(VALUE exc);

RGEO_END_C

#endif
