#ifndef MYSQL2_EXT
#define MYSQL2_EXT

void Init_mysql2(void);

/* tell rbx not to use it's caching compat layer
   by doing this we're making a promise to RBX that
   we'll never modify the pointers we get back from RSTRING_PTR */
#define RSTRING_NOT_MODIFIED
#include <ruby.h>

#ifdef HAVE_MYSQL_H
#include <mysql.h>
#include <errmsg.h>
#else
#include <mysql/mysql.h>
#include <mysql/errmsg.h>
#endif

#include <ruby/encoding.h>
#include <ruby/thread.h>

#if defined(__GNUC__) && (__GNUC__ >= 3)
#define RB_MYSQL_NORETURN __attribute__ ((noreturn))
#define RB_MYSQL_UNUSED __attribute__ ((unused))
#else
#define RB_MYSQL_NORETURN
#define RB_MYSQL_UNUSED
#endif

/* MySQL 8.0 replaces my_bool with C99 bool. Earlier versions of MySQL had
 * a typedef to char. Gem users reported failures on big endian systems when
 * using C99 bool types with older MySQLs due to mismatched behavior. */
#ifndef HAVE_TYPE_MY_BOOL
#include <stdbool.h>
typedef bool my_bool;
#endif

// ruby 2.7+
#ifdef HAVE_RB_GC_MARK_MOVABLE
#define rb_mysql2_gc_location(ptr) ptr = rb_gc_location(ptr)
#else
#define rb_gc_mark_movable(ptr) rb_gc_mark(ptr)
#define rb_mysql2_gc_location(ptr)
#endif

// ruby 2.2+
#ifdef TypedData_Make_Struct
#define NEW_TYPEDDATA_WRAPPER 1
#endif

#include <client.h>
#include <statement.h>
#include <result.h>
#include <infile.h>

#endif
