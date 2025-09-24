#include <mysql2_ext.h>

extern VALUE mMysql2, cMysql2Error;
static VALUE cMysql2Statement, cBigDecimal, cDateTime, cDate;
static VALUE sym_stream, intern_new_with_args, intern_each, intern_to_s, intern_merge_bang;
static VALUE intern_sec_fraction, intern_usec, intern_sec, intern_min, intern_hour, intern_day, intern_month, intern_year,
  intern_query_options;

#ifndef NEW_TYPEDDATA_WRAPPER
#define TypedData_Get_Struct(obj, type, ignore, sval) Data_Get_Struct(obj, type, sval)
#endif

#define RAW_GET_STATEMENT(self) \
  mysql_stmt_wrapper *stmt_wrapper; \
  TypedData_Get_Struct(self, mysql_stmt_wrapper, &rb_mysql_statement_type, stmt_wrapper); \

#define GET_STATEMENT(self) \
  RAW_GET_STATEMENT(self) \
  if (!stmt_wrapper->stmt) { rb_raise(cMysql2Error, "Invalid statement handle"); } \
  if (stmt_wrapper->closed) { rb_raise(cMysql2Error, "Statement handle already closed"); }

static void rb_mysql_stmt_mark(void * ptr) {
  mysql_stmt_wrapper *stmt_wrapper = ptr;
  if (!stmt_wrapper) return;

  rb_gc_mark_movable(stmt_wrapper->client);
}

static void rb_mysql_stmt_free(void *ptr) {
  mysql_stmt_wrapper *stmt_wrapper = ptr;
  decr_mysql2_stmt(stmt_wrapper);
}

static size_t rb_mysql_stmt_memsize(const void * ptr) {
  const mysql_stmt_wrapper *stmt_wrapper = ptr;
  return sizeof(*stmt_wrapper);
}

#ifdef HAVE_RB_GC_MARK_MOVABLE
static void rb_mysql_stmt_compact(void * ptr) {
  mysql_stmt_wrapper *stmt_wrapper = ptr;
  if (!stmt_wrapper) return;

  rb_mysql2_gc_location(stmt_wrapper->client);
}
#endif

static const rb_data_type_t rb_mysql_statement_type = {
  "rb_mysql_statement",
  {
    rb_mysql_stmt_mark,
    rb_mysql_stmt_free,
    rb_mysql_stmt_memsize,
#ifdef HAVE_RB_GC_MARK_MOVABLE
    rb_mysql_stmt_compact,
#endif
  },
  0,
  0,
#ifdef RUBY_TYPED_FREE_IMMEDIATELY
  RUBY_TYPED_FREE_IMMEDIATELY,
#endif
};

static void *nogvl_stmt_close(void *ptr) {
  mysql_stmt_wrapper *stmt_wrapper = ptr;
  if (stmt_wrapper->stmt) {
    mysql_stmt_close(stmt_wrapper->stmt);
    stmt_wrapper->stmt = NULL;
  }
  return NULL;
}

void decr_mysql2_stmt(mysql_stmt_wrapper *stmt_wrapper) {
  stmt_wrapper->refcount--;

  if (stmt_wrapper->refcount == 0) {
    nogvl_stmt_close(stmt_wrapper);
    xfree(stmt_wrapper);
  }
}

void rb_raise_mysql2_stmt_error(mysql_stmt_wrapper *stmt_wrapper) {
  VALUE e;
  GET_CLIENT(stmt_wrapper->client);
  VALUE rb_error_msg = rb_str_new2(mysql_stmt_error(stmt_wrapper->stmt));
  VALUE rb_sql_state = rb_str_new2(mysql_stmt_sqlstate(stmt_wrapper->stmt));

  rb_encoding *conn_enc;
  conn_enc = rb_to_encoding(wrapper->encoding);

  rb_encoding *default_internal_enc = rb_default_internal_encoding();

  rb_enc_associate(rb_error_msg, conn_enc);
  rb_enc_associate(rb_sql_state, conn_enc);
  if (default_internal_enc) {
    rb_error_msg = rb_str_export_to_enc(rb_error_msg, default_internal_enc);
    rb_sql_state = rb_str_export_to_enc(rb_sql_state, default_internal_enc);
  }

  e = rb_funcall(cMysql2Error, intern_new_with_args, 4,
                 rb_error_msg,
                 LONG2FIX(wrapper->server_version),
                 UINT2NUM(mysql_stmt_errno(stmt_wrapper->stmt)),
                 rb_sql_state);
  rb_exc_raise(e);
}

/*
 * used to pass all arguments to mysql_stmt_prepare while inside
 * nogvl_prepare_statement_args
 */
struct nogvl_prepare_statement_args {
  MYSQL_STMT *stmt;
  VALUE sql;
  const char *sql_ptr;
  unsigned long sql_len;
};

static void *nogvl_prepare_statement(void *ptr) {
  struct nogvl_prepare_statement_args *args = ptr;

  if (mysql_stmt_prepare(args->stmt, args->sql_ptr, args->sql_len)) {
    return (void*)Qfalse;
  } else {
    return (void*)Qtrue;
  }
}

VALUE rb_mysql_stmt_new(VALUE rb_client, VALUE sql) {
  mysql_stmt_wrapper *stmt_wrapper;
  VALUE rb_stmt;
  rb_encoding *conn_enc;

  Check_Type(sql, T_STRING);

#ifdef NEW_TYPEDDATA_WRAPPER
  rb_stmt = TypedData_Make_Struct(cMysql2Statement, mysql_stmt_wrapper, &rb_mysql_statement_type, stmt_wrapper);
#else
  rb_stmt = Data_Make_Struct(cMysql2Statement, mysql_stmt_wrapper, rb_mysql_stmt_mark, rb_mysql_stmt_free, stmt_wrapper);
#endif
  {
    stmt_wrapper->client = rb_client;
    stmt_wrapper->refcount = 1;
    stmt_wrapper->closed = 0;
    stmt_wrapper->stmt = NULL;
  }

  // instantiate stmt
  {
    GET_CLIENT(rb_client);
    stmt_wrapper->stmt = mysql_stmt_init(wrapper->client);
    conn_enc = rb_to_encoding(wrapper->encoding);
  }
  if (stmt_wrapper->stmt == NULL) {
    rb_raise(cMysql2Error, "Unable to initialize prepared statement: out of memory");
  }

  // set STMT_ATTR_UPDATE_MAX_LENGTH attr
  {
    my_bool truth = 1;
    if (mysql_stmt_attr_set(stmt_wrapper->stmt, STMT_ATTR_UPDATE_MAX_LENGTH, &truth)) {
      rb_raise(cMysql2Error, "Unable to initialize prepared statement: set STMT_ATTR_UPDATE_MAX_LENGTH");
    }
  }

  // call mysql_stmt_prepare w/o gvl
  {
    struct nogvl_prepare_statement_args args;
    args.stmt = stmt_wrapper->stmt;
    // ensure the string is in the encoding the connection is expecting
    args.sql = rb_str_export_to_enc(sql, conn_enc);
    args.sql_ptr = RSTRING_PTR(sql);
    args.sql_len = RSTRING_LEN(sql);

    if ((VALUE)rb_thread_call_without_gvl(nogvl_prepare_statement, &args, RUBY_UBF_IO, 0) == Qfalse) {
      rb_raise_mysql2_stmt_error(stmt_wrapper);
    }
  }

  return rb_stmt;
}

/* call-seq: stmt.param_count # => Numeric
 *
 * Returns the number of parameters the prepared statement expects.
 */
static VALUE rb_mysql_stmt_param_count(VALUE self) {
  GET_STATEMENT(self);

  return ULL2NUM(mysql_stmt_param_count(stmt_wrapper->stmt));
}

/* call-seq: stmt.field_count # => Numeric
 *
 * Returns the number of fields the prepared statement returns.
 */
static VALUE rb_mysql_stmt_field_count(VALUE self) {
  GET_STATEMENT(self);

  return UINT2NUM(mysql_stmt_field_count(stmt_wrapper->stmt));
}

static void *nogvl_stmt_execute(void *ptr) {
  MYSQL_STMT *stmt = ptr;

  if (mysql_stmt_execute(stmt)) {
    return (void*)Qfalse;
  } else {
    return (void*)Qtrue;
  }
}

static void set_buffer_for_string(MYSQL_BIND* bind_buffer, unsigned long *length_buffer, VALUE string) {
  unsigned long length;

  bind_buffer->buffer = RSTRING_PTR(string);

  length = RSTRING_LEN(string);
  bind_buffer->buffer_length = length;
  *length_buffer = length;

  bind_buffer->length = length_buffer;
}

/* Free each bind_buffer[i].buffer except when params_enc is non-nil, this means
 * the buffer is a Ruby string pointer and not our memory to manage.
 */
#define FREE_BINDS                                          \
  for (i = 0; i < bind_count; i++) {                        \
    if (bind_buffers[i].buffer && NIL_P(params_enc[i])) {   \
      xfree(bind_buffers[i].buffer);                        \
    }                                                       \
  }                                                         \
  if (argc > 0) {                                           \
    xfree(bind_buffers);                                    \
    xfree(length_buffers);                                  \
  }

/* return 0 if the given bignum can cast as LONG_LONG, otherwise 1 */
static int my_big2ll(VALUE bignum, LONG_LONG *ptr)
{
  unsigned LONG_LONG num;
  size_t len;
// rb_absint_size was added in 2.1.0. See:
// https://github.com/ruby/ruby/commit/9fea875
#ifdef HAVE_RB_ABSINT_SIZE
  int nlz_bits = 0;
  len = rb_absint_size(bignum, &nlz_bits);
#else
  len = RBIGNUM_LEN(bignum) * SIZEOF_BDIGITS;
#endif
  if (len > sizeof(LONG_LONG)) goto overflow;
  if (RBIGNUM_POSITIVE_P(bignum)) {
    num = rb_big2ull(bignum);
    if (num > LLONG_MAX)
      goto overflow;
    *ptr = num;
  }
  else {
    if (len == 8 &&
#ifdef HAVE_RB_ABSINT_SIZE
        nlz_bits == 0 &&
#endif
// rb_absint_singlebit_p was added in 2.1.0. See:
// https://github.com/ruby/ruby/commit/e5ff9d5
#if defined(HAVE_RB_ABSINT_SIZE) && defined(HAVE_RB_ABSINT_SINGLEBIT_P)
        /* Optimized to avoid object allocation for Ruby 2.1+
         * only -0x8000000000000000 is safe if `len == 8 && nlz_bits == 0`
         */
        !rb_absint_singlebit_p(bignum)
#else
        rb_big_cmp(bignum, LL2NUM(LLONG_MIN)) == INT2FIX(-1)
#endif
       ) {
      goto overflow;
    }
    *ptr = rb_big2ll(bignum);
  }
  return 0;
overflow:
  return 1;
}

/* call-seq: stmt.execute
 *
 * Executes the current prepared statement, returns +result+.
 */
static VALUE rb_mysql_stmt_execute(int argc, VALUE *argv, VALUE self) {
  MYSQL_BIND *bind_buffers = NULL;
  unsigned long *length_buffers = NULL;
  unsigned long bind_count;
  unsigned long i;
  MYSQL_STMT *stmt;
  MYSQL_RES *metadata;
  VALUE opts;
  VALUE current;
  VALUE resultObj;
  VALUE *params_enc = NULL;
  int is_streaming;
  rb_encoding *conn_enc;

  GET_STATEMENT(self);
  GET_CLIENT(stmt_wrapper->client);

  conn_enc = rb_to_encoding(wrapper->encoding);

  stmt = stmt_wrapper->stmt;
  bind_count = mysql_stmt_param_count(stmt);

  // Get count of ordinary arguments, and extract hash opts/keyword arguments
  // Use a local scope to avoid leaking the temporary count variable
  {
    int c = rb_scan_args(argc, argv, "*:", NULL, &opts);
    if (c != (long)bind_count) {
      rb_raise(cMysql2Error, "Bind parameter count (%ld) doesn't match number of arguments (%d)", bind_count, c);
    }
  }

  // setup any bind variables in the query
  if (bind_count > 0) {
    // Scratch space for string encoding exports, allocate on the stack
    params_enc = alloca(sizeof(VALUE) * bind_count);
    bind_buffers = xcalloc(bind_count, sizeof(MYSQL_BIND));
    length_buffers = xcalloc(bind_count, sizeof(unsigned long));

    for (i = 0; i < bind_count; i++) {
      bind_buffers[i].buffer = NULL;
      params_enc[i] = Qnil;

      switch (TYPE(argv[i])) {
        case T_NIL:
          bind_buffers[i].buffer_type = MYSQL_TYPE_NULL;
          break;
        case T_FIXNUM:
#if SIZEOF_INT < SIZEOF_LONG
          bind_buffers[i].buffer_type = MYSQL_TYPE_LONGLONG;
          bind_buffers[i].buffer = xmalloc(sizeof(long long int));
          *(long*)(bind_buffers[i].buffer) = FIX2LONG(argv[i]);
#else
          bind_buffers[i].buffer_type = MYSQL_TYPE_LONG;
          bind_buffers[i].buffer = xmalloc(sizeof(int));
          *(long*)(bind_buffers[i].buffer) = FIX2INT(argv[i]);
#endif
          break;
        case T_BIGNUM:
          {
            LONG_LONG num;
            if (my_big2ll(argv[i], &num) == 0) {
              bind_buffers[i].buffer_type = MYSQL_TYPE_LONGLONG;
              bind_buffers[i].buffer = xmalloc(sizeof(long long int));
              *(LONG_LONG*)(bind_buffers[i].buffer) = num;
            } else {
              /* The bignum was larger than we can fit in LONG_LONG, send it as a string */
              bind_buffers[i].buffer_type = MYSQL_TYPE_NEWDECIMAL;
              params_enc[i] = rb_str_export_to_enc(rb_big2str(argv[i], 10), conn_enc);
              set_buffer_for_string(&bind_buffers[i], &length_buffers[i], params_enc[i]);
            }
          }
          break;
        case T_FLOAT:
          bind_buffers[i].buffer_type = MYSQL_TYPE_DOUBLE;
          bind_buffers[i].buffer = xmalloc(sizeof(double));
          *(double*)(bind_buffers[i].buffer) = NUM2DBL(argv[i]);
          break;
        case T_STRING:
          bind_buffers[i].buffer_type = MYSQL_TYPE_STRING;

          params_enc[i] = argv[i];
          params_enc[i] = rb_str_export_to_enc(params_enc[i], conn_enc);
          set_buffer_for_string(&bind_buffers[i], &length_buffers[i], params_enc[i]);
          break;
        case T_TRUE:
          bind_buffers[i].buffer_type = MYSQL_TYPE_TINY;
          bind_buffers[i].buffer = xmalloc(sizeof(signed char));
          *(signed char*)(bind_buffers[i].buffer) = 1;
          break;
        case T_FALSE:
          bind_buffers[i].buffer_type = MYSQL_TYPE_TINY;
          bind_buffers[i].buffer = xmalloc(sizeof(signed char));
          *(signed char*)(bind_buffers[i].buffer) = 0;
          break;
        default:
          // TODO: what Ruby type should support MYSQL_TYPE_TIME
          if (CLASS_OF(argv[i]) == rb_cTime || CLASS_OF(argv[i]) == cDateTime) {
            MYSQL_TIME t;
            VALUE rb_time = argv[i];

            bind_buffers[i].buffer_type = MYSQL_TYPE_DATETIME;
            bind_buffers[i].buffer = xmalloc(sizeof(MYSQL_TIME));

            memset(&t, 0, sizeof(MYSQL_TIME));
            t.neg = 0;

            if (CLASS_OF(argv[i]) == rb_cTime) {
              t.second_part = FIX2INT(rb_funcall(rb_time, intern_usec, 0));
            } else if (CLASS_OF(argv[i]) == cDateTime) {
              t.second_part = NUM2DBL(rb_funcall(rb_time, intern_sec_fraction, 0)) * 1000000;
            }

            t.second = FIX2INT(rb_funcall(rb_time, intern_sec, 0));
            t.minute = FIX2INT(rb_funcall(rb_time, intern_min, 0));
            t.hour = FIX2INT(rb_funcall(rb_time, intern_hour, 0));
            t.day = FIX2INT(rb_funcall(rb_time, intern_day, 0));
            t.month = FIX2INT(rb_funcall(rb_time, intern_month, 0));
            t.year = FIX2INT(rb_funcall(rb_time, intern_year, 0));

            *(MYSQL_TIME*)(bind_buffers[i].buffer) = t;
          } else if (CLASS_OF(argv[i]) == cDate) {
            MYSQL_TIME t;
            VALUE rb_time = argv[i];

            bind_buffers[i].buffer_type = MYSQL_TYPE_DATE;
            bind_buffers[i].buffer = xmalloc(sizeof(MYSQL_TIME));

            memset(&t, 0, sizeof(MYSQL_TIME));
            t.second_part = 0;
            t.neg = 0;
            t.day = FIX2INT(rb_funcall(rb_time, intern_day, 0));
            t.month = FIX2INT(rb_funcall(rb_time, intern_month, 0));
            t.year = FIX2INT(rb_funcall(rb_time, intern_year, 0));

            *(MYSQL_TIME*)(bind_buffers[i].buffer) = t;
          } else if (CLASS_OF(argv[i]) == cBigDecimal) {
            bind_buffers[i].buffer_type = MYSQL_TYPE_NEWDECIMAL;

            // DECIMAL are represented with the "string representation of the
            // original server-side value", see
            // https://dev.mysql.com/doc/refman/5.7/en/c-api-prepared-statement-type-conversions.html
            // This should be independent of the locale used both on the server
            // and the client side.
            VALUE rb_val_as_string = rb_funcall(argv[i], intern_to_s, 0);

            params_enc[i] = rb_val_as_string;
            params_enc[i] = rb_str_export_to_enc(params_enc[i], conn_enc);
            set_buffer_for_string(&bind_buffers[i], &length_buffers[i], params_enc[i]);
          }
          break;
      }
    }

    // copies bind_buffers into internal storage
    if (mysql_stmt_bind_param(stmt, bind_buffers)) {
      FREE_BINDS;
      rb_raise_mysql2_stmt_error(stmt_wrapper);
    }
  }

  // Duplicate the options hash, merge! extra opts, put the copy into the Result object
  current = rb_hash_dup(rb_ivar_get(stmt_wrapper->client, intern_query_options));
  (void)RB_GC_GUARD(current);
  Check_Type(current, T_HASH);

  // Merge in hash opts/keyword arguments
  if (!NIL_P(opts)) {
    rb_funcall(current, intern_merge_bang, 1, opts);
  }

  is_streaming = (Qtrue == rb_hash_aref(current, sym_stream));

  // From stmt_execute to mysql_stmt_result_metadata to stmt_store_result, no
  // Ruby API calls are allowed so that GC is not invoked. If the connection is
  // in results-streaming-mode for Statement A, and in the middle Statement B
  // gets garbage collected, a message will be sent to the server notifying it
  // to release Statement B, resulting in the following error:
  //   Commands out of sync; you can't run this command now
  //
  // In streaming mode, statement execute must return a cursor because we
  // cannot prevent other Statement objects from being garbage collected
  // between fetches of each row of the result set. The following error
  // occurs if cursor mode is not set:
  //   Row retrieval was canceled by mysql_stmt_close

  if (is_streaming) {
    unsigned long type = CURSOR_TYPE_READ_ONLY;
    if (mysql_stmt_attr_set(stmt, STMT_ATTR_CURSOR_TYPE, &type)) {
      FREE_BINDS;
      rb_raise(cMysql2Error, "Unable to stream prepared statement, could not set CURSOR_TYPE_READ_ONLY");
    }
  }

  if ((VALUE)rb_thread_call_without_gvl(nogvl_stmt_execute, stmt, RUBY_UBF_IO, 0) == Qfalse) {
    FREE_BINDS;
    rb_raise_mysql2_stmt_error(stmt_wrapper);
  }

  FREE_BINDS;

  metadata = mysql_stmt_result_metadata(stmt);
  if (metadata == NULL) {
    if (mysql_stmt_errno(stmt) != 0) {
      // either CR_OUT_OF_MEMORY or CR_UNKNOWN_ERROR. both fatal.
      wrapper->active_fiber = Qnil;
      rb_raise_mysql2_stmt_error(stmt_wrapper);
    }
    // no data and no error, so query was not a SELECT
    return Qnil;
  }

  if (!is_streaming) {
    // receive the whole result set from the server
    if (mysql_stmt_store_result(stmt)) {
      mysql_free_result(metadata);
      rb_raise_mysql2_stmt_error(stmt_wrapper);
    }
    wrapper->active_fiber = Qnil;
  }

  resultObj = rb_mysql_result_to_obj(stmt_wrapper->client, wrapper->encoding, current, metadata, self);

  rb_mysql_set_server_query_flags(wrapper->client, resultObj);

  if (!is_streaming) {
    // cache all result
    rb_funcall(resultObj, intern_each, 0);
  }

  return resultObj;
}

/* call-seq: stmt.fields # => array
 *
 * Returns a list of fields that will be returned by this statement.
 */
static VALUE rb_mysql_stmt_fields(VALUE self) {
  MYSQL_FIELD *fields;
  MYSQL_RES *metadata;
  unsigned int field_count;
  unsigned int i;
  VALUE field_list;
  MYSQL_STMT* stmt;
  rb_encoding *default_internal_enc, *conn_enc;
  GET_STATEMENT(self);
  GET_CLIENT(stmt_wrapper->client);
  stmt = stmt_wrapper->stmt;

  default_internal_enc = rb_default_internal_encoding();
  {
    GET_CLIENT(stmt_wrapper->client);
    conn_enc = rb_to_encoding(wrapper->encoding);
  }

  metadata = mysql_stmt_result_metadata(stmt);
  if (metadata == NULL) {
    if (mysql_stmt_errno(stmt) != 0) {
      // either CR_OUT_OF_MEMORY or CR_UNKNOWN_ERROR. both fatal.
      wrapper->active_fiber = Qnil;
      rb_raise_mysql2_stmt_error(stmt_wrapper);
    }
    // no data and no error, so query was not a SELECT
    return Qnil;
  }

  fields      = mysql_fetch_fields(metadata);
  field_count = mysql_stmt_field_count(stmt);
  field_list  = rb_ary_new2((long)field_count);

  for (i = 0; i < field_count; i++) {
    VALUE rb_field;

    rb_field = rb_str_new(fields[i].name, fields[i].name_length);
    rb_enc_associate(rb_field, conn_enc);
    if (default_internal_enc) {
     rb_field = rb_str_export_to_enc(rb_field, default_internal_enc);
   }

    rb_ary_store(field_list, (long)i, rb_field);
  }

  mysql_free_result(metadata);
  return field_list;
}

/* call-seq:
 *    stmt.last_id
 *
 * Returns the AUTO_INCREMENT value from the executed INSERT or UPDATE.
 */
static VALUE rb_mysql_stmt_last_id(VALUE self) {
  GET_STATEMENT(self);
  return ULL2NUM(mysql_stmt_insert_id(stmt_wrapper->stmt));
}

/* call-seq:
 *    stmt.affected_rows
 *
 * Returns the number of rows changed, deleted, or inserted.
 */
static VALUE rb_mysql_stmt_affected_rows(VALUE self) {
  my_ulonglong affected;
  GET_STATEMENT(self);

  affected = mysql_stmt_affected_rows(stmt_wrapper->stmt);
  if (affected == (my_ulonglong)-1) {
    rb_raise_mysql2_stmt_error(stmt_wrapper);
  }

  return ULL2NUM(affected);
}

/* call-seq:
 *    stmt.close
 *
 * Explicitly closing this will free up server resources immediately rather
 * than waiting for the garbage collector. Useful if you're managing your
 * own prepared statement cache.
 */
static VALUE rb_mysql_stmt_close(VALUE self) {
  RAW_GET_STATEMENT(self);

  if (!stmt_wrapper->closed) {
      stmt_wrapper->closed = 1;
      rb_thread_call_without_gvl(nogvl_stmt_close, stmt_wrapper, RUBY_UBF_IO, 0);
  }

  return Qnil;
}

/* call-seq:
 *    stmt.closed?
 *
 * Returns wheter or not the statement have been closed.
 */
static VALUE rb_mysql_stmt_closed_p(VALUE self) {
  RAW_GET_STATEMENT(self);

  return stmt_wrapper->closed ? Qtrue : Qfalse;
}

void init_mysql2_statement() {
  cDate = rb_const_get(rb_cObject, rb_intern("Date"));
  rb_global_variable(&cDate);

  cDateTime = rb_const_get(rb_cObject, rb_intern("DateTime"));
  rb_global_variable(&cDateTime);

  cBigDecimal = rb_const_get(rb_cObject, rb_intern("BigDecimal"));
  rb_global_variable(&cBigDecimal);

  cMysql2Statement = rb_define_class_under(mMysql2, "Statement", rb_cObject);
  rb_undef_alloc_func(cMysql2Statement);
  rb_global_variable(&cMysql2Statement);

  rb_define_method(cMysql2Statement, "param_count", rb_mysql_stmt_param_count, 0);
  rb_define_method(cMysql2Statement, "field_count", rb_mysql_stmt_field_count, 0);
  rb_define_method(cMysql2Statement, "_execute", rb_mysql_stmt_execute, -1);
  rb_define_method(cMysql2Statement, "fields", rb_mysql_stmt_fields, 0);
  rb_define_method(cMysql2Statement, "last_id", rb_mysql_stmt_last_id, 0);
  rb_define_method(cMysql2Statement, "affected_rows", rb_mysql_stmt_affected_rows, 0);
  rb_define_method(cMysql2Statement, "close", rb_mysql_stmt_close, 0);
  rb_define_method(cMysql2Statement, "closed?", rb_mysql_stmt_closed_p, 0);

  sym_stream = ID2SYM(rb_intern("stream"));

  intern_new_with_args = rb_intern("new_with_args");
  intern_each = rb_intern("each");

  intern_sec_fraction = rb_intern("sec_fraction");
  intern_usec = rb_intern("usec");
  intern_sec = rb_intern("sec");
  intern_min = rb_intern("min");
  intern_hour = rb_intern("hour");
  intern_day = rb_intern("day");
  intern_month = rb_intern("month");
  intern_year = rb_intern("year");

  intern_to_s = rb_intern("to_s");
  intern_merge_bang = rb_intern("merge!");
  intern_query_options = rb_intern("@query_options");
}
