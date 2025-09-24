#include <sqlite3_ruby.h>
#include <aggregator.h>

#ifdef _MSC_VER
#pragma warning( push )
#pragma warning( disable : 4028 )
#endif

#define REQUIRE_OPEN_DB(_ctxt) \
  if(!_ctxt->db) \
    rb_raise(rb_path2class("SQLite3::Exception"), "cannot use a closed database");

VALUE cSqlite3Database;

static void deallocate(void * ctx)
{
  sqlite3RubyPtr c = (sqlite3RubyPtr)ctx;
  sqlite3 * db     = c->db;

  if(db) sqlite3_close(db);
  xfree(c);
}

static size_t database_memsize(const void *ctx)
{
  const sqlite3RubyPtr c = (const sqlite3RubyPtr)ctx;
  // NB: can't account for ctx->db because the type is incomplete.
  return sizeof(*c);
}

static const rb_data_type_t database_type = {
  "SQLite3::Backup",
  {
      NULL,
      deallocate,
      database_memsize,
  },
  0,
  0,
  RUBY_TYPED_WB_PROTECTED, // Not freed immediately because the dfree function do IOs.
};

static VALUE allocate(VALUE klass)
{
  sqlite3RubyPtr ctx;
  return TypedData_Make_Struct(klass, sqlite3Ruby, &database_type, ctx);
}

static char *
utf16_string_value_ptr(VALUE str)
{
  StringValue(str);
  rb_str_buf_cat(str, "\x00\x00", 2L);
  return RSTRING_PTR(str);
}

static VALUE sqlite3_rb_close(VALUE self);

sqlite3RubyPtr sqlite3_database_unwrap(VALUE database){
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(database, sqlite3Ruby, &database_type, ctx);
  return ctx;
}

static VALUE rb_sqlite3_open_v2(VALUE self, VALUE file, VALUE mode, VALUE zvfs)
{
  sqlite3RubyPtr ctx;
  int status;

  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);

#if defined TAINTING_SUPPORT
#  if defined StringValueCStr
  StringValuePtr(file);
  rb_check_safe_obj(file);
#  else
  Check_SafeStr(file);
#  endif
#endif

      status = sqlite3_open_v2(
          StringValuePtr(file),
          &ctx->db,
          NUM2INT(mode),
          NIL_P(zvfs) ? NULL : StringValuePtr(zvfs)
      );

  CHECK(ctx->db, status)

  return self;
}

static VALUE rb_sqlite3_disable_quirk_mode(VALUE self)
{
#if defined SQLITE_DBCONFIG_DQS_DDL
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);

  if(!ctx->db) return Qfalse;

  sqlite3_db_config(ctx->db, SQLITE_DBCONFIG_DQS_DDL, 0, (void*)0);
  sqlite3_db_config(ctx->db, SQLITE_DBCONFIG_DQS_DML, 0, (void*)0);

  return Qtrue;
#else
  return Qfalse;
#endif
}

/* call-seq: db.close
 *
 * Closes this database.
 */
static VALUE sqlite3_rb_close(VALUE self)
{
  sqlite3RubyPtr ctx;
  sqlite3 * db;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);

  db = ctx->db;
  CHECK(db, sqlite3_close(ctx->db));

  ctx->db = NULL;

  rb_iv_set(self, "-aggregators", Qnil);

  return self;
}

/* call-seq: db.closed?
 *
 * Returns +true+ if this database instance has been closed (see #close).
 */
static VALUE closed_p(VALUE self)
{
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);

  if(!ctx->db) return Qtrue;

  return Qfalse;
}

/* call-seq: total_changes
 *
 * Returns the total number of changes made to this database instance
 * since it was opened.
 */
static VALUE total_changes(VALUE self)
{
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  return INT2NUM(sqlite3_total_changes(ctx->db));
}

static void tracefunc(void * data, const char *sql)
{
  VALUE self = (VALUE)data;
  VALUE thing = rb_iv_get(self, "@tracefunc");
  rb_funcall(thing, rb_intern("call"), 1, rb_str_new2(sql));
}

/* call-seq:
 *    trace { |sql| ... }
 *    trace(Class.new { def call sql; end }.new)
 *
 * Installs (or removes) a block that will be invoked for every SQL
 * statement executed. The block receives one parameter: the SQL statement
 * executed. If the block is +nil+, any existing tracer will be uninstalled.
 */
static VALUE trace(int argc, VALUE *argv, VALUE self)
{
  sqlite3RubyPtr ctx;
  VALUE block;

  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  rb_scan_args(argc, argv, "01", &block);

  if(NIL_P(block) && rb_block_given_p()) block = rb_block_proc();

  rb_iv_set(self, "@tracefunc", block);

  sqlite3_trace(ctx->db, NIL_P(block) ? NULL : tracefunc, (void *)self);

  return self;
}

static int rb_sqlite3_busy_handler(void * ctx, int count)
{
  VALUE self = (VALUE)(ctx);
  VALUE handle = rb_iv_get(self, "@busy_handler");
  VALUE result = rb_funcall(handle, rb_intern("call"), 1, INT2NUM(count));

  if(Qfalse == result) return 0;

  return 1;
}

/* call-seq:
 *    busy_handler { |count| ... }
 *    busy_handler(Class.new { def call count; end }.new)
 *
 * Register a busy handler with this database instance. When a requested
 * resource is busy, this handler will be invoked. If the handler returns
 * +false+, the operation will be aborted; otherwise, the resource will
 * be requested again.
 *
 * The handler will be invoked with the name of the resource that was
 * busy, and the number of times it has been retried.
 *
 * See also the mutually exclusive #busy_timeout.
 */
static VALUE busy_handler(int argc, VALUE *argv, VALUE self)
{
  sqlite3RubyPtr ctx;
  VALUE block;
  int status;

  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  rb_scan_args(argc, argv, "01", &block);

  if(NIL_P(block) && rb_block_given_p()) block = rb_block_proc();

  rb_iv_set(self, "@busy_handler", block);

  status = sqlite3_busy_handler(
      ctx->db, NIL_P(block) ? NULL : rb_sqlite3_busy_handler, (void *)self);

  CHECK(ctx->db, status);

  return self;
}

/* call-seq: last_insert_row_id
 *
 * Obtains the unique row ID of the last row to be inserted by this Database
 * instance.
 */
static VALUE last_insert_row_id(VALUE self)
{
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  return LL2NUM(sqlite3_last_insert_rowid(ctx->db));
}

VALUE sqlite3val2rb(sqlite3_value * val)
{
  switch(sqlite3_value_type(val)) {
    case SQLITE_INTEGER:
      return LL2NUM(sqlite3_value_int64(val));
      break;
    case SQLITE_FLOAT:
      return rb_float_new(sqlite3_value_double(val));
      break;
    case SQLITE_TEXT:
      return rb_str_new2((const char *)sqlite3_value_text(val));
      break;
    case SQLITE_BLOB: {
      /* Sqlite warns calling sqlite3_value_bytes may invalidate pointer from sqlite3_value_blob,
         so we explicitly get the length before getting blob pointer.
         Note that rb_str_new apparently create string with ASCII-8BIT (BINARY) encoding,
         which is what we want, as blobs are binary
       */
      int len = sqlite3_value_bytes(val);
      return rb_str_new((const char *)sqlite3_value_blob(val), len);
      break;
    }
    case SQLITE_NULL:
      return Qnil;
      break;
    default:
      rb_raise(rb_eRuntimeError, "bad type"); /* FIXME */
  }
}

void set_sqlite3_func_result(sqlite3_context * ctx, VALUE result)
{
  switch(TYPE(result)) {
    case T_NIL:
      sqlite3_result_null(ctx);
      break;
    case T_FIXNUM:
      sqlite3_result_int64(ctx, (sqlite3_int64)FIX2LONG(result));
      break;
    case T_BIGNUM: {
#if SIZEOF_LONG < 8
      sqlite3_int64 num64;

      if (bignum_to_int64(result, &num64)) {
	  sqlite3_result_int64(ctx, num64);
	  break;
      }
#endif
    }
    case T_FLOAT:
      sqlite3_result_double(ctx, NUM2DBL(result));
      break;
    case T_STRING:
      if(CLASS_OF(result) == cSqlite3Blob
              || rb_enc_get_index(result) == rb_ascii8bit_encindex()
        ) {
        sqlite3_result_blob(
            ctx,
            (const void *)StringValuePtr(result),
            (int)RSTRING_LEN(result),
            SQLITE_TRANSIENT
        );
      } else {
        sqlite3_result_text(
            ctx,
            (const char *)StringValuePtr(result),
            (int)RSTRING_LEN(result),
            SQLITE_TRANSIENT
        );
      }
      break;
    default:
      rb_raise(rb_eRuntimeError, "can't return %s",
          rb_class2name(CLASS_OF(result)));
  }
}

static void rb_sqlite3_func(sqlite3_context * ctx, int argc, sqlite3_value **argv)
{
  VALUE callable = (VALUE)sqlite3_user_data(ctx);
  VALUE params = rb_ary_new2(argc);
  VALUE result;
  int i;

  if (argc > 0) {
    for(i = 0; i < argc; i++) {
      VALUE param = sqlite3val2rb(argv[i]);
      rb_ary_push(params, param);
    }
  }

  result = rb_apply(callable, rb_intern("call"), params);

  set_sqlite3_func_result(ctx, result);
}

#ifndef HAVE_RB_PROC_ARITY
int rb_proc_arity(VALUE self)
{
  return (int)NUM2INT(rb_funcall(self, rb_intern("arity"), 0));
}
#endif

/* call-seq: define_function_with_flags(name, flags) { |args,...| }
 *
 * Define a function named +name+ with +args+ using TextRep bitflags +flags+.  The arity of the block
 * will be used as the arity for the function defined.
 */
static VALUE define_function_with_flags(VALUE self, VALUE name, VALUE flags)
{
  sqlite3RubyPtr ctx;
  VALUE block;
  int status;

  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  block = rb_block_proc();

  status = sqlite3_create_function(
    ctx->db,
    StringValuePtr(name),
    rb_proc_arity(block),
    NUM2INT(flags),
    (void *)block,
    rb_sqlite3_func,
    NULL,
    NULL
  );

  CHECK(ctx->db, status);

  rb_hash_aset(rb_iv_get(self, "@functions"), name, block);

  return self;
}

/* call-seq: define_function(name) { |args,...| }
 *
 * Define a function named +name+ with +args+.  The arity of the block
 * will be used as the arity for the function defined.
 */
static VALUE define_function(VALUE self, VALUE name)
{
  return define_function_with_flags(self, name, INT2FIX(SQLITE_UTF8));
}

/* call-seq: interrupt
 *
 * Interrupts the currently executing operation, causing it to abort.
 */
static VALUE interrupt(VALUE self)
{
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  sqlite3_interrupt(ctx->db);

  return self;
}

/* call-seq: errmsg
 *
 * Return a string describing the last error to have occurred with this
 * database.
 */
static VALUE errmsg(VALUE self)
{
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  return rb_str_new2(sqlite3_errmsg(ctx->db));
}

/* call-seq: errcode
 *
 * Return an integer representing the last error to have occurred with this
 * database.
 */
static VALUE errcode_(VALUE self)
{
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  return INT2NUM(sqlite3_errcode(ctx->db));
}

/* call-seq: complete?(sql)
 *
 * Return +true+ if the string is a valid (ie, parsable) SQL statement, and
 * +false+ otherwise.
 */
static VALUE complete_p(VALUE UNUSED(self), VALUE sql)
{
  if(sqlite3_complete(StringValuePtr(sql)))
    return Qtrue;

  return Qfalse;
}

/* call-seq: changes
 *
 * Returns the number of changes made to this database instance by the last
 * operation performed. Note that a "delete from table" without a where
 * clause will not affect this value.
 */
static VALUE changes(VALUE self)
{
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  return INT2NUM(sqlite3_changes(ctx->db));
}

static int rb_sqlite3_auth(
    void *ctx,
    int _action,
    const char * _a,
    const char * _b,
    const char * _c,
    const char * _d)
{
  VALUE self   = (VALUE)ctx;
  VALUE action = INT2NUM(_action);
  VALUE a      = _a ? rb_str_new2(_a) : Qnil;
  VALUE b      = _b ? rb_str_new2(_b) : Qnil;
  VALUE c      = _c ? rb_str_new2(_c) : Qnil;
  VALUE d      = _d ? rb_str_new2(_d) : Qnil;
  VALUE callback = rb_iv_get(self, "@authorizer");
  VALUE result = rb_funcall(callback, rb_intern("call"), 5, action, a, b, c, d);

  if(T_FIXNUM == TYPE(result)) return (int)NUM2INT(result);
  if(Qtrue == result) return SQLITE_OK;
  if(Qfalse == result) return SQLITE_DENY;

  return SQLITE_IGNORE;
}

/* call-seq: set_authorizer = auth
 *
 * Set the authorizer for this database.  +auth+ must respond to +call+, and
 * +call+ must take 5 arguments.
 *
 * Installs (or removes) a block that will be invoked for every access
 * to the database. If the block returns 0 (or +true+), the statement
 * is allowed to proceed. Returning 1 or false causes an authorization error to
 * occur, and returning 2 or nil causes the access to be silently denied.
 */
static VALUE set_authorizer(VALUE self, VALUE authorizer)
{
  sqlite3RubyPtr ctx;
  int status;

  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  status = sqlite3_set_authorizer(
      ctx->db, NIL_P(authorizer) ? NULL : rb_sqlite3_auth, (void *)self
  );

  CHECK(ctx->db, status);

  rb_iv_set(self, "@authorizer", authorizer);

  return self;
}

/* call-seq: db.busy_timeout = ms
 *
 * Indicates that if a request for a resource terminates because that
 * resource is busy, SQLite should sleep and retry for up to the indicated
 * number of milliseconds. By default, SQLite does not retry
 * busy resources. To restore the default behavior, send 0 as the
 * +ms+ parameter.
 *
 * See also the mutually exclusive #busy_handler.
 */
static VALUE set_busy_timeout(VALUE self, VALUE timeout)
{
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  CHECK(ctx->db, sqlite3_busy_timeout(ctx->db, (int)NUM2INT(timeout)));

  return self;
}

/* call-seq: db.extended_result_codes = true
 *
 * Enable extended result codes in SQLite.  These result codes allow for more
 * detailed exception reporting, such a which type of constraint is violated.
 */
static VALUE set_extended_result_codes(VALUE self, VALUE enable)
{
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  CHECK(ctx->db, sqlite3_extended_result_codes(ctx->db, RTEST(enable) ? 1 : 0));

  return self;
}

int rb_comparator_func(void * ctx, int a_len, const void * a, int b_len, const void * b)
{
  VALUE comparator;
  VALUE a_str;
  VALUE b_str;
  VALUE comparison;
  rb_encoding * internal_encoding;

  internal_encoding = rb_default_internal_encoding();

  comparator = (VALUE)ctx;
  a_str = rb_str_new((const char *)a, a_len);
  b_str = rb_str_new((const char *)b, b_len);

  rb_enc_associate_index(a_str, rb_utf8_encindex());
  rb_enc_associate_index(b_str, rb_utf8_encindex());

  if(internal_encoding) {
    a_str = rb_str_export_to_enc(a_str, internal_encoding);
    b_str = rb_str_export_to_enc(b_str, internal_encoding);
  }

  comparison = rb_funcall(comparator, rb_intern("compare"), 2, a_str, b_str);

  return NUM2INT(comparison);
}

/* call-seq: db.collation(name, comparator)
 *
 * Add a collation with name +name+, and a +comparator+ object.  The
 * +comparator+ object should implement a method called "compare" that takes
 * two parameters and returns an integer less than, equal to, or greater than
 * 0.
 */
static VALUE collation(VALUE self, VALUE name, VALUE comparator)
{
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  CHECK(ctx->db, sqlite3_create_collation(
        ctx->db,
        StringValuePtr(name),
        SQLITE_UTF8,
        (void *)comparator,
        NIL_P(comparator) ? NULL : rb_comparator_func));

  /* Make sure our comparator doesn't get garbage collected. */
  rb_hash_aset(rb_iv_get(self, "@collations"), name, comparator);

  return self;
}

#ifdef HAVE_SQLITE3_LOAD_EXTENSION
/* call-seq: db.load_extension(file)
 *
 * Loads an SQLite extension library from the named file. Extension
 * loading must be enabled using db.enable_load_extension(true) prior
 * to calling this API.
 */
static VALUE load_extension(VALUE self, VALUE file)
{
  sqlite3RubyPtr ctx;
  int status;
  char *errMsg;
  VALUE errexp;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  status = sqlite3_load_extension(ctx->db, StringValuePtr(file), 0, &errMsg);
  if (status != SQLITE_OK)
  {
    errexp = rb_exc_new2(rb_eRuntimeError, errMsg);
    sqlite3_free(errMsg);
    rb_exc_raise(errexp);
  }

  return self;
}
#endif

#ifdef HAVE_SQLITE3_ENABLE_LOAD_EXTENSION
/* call-seq: db.enable_load_extension(onoff)
 *
 * Enable or disable extension loading.
 */
static VALUE enable_load_extension(VALUE self, VALUE onoff)
{
  sqlite3RubyPtr ctx;
  int onoffparam;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  if (Qtrue == onoff) {
    onoffparam = 1;
  } else if (Qfalse == onoff) {
    onoffparam = 0;
  } else {
    onoffparam = (int)NUM2INT(onoff);
  }

  CHECK(ctx->db, sqlite3_enable_load_extension(ctx->db, onoffparam));

  return self;
}
#endif

static int enc_cb(void * _self, int UNUSED(columns), char **data, char **UNUSED(names))
{
  VALUE self = (VALUE)_self;

  int index = rb_enc_find_index(data[0]);
  rb_encoding * e = rb_enc_from_index(index);
  rb_iv_set(self, "@encoding", rb_enc_from_encoding(e));

  return 0;
}

/* call-seq: db.encoding
 *
 * Fetch the encoding set on this database
 */
static VALUE db_encoding(VALUE self)
{
  sqlite3RubyPtr ctx;
  VALUE enc;

  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  enc = rb_iv_get(self, "@encoding");

  if(NIL_P(enc)) {
    sqlite3_exec(ctx->db, "PRAGMA encoding", enc_cb, (void *)self, NULL);
  }

  return rb_iv_get(self, "@encoding");
}

/* call-seq: db.transaction_active?
 *
 * Returns +true+ if there is a transaction active, and +false+ otherwise.
 *
 */
static VALUE transaction_active_p(VALUE self)
{
  sqlite3RubyPtr ctx;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  return sqlite3_get_autocommit(ctx->db) ? Qfalse : Qtrue;
}

static int hash_callback_function(VALUE callback_ary, int count, char **data, char **columns)
{
  VALUE new_hash = rb_hash_new();
  int i;

  for (i = 0; i < count; i++) {
    if (data[i] == NULL) {
      rb_hash_aset(new_hash, rb_str_new_cstr(columns[i]), Qnil);
    } else {
      rb_hash_aset(new_hash, rb_str_new_cstr(columns[i]), rb_str_new_cstr(data[i]));
    }
  }

  rb_ary_push(callback_ary, new_hash);

  return 0;
}

static int regular_callback_function(VALUE callback_ary, int count, char **data, char **columns)
{
  VALUE new_ary = rb_ary_new();
  int i;

  for (i = 0; i < count; i++) {
    if (data[i] == NULL) {
      rb_ary_push(new_ary, Qnil);
    } else {
      rb_ary_push(new_ary, rb_str_new_cstr(data[i]));
    }
  }

  rb_ary_push(callback_ary, new_ary);

  return 0;
}


/* Is invoked by calling db.execute_batch2(sql, &block)
 *
 * Executes all statements in a given string separated by semicolons.
 * If a query is made, all values returned are strings
 * (except for 'NULL' values which return nil),
 * so the user may parse values with a block.
 * If no query is made, an empty array will be returned.
 */
static VALUE exec_batch(VALUE self, VALUE sql, VALUE results_as_hash)
{
  sqlite3RubyPtr ctx;
  int status;
  VALUE callback_ary = rb_ary_new();
  char *errMsg;
  VALUE errexp;

  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  if(results_as_hash == Qtrue) {
    status = sqlite3_exec(ctx->db, StringValuePtr(sql), (sqlite3_callback)hash_callback_function, (void*)callback_ary, &errMsg);
  } else {
    status = sqlite3_exec(ctx->db, StringValuePtr(sql), (sqlite3_callback)regular_callback_function, (void*)callback_ary, &errMsg);
  }

  if (status != SQLITE_OK)
  {
    errexp = rb_exc_new2(rb_eRuntimeError, errMsg);
    sqlite3_free(errMsg);
    rb_exc_raise(errexp);
  }

  return callback_ary;
}

/* call-seq: db.db_filename(database_name)
 *
 * Returns the file associated with +database_name+.  Can return nil or an
 * empty string if the database is temporary, or in-memory.
 */
static VALUE db_filename(VALUE self, VALUE db_name)
{
  sqlite3RubyPtr ctx;
  const char * fname;
  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);
  REQUIRE_OPEN_DB(ctx);

  fname = sqlite3_db_filename(ctx->db, StringValueCStr(db_name));

  if(fname) return SQLITE3_UTF8_STR_NEW2(fname);
  return Qnil;
}

static VALUE rb_sqlite3_open16(VALUE self, VALUE file)
{
  int status;
  sqlite3RubyPtr ctx;

  TypedData_Get_Struct(self, sqlite3Ruby, &database_type, ctx);

#if defined TAINTING_SUPPORT
#if defined StringValueCStr
  StringValuePtr(file);
  rb_check_safe_obj(file);
#else
  Check_SafeStr(file);
#endif
#endif

  status = sqlite3_open16(utf16_string_value_ptr(file), &ctx->db);

  CHECK(ctx->db, status)

  return INT2NUM(status);
}

void init_sqlite3_database(void)
{
#if 0
  VALUE mSqlite3 = rb_define_module("SQLite3");
#endif
  cSqlite3Database = rb_define_class_under(mSqlite3, "Database", rb_cObject);

  rb_define_alloc_func(cSqlite3Database, allocate);
  rb_define_private_method(cSqlite3Database, "open_v2", rb_sqlite3_open_v2, 3);
  rb_define_private_method(cSqlite3Database, "open16", rb_sqlite3_open16, 1);
  rb_define_method(cSqlite3Database, "collation", collation, 2);
  rb_define_method(cSqlite3Database, "close", sqlite3_rb_close, 0);
  rb_define_method(cSqlite3Database, "closed?", closed_p, 0);
  rb_define_method(cSqlite3Database, "total_changes", total_changes, 0);
  rb_define_method(cSqlite3Database, "trace", trace, -1);
  rb_define_method(cSqlite3Database, "last_insert_row_id", last_insert_row_id, 0);
  rb_define_method(cSqlite3Database, "define_function", define_function, 1);
  rb_define_method(cSqlite3Database, "define_function_with_flags", define_function_with_flags, 2);
  /* public "define_aggregator" is now a shim around define_aggregator2
   * implemented in Ruby */
  rb_define_private_method(cSqlite3Database, "define_aggregator2", rb_sqlite3_define_aggregator2, 2);
  rb_define_private_method(cSqlite3Database, "disable_quirk_mode", rb_sqlite3_disable_quirk_mode, 0);
  rb_define_method(cSqlite3Database, "interrupt", interrupt, 0);
  rb_define_method(cSqlite3Database, "errmsg", errmsg, 0);
  rb_define_method(cSqlite3Database, "errcode", errcode_, 0);
  rb_define_method(cSqlite3Database, "complete?", complete_p, 1);
  rb_define_method(cSqlite3Database, "changes", changes, 0);
  rb_define_method(cSqlite3Database, "authorizer=", set_authorizer, 1);
  rb_define_method(cSqlite3Database, "busy_handler", busy_handler, -1);
  rb_define_method(cSqlite3Database, "busy_timeout=", set_busy_timeout, 1);
  rb_define_method(cSqlite3Database, "extended_result_codes=", set_extended_result_codes, 1);
  rb_define_method(cSqlite3Database, "transaction_active?", transaction_active_p, 0);
  rb_define_private_method(cSqlite3Database, "exec_batch", exec_batch, 2);
  rb_define_private_method(cSqlite3Database, "db_filename", db_filename, 1);

#ifdef HAVE_SQLITE3_LOAD_EXTENSION
  rb_define_method(cSqlite3Database, "load_extension", load_extension, 1);
#endif

#ifdef HAVE_SQLITE3_ENABLE_LOAD_EXTENSION
  rb_define_method(cSqlite3Database, "enable_load_extension", enable_load_extension, 1);
#endif

  rb_define_method(cSqlite3Database, "encoding", db_encoding, 0);

  rb_sqlite3_aggregator_init();
}

#ifdef _MSC_VER
#pragma warning( pop )
#endif
