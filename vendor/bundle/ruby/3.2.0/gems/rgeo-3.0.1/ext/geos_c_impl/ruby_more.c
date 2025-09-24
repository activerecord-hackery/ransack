/*
        Utilities for the ruby CAPI
*/

#ifndef RGEO_GEOS_RUBY_MORE_INCLUDED
#define RGEO_GEOS_RUBY_MORE_INCLUDED

#include "ruby_more.h"

#include <ruby.h>

#include "preface.h"

RGEO_BEGIN_C

struct funcall_args
{
  VALUE recv;
  ID mid;
  int argc;
  VALUE* argv;
};

static VALUE
inner_funcall(VALUE args_)
{
  struct funcall_args* args = (struct funcall_args*)args_;
  return rb_funcallv(args->recv, args->mid, args->argc, args->argv);
}

VALUE
rb_protect_funcall(VALUE recv, ID mid, int* state, int n, ...)
{
  struct funcall_args args;
  VALUE* argv;
  va_list ar;

  if (n > 0) {
    long i;
    va_start(ar, n);
    argv = ALLOCA_N(VALUE, n);
    for (i = 0; i < n; i++) {
      argv[i] = va_arg(ar, VALUE);
    }
    va_end(ar);
  } else {
    argv = 0;
  }

  args.recv = recv;
  args.mid = mid;
  args.argc = n;
  args.argv = argv;

  return rb_protect(inner_funcall, (VALUE)&args, state);
}

VALUE
rb_exc_raise_value(VALUE exc)
{
  rb_exc_raise(exc);
  return Qnil;
}

RGEO_END_C

#endif
