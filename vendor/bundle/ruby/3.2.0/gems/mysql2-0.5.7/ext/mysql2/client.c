#include <mysql2_ext.h>

#include <time.h>
#include <errno.h>
#ifndef _WIN32
#include <sys/types.h>
#include <sys/socket.h>
#endif
#ifndef _MSC_VER
#include <unistd.h>
#endif
#include <fcntl.h>
#include "wait_for_single_fd.h"

#include "mysql_enc_name_to_ruby.h"

VALUE cMysql2Client;
extern VALUE mMysql2, cMysql2Error, cMysql2TimeoutError;
static VALUE sym_id, sym_version, sym_header_version, sym_async, sym_symbolize_keys, sym_as, sym_array, sym_stream;
static VALUE sym_no_good_index_used, sym_no_index_used, sym_query_was_slow;
static ID intern_brackets, intern_merge, intern_merge_bang, intern_new_with_args,
  intern_current_query_options, intern_read_timeout;

#define REQUIRE_INITIALIZED(wrapper) \
  if (!wrapper->initialized) { \
    rb_raise(cMysql2Error, "MySQL client is not initialized"); \
  }

#if defined(HAVE_MYSQL_NET_VIO) || defined(HAVE_ST_NET_VIO)
  #define CONNECTED(wrapper) (wrapper->client->net.vio != NULL && wrapper->client->net.fd != -1)
#elif defined(HAVE_MYSQL_NET_PVIO) || defined(HAVE_ST_NET_PVIO)
  #define CONNECTED(wrapper) (wrapper->client->net.pvio != NULL && wrapper->client->net.fd != -1)
#endif

#define REQUIRE_CONNECTED(wrapper) \
  REQUIRE_INITIALIZED(wrapper) \
  if (!CONNECTED(wrapper) && !wrapper->reconnect_enabled) { \
    rb_raise(cMysql2Error, "MySQL client is not connected"); \
  }

#define REQUIRE_NOT_CONNECTED(wrapper) \
  REQUIRE_INITIALIZED(wrapper) \
  if (CONNECTED(wrapper)) { \
    rb_raise(cMysql2Error, "MySQL connection is already open"); \
  }

/*
 * compatibility with mysql-connector-c, where LIBMYSQL_VERSION is the correct
 * variable to use, but MYSQL_SERVER_VERSION gives the correct numbers when
 * linking against the server itself
 *
 * MariaDB exposes its client version independently to the server version as
 * MARIADB_PACKAGE_VERSION.
 */
#if defined(MARIADB_PACKAGE_VERSION)
  #define MYSQL_LINK_VERSION MARIADB_PACKAGE_VERSION
#elif defined(LIBMYSQL_VERSION)
  #define MYSQL_LINK_VERSION LIBMYSQL_VERSION
#else
  #define MYSQL_LINK_VERSION MYSQL_SERVER_VERSION
#endif

/*
 * mariadb-connector-c defines CLIENT_SESSION_TRACKING and SESSION_TRACK_TRANSACTION_TYPE
 * while mysql-connector-c defines CLIENT_SESSION_TRACK and SESSION_TRACK_TRANSACTION_STATE
 * This is a hack to take care of both clients.
 */
#if defined(CLIENT_SESSION_TRACK)
#elif defined(CLIENT_SESSION_TRACKING)
  #define CLIENT_SESSION_TRACK CLIENT_SESSION_TRACKING
  #define SESSION_TRACK_TRANSACTION_STATE SESSION_TRACK_TRANSACTION_TYPE
#endif

/*
 * compatibility with mysql-connector-c 6.1.x, MySQL 5.7.3 - 5.7.10 & with MariaDB 10.x and later.
 */
#ifdef HAVE_CONST_MYSQL_OPT_SSL_VERIFY_SERVER_CERT
  #define SSL_MODE_VERIFY_IDENTITY 5
  #define HAVE_CONST_SSL_MODE_VERIFY_IDENTITY
#endif
#ifdef HAVE_CONST_MYSQL_OPT_SSL_ENFORCE
  #define SSL_MODE_DISABLED 1
  #define SSL_MODE_REQUIRED 3
  #define HAVE_CONST_SSL_MODE_DISABLED
  #define HAVE_CONST_SSL_MODE_REQUIRED
#endif

/*
 * used to pass all arguments to mysql_real_connect while inside
 * rb_thread_call_without_gvl
 */
struct nogvl_connect_args {
  MYSQL *mysql;
  const char *host;
  const char *user;
  const char *passwd;
  const char *db;
  unsigned int port;
  const char *unix_socket;
  unsigned long client_flag;
};

/*
 * used to pass all arguments to mysql_send_query while inside
 * rb_thread_call_without_gvl
 */
struct nogvl_send_query_args {
  MYSQL *mysql;
  VALUE sql;
  const char *sql_ptr;
  long sql_len;
  mysql_client_wrapper *wrapper;
};

/*
 * used to pass all arguments to mysql_select_db while inside
 * rb_thread_call_without_gvl
 */
struct nogvl_select_db_args {
  MYSQL *mysql;
  char *db;
};

static VALUE rb_set_ssl_mode_option(VALUE self, VALUE setting) {
  unsigned long version = mysql_get_client_version();
  const char *version_str = mysql_get_client_info();

  /* Warn about versions that are known to be incomplete; these are pretty
   * ancient, we want people to upgrade if they need SSL/TLS to work
   *
   * MySQL 5.x before 5.6.30 -- ssl_mode introduced but not fully working until 5.6.36)
   * MySQL 5.7 before 5.7.3 -- ssl_mode introduced but not fully working until 5.7.11)
   */
  if ((version >= 50000 && version < 50630) || (version >= 50700 && version < 50703)) {
    rb_warn("Your mysql client library version %s does not support setting ssl_mode; full support comes with 5.6.36+, 5.7.11+, 8.0+", version_str);
    return Qnil;
  }

  /* For these versions, map from the options we're exposing to Ruby to the constant available:
   *   ssl_mode: :verify_identity to MYSQL_OPT_SSL_VERIFY_SERVER_CERT = 1
   *   ssl_mode: :required to MYSQL_OPT_SSL_ENFORCE = 1
   *   ssl_mode: :disabled to MYSQL_OPT_SSL_ENFORCE = 0
   */
#if defined(HAVE_CONST_MYSQL_OPT_SSL_VERIFY_SERVER_CERT) || defined(HAVE_CONST_MYSQL_OPT_SSL_ENFORCE)
  GET_CLIENT(self);
  int val = NUM2INT(setting);

  /* Expected code path for MariaDB 10.x and MariaDB Connector/C 3.x
   * Workaround code path for MySQL 5.7.3 - 5.7.10 and MySQL Connector/C 6.1.3 - 6.1.x
   */
  if (version >= 100000                         // MariaDB (all versions numbered 10.x)
    || (version >= 30000 && version < 40000)    // MariaDB Connector/C (all versions numbered 3.x)
    || (version >= 50703 && version < 50711)    // Workaround for MySQL 5.7.3 - 5.7.10
    || (version >= 60103 && version < 60200)) { // Workaround for MySQL Connector/C 6.1.3 - 6.1.x
#ifdef HAVE_CONST_MYSQL_OPT_SSL_VERIFY_SERVER_CERT
    if (val == SSL_MODE_VERIFY_IDENTITY) {
      my_bool b = 1;
      int result = mysql_options(wrapper->client, MYSQL_OPT_SSL_VERIFY_SERVER_CERT, &b);
      return INT2NUM(result);
    }
#endif
#ifdef HAVE_CONST_MYSQL_OPT_SSL_ENFORCE
    if (val == SSL_MODE_DISABLED || val == SSL_MODE_REQUIRED) {
      my_bool b = (val == SSL_MODE_REQUIRED);
      int result = mysql_options(wrapper->client, MYSQL_OPT_SSL_ENFORCE, &b);
      return INT2NUM(result);
    }
#endif
    rb_warn("Your mysql client library version %s does not support ssl_mode %d", version_str, val);
    return Qnil;
  } else {
    rb_warn("Your mysql client library version %s does not support ssl_mode as expected", version_str);
    return Qnil;
  }
#endif

  /* For other versions -- known to be MySQL 5.6.36+, 5.7.11+, 8.0+
   * pass the value of the argument to MYSQL_OPT_SSL_MODE -- note the code
   * mapping from atoms / constants is in the MySQL::Client Ruby class
   */
#ifdef FULL_SSL_MODE_SUPPORT
  GET_CLIENT(self);
  int val = NUM2INT(setting);

  if (val != SSL_MODE_DISABLED && val != SSL_MODE_PREFERRED && val != SSL_MODE_REQUIRED && val != SSL_MODE_VERIFY_CA && val != SSL_MODE_VERIFY_IDENTITY) {
    rb_raise(cMysql2Error, "ssl_mode= takes DISABLED, PREFERRED, REQUIRED, VERIFY_CA, VERIFY_IDENTITY, you passed: %d", val );
  }
  int result = mysql_options(wrapper->client, MYSQL_OPT_SSL_MODE, &val);

  return INT2NUM(result);
#endif

  // Warn if we get this far
#ifdef NO_SSL_MODE_SUPPORT
  rb_warn("Your mysql client library does not support setting ssl_mode");
  return Qnil;
#endif
}

/*
 * non-blocking mysql_*() functions that we won't be wrapping since
 * they do not appear to hit the network nor issue any interruptible
 * or blocking system calls.
 *
 * - mysql_affected_rows()
 * - mysql_error()
 * - mysql_fetch_fields()
 * - mysql_fetch_lengths() - calls cli_fetch_lengths or emb_fetch_lengths
 * - mysql_field_count()
 * - mysql_get_client_info()
 * - mysql_get_client_version()
 * - mysql_get_server_info()
 * - mysql_get_server_version()
 * - mysql_insert_id()
 * - mysql_num_fields()
 * - mysql_num_rows()
 * - mysql_options()
 * - mysql_real_escape_string()
 * - mysql_ssl_set()
 */

static void rb_mysql_client_mark(void * wrapper) {
  mysql_client_wrapper * w = wrapper;
  if (w) {
    rb_gc_mark_movable(w->encoding);
    rb_gc_mark_movable(w->active_fiber);
  }
}

/* this is called during GC */
static void rb_mysql_client_free(void *ptr) {
  mysql_client_wrapper *wrapper = ptr;
  decr_mysql2_client(wrapper);
}

static size_t rb_mysql_client_memsize(const void * wrapper) {
  const mysql_client_wrapper * w = wrapper;
  return sizeof(*w);
}

static void rb_mysql_client_compact(void * wrapper) {
  mysql_client_wrapper * w = wrapper;
  if (w) {
    rb_mysql2_gc_location(w->encoding);
    rb_mysql2_gc_location(w->active_fiber);
  }
}

const rb_data_type_t rb_mysql_client_type = {
  "rb_mysql_client",
  {
    rb_mysql_client_mark,
    rb_mysql_client_free,
    rb_mysql_client_memsize,
#ifdef HAVE_RB_GC_MARK_MOVABLE
    rb_mysql_client_compact,
#endif
  },
  0,
  0,
#ifdef RUBY_TYPED_FREE_IMMEDIATELY
  RUBY_TYPED_FREE_IMMEDIATELY,
#endif
};

static VALUE rb_raise_mysql2_error(mysql_client_wrapper *wrapper) {
  VALUE rb_error_msg = rb_str_new2(mysql_error(wrapper->client));
  VALUE rb_sql_state = rb_str_new2(mysql_sqlstate(wrapper->client));
  VALUE e;

  rb_enc_associate(rb_error_msg, rb_utf8_encoding());
  rb_enc_associate(rb_sql_state, rb_usascii_encoding());

  e = rb_funcall(cMysql2Error, intern_new_with_args, 4,
                 rb_error_msg,
                 LONG2FIX(wrapper->server_version),
                 UINT2NUM(mysql_errno(wrapper->client)),
                 rb_sql_state);
  rb_exc_raise(e);
}

static void *nogvl_init(void *ptr) {
  MYSQL *client;
  mysql_client_wrapper *wrapper = ptr;

  /* may initialize embedded server and read /etc/services off disk */
  client = mysql_init(wrapper->client);

  if (client) mysql2_set_local_infile(client, wrapper);

  return (void*)(client ? Qtrue : Qfalse);
}

static void *nogvl_connect(void *ptr) {
  struct nogvl_connect_args *args = ptr;
  MYSQL *client;

  client = mysql_real_connect(args->mysql, args->host,
                              args->user, args->passwd,
                              args->db, args->port, args->unix_socket,
                              args->client_flag);

  return (void *)(client ? Qtrue : Qfalse);
}

#ifndef _WIN32
/*
 * Redirect clientfd to /dev/null for mysql_close and SSL_close to write,
 * shutdown, and close. The hack is needed to prevent shutdown() from breaking
 * a socket that may be in use by the parent or other processes after fork.
 *
 * /dev/null is used to absorb writes; previously a dummy socket was used, but
 * it could not absorb writes and caused openssl to go into an infinite loop.
 *
 * Returns Qtrue or Qfalse (success or failure)
 *
 * Note: if this function is needed on Windows, use "nul" instead of "/dev/null"
 */
static VALUE invalidate_fd(int clientfd)
{
#ifdef O_CLOEXEC
  /* Atomically set CLOEXEC on the new FD in case another thread forks */
  int sockfd = open("/dev/null", O_RDWR | O_CLOEXEC);
#else
  /* Well we don't have O_CLOEXEC, trigger the fallback code below */
  int sockfd = -1;
#endif

  if (sockfd < 0) {
    /* Either O_CLOEXEC wasn't defined at compile time, or it was defined at
     * compile time, but isn't available at run-time. So we'll just be quick
     * about setting FD_CLOEXEC now.
     */
    int flags;
    sockfd = open("/dev/null", O_RDWR);
    flags = fcntl(sockfd, F_GETFD);
    /* Do the flags dance in case there are more defined flags in the future */
    if (flags != -1) {
      flags |= FD_CLOEXEC;
      fcntl(sockfd, F_SETFD, flags);
    }
  }

  if (sockfd < 0) {
    /* Cannot raise here, because one or both of the following may be true:
     * a) we have no GVL (in C Ruby)
     * b) are running as a GC finalizer
     */
    return Qfalse;
  }

  dup2(sockfd, clientfd);
  close(sockfd);

  return Qtrue;
}
#endif /* _WIN32 */

static void *nogvl_close(void *ptr) {
  mysql_client_wrapper *wrapper = ptr;

  if (wrapper->initialized && !wrapper->closed) {
    mysql_close(wrapper->client);
    wrapper->closed = 1;
    wrapper->reconnect_enabled = 0;
    wrapper->active_fiber = Qnil;
  }

  return NULL;
}

void decr_mysql2_client(mysql_client_wrapper *wrapper)
{
  wrapper->refcount--;

  if (wrapper->refcount == 0) {
#ifndef _WIN32
    if (CONNECTED(wrapper) && !wrapper->automatic_close) {
      /* The client is being garbage collected while connected. Prevent
       * mysql_close() from sending a mysql-QUIT or from calling shutdown() on
       * the socket by invalidating it. invalidate_fd() will drop this
       * process's reference to the socket only, while a QUIT or shutdown()
       * would render the underlying connection unusable, interrupting other
       * processes which share this object across a fork().
       */
      if (invalidate_fd(wrapper->client->net.fd) == Qfalse) {
        fprintf(stderr, "[WARN] mysql2 failed to invalidate FD safely\n");
        close(wrapper->client->net.fd);
      }
      wrapper->client->net.fd = -1;
    }
#endif

    nogvl_close(wrapper);
    xfree(wrapper->client);
    xfree(wrapper);
  }
}

static VALUE allocate(VALUE klass) {
  VALUE obj;
  mysql_client_wrapper * wrapper;
#ifdef NEW_TYPEDDATA_WRAPPER
  obj = TypedData_Make_Struct(klass, mysql_client_wrapper, &rb_mysql_client_type, wrapper);
#else
  obj = Data_Make_Struct(klass, mysql_client_wrapper, rb_mysql_client_mark, rb_mysql_client_free, wrapper);
#endif
  wrapper->encoding = Qnil;
  wrapper->active_fiber = Qnil;
  wrapper->automatic_close = 1;
  wrapper->server_version = 0;
  wrapper->reconnect_enabled = 0;
  wrapper->connect_timeout = 0;
  wrapper->initialized = 0; /* will be set true after calling mysql_init */
  wrapper->closed = 1; /* will be set false after calling mysql_real_connect */
  wrapper->refcount = 1;
  wrapper->affected_rows = -1;
  wrapper->client = (MYSQL*)xmalloc(sizeof(MYSQL));

  return obj;
}

/* call-seq:
 *    Mysql2::Client.escape(string)
 *
 * Escape +string+ so that it may be used in a SQL statement.
 * Note that this escape method is not connection encoding aware.
 * If you need encoding support use Mysql2::Client#escape instead.
 */
static VALUE rb_mysql_client_escape(RB_MYSQL_UNUSED VALUE klass, VALUE str) {
  unsigned char *newStr;
  VALUE rb_str;
  unsigned long newLen, oldLen;

  Check_Type(str, T_STRING);

  oldLen = RSTRING_LEN(str);
  newStr = xmalloc(oldLen*2+1);

  newLen = mysql_escape_string((char *)newStr, RSTRING_PTR(str), oldLen);
  if (newLen == oldLen) {
    /* no need to return a new ruby string if nothing changed */
    xfree(newStr);
    return str;
  } else {
    rb_str = rb_str_new((const char*)newStr, newLen);
    rb_enc_copy(rb_str, str);
    xfree(newStr);
    return rb_str;
  }
}

static VALUE rb_mysql_client_warning_count(VALUE self) {
  unsigned int warning_count;
  GET_CLIENT(self);

  warning_count = mysql_warning_count(wrapper->client);

  return UINT2NUM(warning_count);
}

static VALUE rb_mysql_info(VALUE self) {
  const char *info;
  VALUE rb_str;
  GET_CLIENT(self);

  info = mysql_info(wrapper->client);

  if (info == NULL) {
    return Qnil;
  }

  rb_str = rb_str_new2(info);
  rb_enc_associate(rb_str, rb_utf8_encoding());

  return rb_str;
}

static VALUE rb_mysql_get_ssl_cipher(VALUE self)
{
  const char *cipher;
  VALUE rb_str;
  GET_CLIENT(self);

  cipher = mysql_get_ssl_cipher(wrapper->client);

  if (cipher == NULL) {
    return Qnil;
  }

  rb_str = rb_str_new2(cipher);
  rb_enc_associate(rb_str, rb_utf8_encoding());

  return rb_str;
}

#ifdef CLIENT_CONNECT_ATTRS
static int opt_connect_attr_add_i(VALUE key, VALUE value, VALUE arg)
{
  mysql_client_wrapper *wrapper = (mysql_client_wrapper *)arg;
  rb_encoding *enc = rb_to_encoding(wrapper->encoding);
  key = rb_str_export_to_enc(key, enc);
  value = rb_str_export_to_enc(value, enc);

  mysql_options4(wrapper->client, MYSQL_OPT_CONNECT_ATTR_ADD, StringValueCStr(key), StringValueCStr(value));
  return ST_CONTINUE;
}
#endif

static VALUE rb_mysql_connect(VALUE self, VALUE user, VALUE pass, VALUE host, VALUE port, VALUE database, VALUE socket, VALUE flags, VALUE conn_attrs) {
  struct nogvl_connect_args args;
  time_t start_time, end_time, elapsed_time, connect_timeout;
  VALUE rv;
  GET_CLIENT(self);

  args.host        = NIL_P(host)     ? NULL : StringValueCStr(host);
  args.unix_socket = NIL_P(socket)   ? NULL : StringValueCStr(socket);
  args.port        = NIL_P(port)     ? 0    : NUM2INT(port);
  args.user        = NIL_P(user)     ? NULL : StringValueCStr(user);
  args.passwd      = NIL_P(pass)     ? NULL : StringValueCStr(pass);
  args.db          = NIL_P(database) ? NULL : StringValueCStr(database);
  args.mysql       = wrapper->client;
  args.client_flag = NUM2ULONG(flags);

#ifdef CLIENT_CONNECT_ATTRS
  mysql_options(wrapper->client, MYSQL_OPT_CONNECT_ATTR_RESET, 0);
  rb_hash_foreach(conn_attrs, opt_connect_attr_add_i, (VALUE)wrapper);
#endif

  if (wrapper->connect_timeout)
    time(&start_time);
  rv = (VALUE) rb_thread_call_without_gvl(nogvl_connect, &args, RUBY_UBF_IO, 0);
  if (rv == Qfalse) {
    while (rv == Qfalse && errno == EINTR) {
      if (wrapper->connect_timeout) {
        time(&end_time);
        /* avoid long connect timeout from system time changes */
        if (end_time < start_time)
          start_time = end_time;
        elapsed_time = end_time - start_time;
        /* avoid an early timeout due to time truncating milliseconds off the start time */
        if (elapsed_time > 0)
          elapsed_time--;
        if (elapsed_time >= (time_t)wrapper->connect_timeout)
          break;
        connect_timeout = wrapper->connect_timeout - elapsed_time;
        mysql_options(wrapper->client, MYSQL_OPT_CONNECT_TIMEOUT, &connect_timeout);
      }
      errno = 0;
      rv = (VALUE) rb_thread_call_without_gvl(nogvl_connect, &args, RUBY_UBF_IO, 0);
    }
    /* restore the connect timeout for reconnecting */
    if (wrapper->connect_timeout)
      mysql_options(wrapper->client, MYSQL_OPT_CONNECT_TIMEOUT, &wrapper->connect_timeout);
    if (rv == Qfalse)
      rb_raise_mysql2_error(wrapper);
  }

  wrapper->closed = 0;
  wrapper->server_version = mysql_get_server_version(wrapper->client);
  return self;
}

/*
 * Immediately disconnect from the server; normally the garbage collector
 * will disconnect automatically when a connection is no longer needed.
 * Explicitly closing this will free up server resources sooner than waiting
 * for the garbage collector.
 *
 * @return [nil]
 */
static VALUE rb_mysql_client_close(VALUE self) {
  GET_CLIENT(self);

  if (wrapper->client) {
    rb_thread_call_without_gvl(nogvl_close, wrapper, RUBY_UBF_IO, 0);
  }

  return Qnil;
}

/* call-seq:
 *    client.closed?
 *
 * @return [Boolean]
 */
static VALUE rb_mysql_client_closed(VALUE self) {
  GET_CLIENT(self);
  return CONNECTED(wrapper) ? Qfalse : Qtrue;
}

/*
 * mysql_send_query is unlikely to block since most queries are small
 * enough to fit in a socket buffer, but sometimes large UPDATE and
 * INSERTs will cause the process to block
 */
static void *nogvl_send_query(void *ptr) {
  struct nogvl_send_query_args *args = ptr;
  int rv;

  rv = mysql_send_query(args->mysql, args->sql_ptr, args->sql_len);

  return (void*)(rv == 0 ? Qtrue : Qfalse);
}

static VALUE do_send_query(VALUE args) {
  struct nogvl_send_query_args *query_args = (void *)args;
  mysql_client_wrapper *wrapper = query_args->wrapper;
  if ((VALUE)rb_thread_call_without_gvl(nogvl_send_query, query_args, RUBY_UBF_IO, 0) == Qfalse) {
    /* an error occurred, we're not active anymore */
    wrapper->active_fiber = Qnil;
    rb_raise_mysql2_error(wrapper);
  }
  return Qnil;
}

/*
 * even though we did rb_thread_select before calling this, a large
 * response can overflow the socket buffers and cause us to eventually
 * block while calling mysql_read_query_result
 */
static void *nogvl_read_query_result(void *ptr) {
  MYSQL * client = ptr;
  my_bool res = mysql_read_query_result(client);

  return (void *)(res == 0 ? Qtrue : Qfalse);
}

static void *nogvl_do_result(void *ptr, char use_result) {
  mysql_client_wrapper *wrapper = ptr;
  MYSQL_RES *result;

  if (use_result) {
    result = mysql_use_result(wrapper->client);
  } else {
    result = mysql_store_result(wrapper->client);
  }

  /* once our result is stored off, this connection is
     ready for another command to be issued */
  wrapper->active_fiber = Qnil;

  return result;
}

/* mysql_store_result may (unlikely) read rows off the socket */
static void *nogvl_store_result(void *ptr) {
  return nogvl_do_result(ptr, 0);
}

static void *nogvl_use_result(void *ptr) {
  return nogvl_do_result(ptr, 1);
}

/* call-seq:
 *    client.async_result
 *
 * Returns the result for the last async issued query.
 */
static VALUE rb_mysql_client_async_result(VALUE self) {
  MYSQL_RES * result;
  VALUE resultObj;
  VALUE current, is_streaming;
  GET_CLIENT(self);

  /* if we're not waiting on a result, do nothing */
  if (NIL_P(wrapper->active_fiber))
    return Qnil;

  REQUIRE_CONNECTED(wrapper);
  if ((VALUE)rb_thread_call_without_gvl(nogvl_read_query_result, wrapper->client, RUBY_UBF_IO, 0) == Qfalse) {
    /* an error occurred, mark this connection inactive */
    wrapper->active_fiber = Qnil;
    rb_raise_mysql2_error(wrapper);
  }
  wrapper->affected_rows = mysql_affected_rows(wrapper->client);

  is_streaming = rb_hash_aref(rb_ivar_get(self, intern_current_query_options), sym_stream);
  if (is_streaming == Qtrue) {
    result = (MYSQL_RES *)rb_thread_call_without_gvl(nogvl_use_result, wrapper, RUBY_UBF_IO, 0);
  } else {
    result = (MYSQL_RES *)rb_thread_call_without_gvl(nogvl_store_result, wrapper, RUBY_UBF_IO, 0);
  }

  if (result == NULL) {
    if (mysql_errno(wrapper->client) != 0) {
      wrapper->active_fiber = Qnil;
      rb_raise_mysql2_error(wrapper);
    }
    /* no data and no error, so query was not a SELECT */
    return Qnil;
  }

  // Duplicate the options hash and put the copy in the Result object
  current = rb_hash_dup(rb_ivar_get(self, intern_current_query_options));
  (void)RB_GC_GUARD(current);
  Check_Type(current, T_HASH);
  resultObj = rb_mysql_result_to_obj(self, wrapper->encoding, current, result, Qnil);

  rb_mysql_set_server_query_flags(wrapper->client, resultObj);

  return resultObj;
}

#ifndef _WIN32
struct async_query_args {
  int fd;
  VALUE self;
};

static VALUE disconnect_and_raise(VALUE self, VALUE error) {
  GET_CLIENT(self);

  wrapper->active_fiber = Qnil;

  /* Invalidate the MySQL socket to prevent further communication.
   * The GC will come along later and call mysql_close to free it.
   */
  if (CONNECTED(wrapper)) {
    if (invalidate_fd(wrapper->client->net.fd) == Qfalse) {
      fprintf(stderr, "[WARN] mysql2 failed to invalidate FD safely, closing unsafely\n");
      close(wrapper->client->net.fd);
    }
    wrapper->client->net.fd = -1;
  }

  rb_exc_raise(error);
}

static VALUE do_query(VALUE args) {
  struct async_query_args *async_args = (void *)args;
  struct timeval tv;
  struct timeval *tvp;
  long int sec;
  int retval;
  VALUE read_timeout;

  read_timeout = rb_ivar_get(async_args->self, intern_read_timeout);

  tvp = NULL;
  if (!NIL_P(read_timeout)) {
    Check_Type(read_timeout, T_FIXNUM);
    tvp = &tv;
    sec = FIX2INT(read_timeout);
    /* TODO: support partial seconds?
       also, this check is here for sanity, we also check up in Ruby */
    if (sec >= 0) {
      tvp->tv_sec = sec;
    } else {
      rb_raise(cMysql2Error, "read_timeout must be a positive integer, you passed %ld", sec);
    }
    tvp->tv_usec = 0;
  }

  for(;;) {
    retval = rb_wait_for_single_fd(async_args->fd, RB_WAITFD_IN, tvp);

    if (retval == 0) {
      rb_raise(cMysql2TimeoutError, "Timeout waiting for a response from the last query. (waited %d seconds)", FIX2INT(read_timeout));
    }

    if (retval < 0) {
      rb_sys_fail(0);
    }

    if (retval > 0) {
      break;
    }
  }

  return Qnil;
}
#endif

static VALUE disconnect_and_mark_inactive(VALUE self) {
  GET_CLIENT(self);

  /* Check if execution terminated while result was still being read. */
  if (!NIL_P(wrapper->active_fiber)) {
    if (CONNECTED(wrapper)) {
      /* Invalidate the MySQL socket to prevent further communication. */
#ifndef _WIN32
      if (invalidate_fd(wrapper->client->net.fd) == Qfalse) {
        rb_warn("mysql2 failed to invalidate FD safely, closing unsafely\n");
        close(wrapper->client->net.fd);
      }
#else
      close(wrapper->client->net.fd);
#endif
      wrapper->client->net.fd = -1;
    }
    /* Skip mysql client check performed before command execution. */
    wrapper->client->status = MYSQL_STATUS_READY;
    wrapper->active_fiber = Qnil;
  }

  return Qnil;
}

static void rb_mysql_client_set_active_fiber(VALUE self) {
  VALUE fiber_current = rb_fiber_current();
  GET_CLIENT(self);

  // see if this connection is still waiting on a result from a previous query
  if (NIL_P(wrapper->active_fiber)) {
    // mark this connection active
    wrapper->active_fiber = fiber_current;
  } else if (wrapper->active_fiber == fiber_current) {
    rb_raise(cMysql2Error, "This connection is still waiting for a result, try again once you have the result");
  } else {
    VALUE inspect = rb_inspect(wrapper->active_fiber);
    const char *thr = StringValueCStr(inspect);

    rb_raise(cMysql2Error, "This connection is in use by: %s", thr);
  }
}

/* call-seq:
 *    client.abandon_results!
 *
 * When using MULTI_STATEMENTS support, calling this will throw
 * away any unprocessed results as fast as it can in order to
 * put the connection back into a state where queries can be issued
 * again.
 */
static VALUE rb_mysql_client_abandon_results(VALUE self) {
  MYSQL_RES *result;
  int ret;

  GET_CLIENT(self);

  while (mysql_more_results(wrapper->client) == 1) {
    ret = mysql_next_result(wrapper->client);
    if (ret > 0) {
      rb_raise_mysql2_error(wrapper);
    }

    result = (MYSQL_RES *)rb_thread_call_without_gvl(nogvl_store_result, wrapper, RUBY_UBF_IO, 0);

    if (result != NULL) {
      mysql_free_result(result);
    }
  }

  return Qnil;
}

/* call-seq:
 *    client.query(sql, options = {})
 *
 * Query the database with +sql+, with optional +options+.  For the possible
 * options, see default_query_options on the Mysql2::Client class.
 */
static VALUE rb_mysql_query(VALUE self, VALUE sql, VALUE current) {
#ifndef _WIN32
  struct async_query_args async_args;
#endif
  struct nogvl_send_query_args args;
  GET_CLIENT(self);

  REQUIRE_CONNECTED(wrapper);
  args.mysql = wrapper->client;

  (void)RB_GC_GUARD(current);
  Check_Type(current, T_HASH);
  rb_ivar_set(self, intern_current_query_options, current);

  Check_Type(sql, T_STRING);
  /* ensure the string is in the encoding the connection is expecting */
  args.sql = rb_str_export_to_enc(sql, rb_to_encoding(wrapper->encoding));
  args.sql_ptr = RSTRING_PTR(args.sql);
  args.sql_len = RSTRING_LEN(args.sql);
  args.wrapper = wrapper;

  rb_mysql_client_set_active_fiber(self);

#ifndef _WIN32
  rb_rescue2(do_send_query, (VALUE)&args, disconnect_and_raise, self, rb_eException, (VALUE)0);
  (void)RB_GC_GUARD(sql);

  if (rb_hash_aref(current, sym_async) == Qtrue) {
    return Qnil;
  } else {
    async_args.fd = wrapper->client->net.fd;
    async_args.self = self;

    rb_rescue2(do_query, (VALUE)&async_args, disconnect_and_raise, self, rb_eException, (VALUE)0);

    return rb_ensure(rb_mysql_client_async_result, self, disconnect_and_mark_inactive, self);
  }
#else
  do_send_query((VALUE)&args);
  (void)RB_GC_GUARD(sql);

  /* this will just block until the result is ready */
  return rb_ensure(rb_mysql_client_async_result, self, disconnect_and_mark_inactive, self);
#endif
}

/* call-seq:
 *    client.escape(string)
 *
 * Escape +string+ so that it may be used in a SQL statement.
 */
static VALUE rb_mysql_client_real_escape(VALUE self, VALUE str) {
  unsigned char *newStr;
  VALUE rb_str;
  unsigned long newLen, oldLen;
  rb_encoding *default_internal_enc;
  rb_encoding *conn_enc;
  GET_CLIENT(self);

  REQUIRE_CONNECTED(wrapper);
  Check_Type(str, T_STRING);
  default_internal_enc = rb_default_internal_encoding();
  conn_enc = rb_to_encoding(wrapper->encoding);
  /* ensure the string is in the encoding the connection is expecting */
  str = rb_str_export_to_enc(str, conn_enc);

  oldLen = RSTRING_LEN(str);
  newStr = xmalloc(oldLen*2+1);

  newLen = mysql_real_escape_string(wrapper->client, (char *)newStr, RSTRING_PTR(str), oldLen);
  if (newLen == oldLen) {
    /* no need to return a new ruby string if nothing changed */
    if (default_internal_enc) {
      str = rb_str_export_to_enc(str, default_internal_enc);
    }
    xfree(newStr);
    return str;
  } else {
    rb_str = rb_str_new((const char*)newStr, newLen);
    rb_enc_associate(rb_str, conn_enc);
    if (default_internal_enc) {
      rb_str = rb_str_export_to_enc(rb_str, default_internal_enc);
    }
    xfree(newStr);
    return rb_str;
  }
}

static VALUE _mysql_client_options(VALUE self, int opt, VALUE value) {
  int result;
  const void *retval = NULL;
  unsigned int intval = 0;
  const char * charval = NULL;
  my_bool boolval;

  GET_CLIENT(self);

  REQUIRE_NOT_CONNECTED(wrapper);

  if (NIL_P(value))
      return Qfalse;

  switch(opt) {
    case MYSQL_OPT_CONNECT_TIMEOUT:
      intval = NUM2UINT(value);
      retval = &intval;
      break;

    case MYSQL_OPT_READ_TIMEOUT:
      intval = NUM2UINT(value);
      retval = &intval;
      break;

    case MYSQL_OPT_WRITE_TIMEOUT:
      intval = NUM2UINT(value);
      retval = &intval;
      break;

    case MYSQL_OPT_LOCAL_INFILE:
      intval = (value == Qfalse ? 0 : 1);
      retval = &intval;
      break;

    case MYSQL_OPT_RECONNECT:
      boolval = (value == Qfalse ? 0 : 1);
      retval = &boolval;
      break;

#ifdef MYSQL_SECURE_AUTH
    case MYSQL_SECURE_AUTH:
      boolval = (value == Qfalse ? 0 : 1);
      retval = &boolval;
      break;
#endif

    case MYSQL_READ_DEFAULT_FILE:
      charval = (const char *)StringValueCStr(value);
      retval  = charval;
      break;

    case MYSQL_READ_DEFAULT_GROUP:
      charval = (const char *)StringValueCStr(value);
      retval  = charval;
      break;

    case MYSQL_INIT_COMMAND:
      charval = (const char *)StringValueCStr(value);
      retval  = charval;
      break;

#ifdef HAVE_CONST_MYSQL_OPT_GET_SERVER_PUBLIC_KEY
    case MYSQL_OPT_GET_SERVER_PUBLIC_KEY:
      boolval = (value == Qfalse ? 0 : 1);
      retval = &boolval;
      break;
#endif

#ifdef HAVE_MYSQL_DEFAULT_AUTH
    case MYSQL_DEFAULT_AUTH:
      charval = (const char *)StringValueCStr(value);
      retval  = charval;
      break;
#endif

#ifdef HAVE_CONST_MYSQL_ENABLE_CLEARTEXT_PLUGIN
    case MYSQL_ENABLE_CLEARTEXT_PLUGIN:
      boolval = (value == Qfalse ? 0 : 1);
      retval = &boolval;
      break;
#endif

    default:
      return Qfalse;
  }

  result = mysql_options(wrapper->client, opt, retval);

  /* Zero means success */
  if (result != 0) {
    rb_warn("%s\n", mysql_error(wrapper->client));
  } else {
    /* Special case for options that are stored in the wrapper struct */
    switch (opt) {
      case MYSQL_OPT_RECONNECT:
        wrapper->reconnect_enabled = boolval;
        break;
      case MYSQL_OPT_CONNECT_TIMEOUT:
        wrapper->connect_timeout = intval;
        break;
    }
  }

  return (result == 0) ? Qtrue : Qfalse;
}

/* call-seq:
 *    client.info
 *
 * Returns a string that represents the client library version.
 */
static VALUE rb_mysql_client_info(RB_MYSQL_UNUSED VALUE klass) {
  VALUE version_info, version, header_version;
  version_info = rb_hash_new();

  version = rb_str_new2(mysql_get_client_info());
  header_version = rb_str_new2(MYSQL_LINK_VERSION);

  rb_enc_associate(version, rb_usascii_encoding());
  rb_enc_associate(header_version, rb_usascii_encoding());

  rb_hash_aset(version_info, sym_id, LONG2NUM(mysql_get_client_version()));
  rb_hash_aset(version_info, sym_version, version);
  rb_hash_aset(version_info, sym_header_version, header_version);

  return version_info;
}

/* call-seq:
 *    client.server_info
 *
 * Returns a string that represents the server version number
 */
static VALUE rb_mysql_client_server_info(VALUE self) {
  VALUE version, server_info;
  rb_encoding *default_internal_enc;
  rb_encoding *conn_enc;
  GET_CLIENT(self);

  REQUIRE_CONNECTED(wrapper);
  default_internal_enc = rb_default_internal_encoding();
  conn_enc = rb_to_encoding(wrapper->encoding);

  version = rb_hash_new();
  rb_hash_aset(version, sym_id, LONG2FIX(mysql_get_server_version(wrapper->client)));
  server_info = rb_str_new2(mysql_get_server_info(wrapper->client));
  rb_enc_associate(server_info, conn_enc);
  if (default_internal_enc) {
    server_info = rb_str_export_to_enc(server_info, default_internal_enc);
  }
  rb_hash_aset(version, sym_version, server_info);
  return version;
}

/* call-seq:
 *    client.socket
 *
 * Return the file descriptor number for this client.
 */
#ifndef _WIN32
static VALUE rb_mysql_client_socket(VALUE self) {
  GET_CLIENT(self);
  REQUIRE_CONNECTED(wrapper);
  return INT2NUM(wrapper->client->net.fd);
}
#else
static VALUE rb_mysql_client_socket(RB_MYSQL_UNUSED VALUE self) {
  rb_raise(cMysql2Error, "Raw access to the mysql file descriptor isn't supported on Windows");
}
#endif

/* call-seq:
 *    client.last_id
 *
 * Returns the value generated for an AUTO_INCREMENT column by the previous INSERT or UPDATE
 * statement.
 */
static VALUE rb_mysql_client_last_id(VALUE self) {
  GET_CLIENT(self);
  REQUIRE_CONNECTED(wrapper);
  return ULL2NUM(mysql_insert_id(wrapper->client));
}

/* call-seq:
 *    client.session_track
 *
 * Returns information about changes to the session state on the server.
 */
static VALUE rb_mysql_client_session_track(VALUE self, VALUE type) {
#ifdef CLIENT_SESSION_TRACK
  const char *data;
  size_t length;
  my_ulonglong retVal;
  GET_CLIENT(self);

  REQUIRE_CONNECTED(wrapper);
  retVal = mysql_session_track_get_first(wrapper->client, NUM2INT(type), &data, &length);
  if (retVal != 0) {
    return Qnil;
  }
  VALUE rbAry = rb_ary_new();
  VALUE rbFirst = rb_str_new(data, length);
  rb_ary_push(rbAry, rbFirst);
  while(mysql_session_track_get_next(wrapper->client, NUM2INT(type), &data, &length) == 0) {
    VALUE rbNext = rb_str_new(data, length);
    rb_ary_push(rbAry, rbNext);
  }
  return rbAry;
#else
  return Qnil;
#endif
}

/* call-seq:
 *    client.affected_rows
 *
 * returns the number of rows changed, deleted, or inserted by the last statement
 * if it was an UPDATE, DELETE, or INSERT.
 */
static VALUE rb_mysql_client_affected_rows(VALUE self) {
  uint64_t retVal;
  GET_CLIENT(self);

  REQUIRE_CONNECTED(wrapper);
  retVal = wrapper->affected_rows;
  if (retVal == (uint64_t)-1) {
    rb_raise_mysql2_error(wrapper);
  }
  return ULL2NUM(retVal);
}

/* call-seq:
 *    client.thread_id
 *
 * Returns the thread ID of the current connection.
 */
static VALUE rb_mysql_client_thread_id(VALUE self) {
  unsigned long retVal;
  GET_CLIENT(self);

  REQUIRE_CONNECTED(wrapper);
  retVal = mysql_thread_id(wrapper->client);
  return ULL2NUM(retVal);
}

static void *nogvl_select_db(void *ptr) {
  struct nogvl_select_db_args *args = ptr;

  if (mysql_select_db(args->mysql, args->db) == 0)
    return (void *)Qtrue;
  else
    return (void *)Qfalse;
}

/* call-seq:
 *    client.select_db(name)
 *
 * Causes the database specified by +name+ to become the default (current)
 * database on the connection specified by mysql.
 */
static VALUE rb_mysql_client_select_db(VALUE self, VALUE db)
{
  struct nogvl_select_db_args args;

  GET_CLIENT(self);
  REQUIRE_CONNECTED(wrapper);

  args.mysql = wrapper->client;
  args.db = StringValueCStr(db);

  if (rb_thread_call_without_gvl(nogvl_select_db, &args, RUBY_UBF_IO, 0) == Qfalse)
    rb_raise_mysql2_error(wrapper);

  return db;
}

static void *nogvl_ping(void *ptr) {
  MYSQL *client = ptr;

  return (void *)(mysql_ping(client) == 0 ? Qtrue : Qfalse);
}

/* call-seq:
 *    client.ping
 *
 * Checks whether the connection to the server is working. If the connection
 * has gone down and auto-reconnect is enabled an attempt to reconnect is made.
 * If the connection is down and auto-reconnect is disabled, ping returns an
 * error.
 */
static VALUE rb_mysql_client_ping(VALUE self) {
  GET_CLIENT(self);

  if (!CONNECTED(wrapper)) {
    return Qfalse;
  } else {
    return (VALUE)rb_thread_call_without_gvl(nogvl_ping, wrapper->client, RUBY_UBF_IO, 0);
  }
}

/* call-seq:
 *    client.set_server_option(value)
 *
 * Enables or disables an option for the connection.
 * Read https://dev.mysql.com/doc/refman/5.7/en/mysql-set-server-option.html
 * for more information.
 */
static VALUE rb_mysql_client_set_server_option(VALUE self, VALUE value) {
  GET_CLIENT(self);

  if (mysql_set_server_option(wrapper->client, NUM2INT(value)) == 0) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

/* call-seq:
 *    client.more_results?
 *
 * Returns true or false if there are more results to process.
 */
static VALUE rb_mysql_client_more_results(VALUE self)
{
  GET_CLIENT(self);
  if (mysql_more_results(wrapper->client) == 0)
    return Qfalse;
  else
    return Qtrue;
}

/* call-seq:
 *    client.next_result
 *
 * Fetch the next result set from the server.
 * Returns nothing.
 */
static VALUE rb_mysql_client_next_result(VALUE self)
{
    int ret;
    GET_CLIENT(self);
    ret = mysql_next_result(wrapper->client);
    if (ret > 0) {
      rb_raise_mysql2_error(wrapper);
      return Qfalse;
    } else if (ret == 0) {
      return Qtrue;
    } else {
      return Qfalse;
    }
}

/* call-seq:
 *    client.store_result
 *
 * Return the next result object from a query which
 * yielded multiple result sets.
 */
static VALUE rb_mysql_client_store_result(VALUE self)
{
  MYSQL_RES * result;
  VALUE resultObj;
  VALUE current;
  GET_CLIENT(self);

  result = (MYSQL_RES *)rb_thread_call_without_gvl(nogvl_store_result, wrapper, RUBY_UBF_IO, 0);

  if (result == NULL) {
    if (mysql_errno(wrapper->client) != 0) {
      rb_raise_mysql2_error(wrapper);
    }
    /* no data and no error, so query was not a SELECT */
    return Qnil;
  }

  // Duplicate the options hash and put the copy in the Result object
  current = rb_hash_dup(rb_ivar_get(self, intern_current_query_options));
  (void)RB_GC_GUARD(current);
  Check_Type(current, T_HASH);
  resultObj = rb_mysql_result_to_obj(self, wrapper->encoding, current, result, Qnil);

  return resultObj;
}

/* call-seq:
 *    client.encoding
 *
 * Returns the encoding set on the client.
 */
static VALUE rb_mysql_client_encoding(VALUE self) {
  GET_CLIENT(self);
  return wrapper->encoding;
}

/* call-seq:
 *    client.database
 *
 * Returns the currently selected database.
 *
 * The result may be stale if `session_track_schema` is disabled.  Read
 * https://dev.mysql.com/doc/refman/5.7/en/session-state-tracking.html for more
 * information.
 */
static VALUE rb_mysql_client_database(VALUE self) {
  GET_CLIENT(self);

  char *db = wrapper->client->db;
  if (!db) {
    return Qnil;
  }

  return rb_str_new_cstr(wrapper->client->db);
}

/* call-seq:
 *    client.automatic_close?
 *
 * @return [Boolean]
 */
static VALUE get_automatic_close(VALUE self) {
  GET_CLIENT(self);
  return wrapper->automatic_close ? Qtrue : Qfalse;
}

/* call-seq:
 *    client.automatic_close = false
 *
 * Set this to +false+ to leave the connection open after it is garbage
 * collected. To avoid "Aborted connection" errors on the server, explicitly
 * call +close+ when the connection is no longer needed.
 *
 * @see http://dev.mysql.com/doc/en/communication-errors.html
 */
static VALUE set_automatic_close(VALUE self, VALUE value) {
  GET_CLIENT(self);
  if (RTEST(value)) {
    wrapper->automatic_close = 1;
  } else {
#ifndef _WIN32
    wrapper->automatic_close = 0;
#else
    rb_warn("Connections are always closed by garbage collector on Windows");
#endif
  }
  return value;
}

/* call-seq:
 *    client.reconnect = true
 *
 * Enable or disable the automatic reconnect behavior of libmysql.
 * Read http://dev.mysql.com/doc/refman/5.5/en/auto-reconnect.html
 * for more information.
 */
static VALUE set_reconnect(VALUE self, VALUE value) {
  return _mysql_client_options(self, MYSQL_OPT_RECONNECT, value);
}

static VALUE set_local_infile(VALUE self, VALUE value) {
  return _mysql_client_options(self, MYSQL_OPT_LOCAL_INFILE, value);
}

static VALUE set_connect_timeout(VALUE self, VALUE value) {
  long int sec;
  Check_Type(value, T_FIXNUM);
  sec = FIX2INT(value);
  if (sec < 0) {
    rb_raise(cMysql2Error, "connect_timeout must be a positive integer, you passed %ld", sec);
  }
  return _mysql_client_options(self, MYSQL_OPT_CONNECT_TIMEOUT, value);
}

static VALUE set_read_timeout(VALUE self, VALUE value) {
  long int sec;
  Check_Type(value, T_FIXNUM);
  sec = FIX2INT(value);
  if (sec < 0) {
    rb_raise(cMysql2Error, "read_timeout must be a positive integer, you passed %ld", sec);
  }
  /* Set the instance variable here even though _mysql_client_options
     might not succeed, because the timeout is used in other ways
     elsewhere */
  rb_ivar_set(self, intern_read_timeout, value);
  return _mysql_client_options(self, MYSQL_OPT_READ_TIMEOUT, value);
}

static VALUE set_write_timeout(VALUE self, VALUE value) {
  long int sec;
  Check_Type(value, T_FIXNUM);
  sec = FIX2INT(value);
  if (sec < 0) {
    rb_raise(cMysql2Error, "write_timeout must be a positive integer, you passed %ld", sec);
  }
  return _mysql_client_options(self, MYSQL_OPT_WRITE_TIMEOUT, value);
}

static VALUE set_charset_name(VALUE self, VALUE value) {
  char *charset_name;
  const struct mysql2_mysql_enc_name_to_rb_map *mysql2rb;
  rb_encoding *enc;
  VALUE rb_enc;
  GET_CLIENT(self);

  Check_Type(value, T_STRING);
  charset_name = RSTRING_PTR(value);

  mysql2rb = mysql2_mysql_enc_name_to_rb(charset_name, (unsigned int)RSTRING_LEN(value));
  if (mysql2rb == NULL || mysql2rb->rb_name == NULL) {
    VALUE inspect = rb_inspect(value);
    rb_raise(cMysql2Error, "Unsupported charset: '%s'", RSTRING_PTR(inspect));
  } else {
    enc = rb_enc_find(mysql2rb->rb_name);
    rb_enc = rb_enc_from_encoding(enc);
    wrapper->encoding = rb_enc;
  }

  if (mysql_options(wrapper->client, MYSQL_SET_CHARSET_NAME, charset_name)) {
    /* TODO: warning - unable to set charset */
    rb_warn("%s\n", mysql_error(wrapper->client));
  }

  return value;
}

static VALUE set_ssl_options(VALUE self, VALUE key, VALUE cert, VALUE ca, VALUE capath, VALUE cipher) {
  GET_CLIENT(self);

#ifdef HAVE_MYSQL_SSL_SET
  mysql_ssl_set(wrapper->client,
      NIL_P(key)    ? NULL : StringValueCStr(key),
      NIL_P(cert)   ? NULL : StringValueCStr(cert),
      NIL_P(ca)     ? NULL : StringValueCStr(ca),
      NIL_P(capath) ? NULL : StringValueCStr(capath),
      NIL_P(cipher) ? NULL : StringValueCStr(cipher));
#else
  /* mysql 8.3 does not provide mysql_ssl_set */
  if (!NIL_P(key)) {
    mysql_options(wrapper->client, MYSQL_OPT_SSL_KEY, StringValueCStr(key));
  }
  if (!NIL_P(cert)) {
    mysql_options(wrapper->client, MYSQL_OPT_SSL_CERT, StringValueCStr(cert));
  }
  if (!NIL_P(ca)) {
    mysql_options(wrapper->client, MYSQL_OPT_SSL_CA, StringValueCStr(ca));
  }
  if (!NIL_P(capath)) {
    mysql_options(wrapper->client, MYSQL_OPT_SSL_CAPATH, StringValueCStr(capath));
  }
  if (!NIL_P(cipher)) {
    mysql_options(wrapper->client, MYSQL_OPT_SSL_CIPHER, StringValueCStr(cipher));
  }
#endif

  return self;
}

static VALUE set_secure_auth(VALUE self, VALUE value) {
/* This option was deprecated in MySQL 5.x and removed in MySQL 8.0 */
#ifdef MYSQL_SECURE_AUTH
  return _mysql_client_options(self, MYSQL_SECURE_AUTH, value);
#else
  return Qfalse;
#endif
}

static VALUE set_read_default_file(VALUE self, VALUE value) {
  return _mysql_client_options(self, MYSQL_READ_DEFAULT_FILE, value);
}

static VALUE set_read_default_group(VALUE self, VALUE value) {
  return _mysql_client_options(self, MYSQL_READ_DEFAULT_GROUP, value);
}

static VALUE set_init_command(VALUE self, VALUE value) {
  return _mysql_client_options(self, MYSQL_INIT_COMMAND, value);
}

static VALUE set_get_server_public_key(VALUE self, VALUE value) {
#ifdef HAVE_CONST_MYSQL_OPT_GET_SERVER_PUBLIC_KEY
  return _mysql_client_options(self, MYSQL_OPT_GET_SERVER_PUBLIC_KEY, value);
#else
  rb_raise(cMysql2Error, "get-server-public-key is not available, you may need a newer MySQL client library");
#endif
}

static VALUE set_default_auth(VALUE self, VALUE value) {
#ifdef HAVE_MYSQL_DEFAULT_AUTH
  return _mysql_client_options(self, MYSQL_DEFAULT_AUTH, value);
#else
  rb_raise(cMysql2Error, "pluggable authentication is not available, you may need a newer MySQL client library");
#endif
}

static VALUE set_enable_cleartext_plugin(VALUE self, VALUE value) {
#ifdef HAVE_CONST_MYSQL_ENABLE_CLEARTEXT_PLUGIN
  return _mysql_client_options(self, MYSQL_ENABLE_CLEARTEXT_PLUGIN, value);
#else
  rb_raise(cMysql2Error, "enable-cleartext-plugin is not available, you may need a newer MySQL client library");
#endif
}

static VALUE initialize_ext(VALUE self) {
  GET_CLIENT(self);

  if ((VALUE)rb_thread_call_without_gvl(nogvl_init, wrapper, RUBY_UBF_IO, 0) == Qfalse) {
    /* TODO: warning - not enough memory? */
    rb_raise_mysql2_error(wrapper);
  }

  wrapper->initialized = 1;
  return self;
}

/* call-seq: client.prepare # => Mysql2::Statement
 *
 * Create a new prepared statement.
 */
static VALUE rb_mysql_client_prepare_statement(VALUE self, VALUE sql) {
  GET_CLIENT(self);
  REQUIRE_CONNECTED(wrapper);

  return rb_mysql_stmt_new(self, sql);
}

void init_mysql2_client() {
#ifdef _WIN32
  /* verify the libmysql we're about to use was the version we were built against
     https://github.com/luislavena/mysql-gem/commit/a600a9c459597da0712f70f43736e24b484f8a99 */
  int i;
  int dots = 0;
  const char *lib = mysql_get_client_info();

  for (i = 0; lib[i] != 0 && MYSQL_LINK_VERSION[i] != 0; i++) {
    if (lib[i] == '.') {
      dots++;
              /* we only compare MAJOR and MINOR */
      if (dots == 2) break;
    }
    if (lib[i] != MYSQL_LINK_VERSION[i]) {
      rb_raise(rb_eRuntimeError, "Incorrect MySQL client library version! This gem was compiled for %s but the client library is %s.", MYSQL_LINK_VERSION, lib);
    }
  }
#endif

  /* Initializing mysql library, so different threads could call Client.new */
  /* without race condition in the library */
  if (mysql_library_init(0, NULL, NULL) != 0) {
    rb_raise(rb_eRuntimeError, "Could not initialize MySQL client library");
  }

#if 0
  mMysql2      = rb_define_module("Mysql2"); Teach RDoc about Mysql2 constant.
#endif
  cMysql2Client = rb_define_class_under(mMysql2, "Client", rb_cObject);
  rb_global_variable(&cMysql2Client);

  rb_define_alloc_func(cMysql2Client, allocate);

  rb_define_singleton_method(cMysql2Client, "escape", rb_mysql_client_escape, 1);
  rb_define_singleton_method(cMysql2Client, "info", rb_mysql_client_info, 0);

  rb_define_method(cMysql2Client, "close", rb_mysql_client_close, 0);
  rb_define_method(cMysql2Client, "closed?", rb_mysql_client_closed, 0);
  rb_define_method(cMysql2Client, "abandon_results!", rb_mysql_client_abandon_results, 0);
  rb_define_method(cMysql2Client, "escape", rb_mysql_client_real_escape, 1);
  rb_define_method(cMysql2Client, "server_info", rb_mysql_client_server_info, 0);
  rb_define_method(cMysql2Client, "socket", rb_mysql_client_socket, 0);
  rb_define_method(cMysql2Client, "async_result", rb_mysql_client_async_result, 0);
  rb_define_method(cMysql2Client, "last_id", rb_mysql_client_last_id, 0);
  rb_define_method(cMysql2Client, "affected_rows", rb_mysql_client_affected_rows, 0);
  rb_define_method(cMysql2Client, "prepare", rb_mysql_client_prepare_statement, 1);
  rb_define_method(cMysql2Client, "thread_id", rb_mysql_client_thread_id, 0);
  rb_define_method(cMysql2Client, "ping", rb_mysql_client_ping, 0);
  rb_define_method(cMysql2Client, "select_db", rb_mysql_client_select_db, 1);
  rb_define_method(cMysql2Client, "set_server_option", rb_mysql_client_set_server_option, 1);
  rb_define_method(cMysql2Client, "more_results?", rb_mysql_client_more_results, 0);
  rb_define_method(cMysql2Client, "next_result", rb_mysql_client_next_result, 0);
  rb_define_method(cMysql2Client, "store_result", rb_mysql_client_store_result, 0);
  rb_define_method(cMysql2Client, "automatic_close?", get_automatic_close, 0);
  rb_define_method(cMysql2Client, "automatic_close=", set_automatic_close, 1);
  rb_define_method(cMysql2Client, "reconnect=", set_reconnect, 1);
  rb_define_method(cMysql2Client, "warning_count", rb_mysql_client_warning_count, 0);
  rb_define_method(cMysql2Client, "query_info_string", rb_mysql_info, 0);
  rb_define_method(cMysql2Client, "ssl_cipher", rb_mysql_get_ssl_cipher, 0);
  rb_define_method(cMysql2Client, "encoding", rb_mysql_client_encoding, 0);
  rb_define_method(cMysql2Client, "session_track", rb_mysql_client_session_track, 1);
  rb_define_method(cMysql2Client, "database", rb_mysql_client_database, 0);

  rb_define_private_method(cMysql2Client, "connect_timeout=", set_connect_timeout, 1);
  rb_define_private_method(cMysql2Client, "read_timeout=", set_read_timeout, 1);
  rb_define_private_method(cMysql2Client, "write_timeout=", set_write_timeout, 1);
  rb_define_private_method(cMysql2Client, "local_infile=", set_local_infile, 1);
  rb_define_private_method(cMysql2Client, "charset_name=", set_charset_name, 1);
  rb_define_private_method(cMysql2Client, "secure_auth=", set_secure_auth, 1);
  rb_define_private_method(cMysql2Client, "default_file=", set_read_default_file, 1);
  rb_define_private_method(cMysql2Client, "default_group=", set_read_default_group, 1);
  rb_define_private_method(cMysql2Client, "init_command=", set_init_command, 1);
  rb_define_private_method(cMysql2Client, "get_server_public_key=", set_get_server_public_key, 1);
  rb_define_private_method(cMysql2Client, "default_auth=", set_default_auth, 1);
  rb_define_private_method(cMysql2Client, "ssl_set", set_ssl_options, 5);
  rb_define_private_method(cMysql2Client, "ssl_mode=", rb_set_ssl_mode_option, 1);
  rb_define_private_method(cMysql2Client, "enable_cleartext_plugin=", set_enable_cleartext_plugin, 1);
  rb_define_private_method(cMysql2Client, "initialize_ext", initialize_ext, 0);
  rb_define_private_method(cMysql2Client, "connect", rb_mysql_connect, 8);
  rb_define_private_method(cMysql2Client, "_query", rb_mysql_query, 2);

  sym_id              = ID2SYM(rb_intern("id"));
  sym_version         = ID2SYM(rb_intern("version"));
  sym_header_version  = ID2SYM(rb_intern("header_version"));
  sym_async           = ID2SYM(rb_intern("async"));
  sym_symbolize_keys  = ID2SYM(rb_intern("symbolize_keys"));
  sym_as              = ID2SYM(rb_intern("as"));
  sym_array           = ID2SYM(rb_intern("array"));
  sym_stream          = ID2SYM(rb_intern("stream"));

  sym_no_good_index_used = ID2SYM(rb_intern("no_good_index_used"));
  sym_no_index_used      = ID2SYM(rb_intern("no_index_used"));
  sym_query_was_slow     = ID2SYM(rb_intern("query_was_slow"));

  intern_brackets = rb_intern("[]");
  intern_merge = rb_intern("merge");
  intern_merge_bang = rb_intern("merge!");
  intern_new_with_args = rb_intern("new_with_args");
  intern_current_query_options = rb_intern("@current_query_options");
  intern_read_timeout = rb_intern("@read_timeout");

#ifdef CLIENT_LONG_PASSWORD
  rb_const_set(cMysql2Client, rb_intern("LONG_PASSWORD"),
      LONG2NUM(CLIENT_LONG_PASSWORD));
#else
  /* HACK because MariaDB 10.2 no longer defines this constant,
   * but we're using it in our default connection flags. */
  rb_const_set(cMysql2Client, rb_intern("LONG_PASSWORD"), INT2NUM(0));
#endif

#ifdef CLIENT_FOUND_ROWS
  rb_const_set(cMysql2Client, rb_intern("FOUND_ROWS"),
      LONG2NUM(CLIENT_FOUND_ROWS));
#endif

#ifdef CLIENT_LONG_FLAG
  rb_const_set(cMysql2Client, rb_intern("LONG_FLAG"),
      LONG2NUM(CLIENT_LONG_FLAG));
#endif

#ifdef CLIENT_CONNECT_WITH_DB
  rb_const_set(cMysql2Client, rb_intern("CONNECT_WITH_DB"),
      LONG2NUM(CLIENT_CONNECT_WITH_DB));
#endif

#ifdef CLIENT_NO_SCHEMA
  rb_const_set(cMysql2Client, rb_intern("NO_SCHEMA"),
      LONG2NUM(CLIENT_NO_SCHEMA));
#endif

#ifdef CLIENT_COMPRESS
  rb_const_set(cMysql2Client, rb_intern("COMPRESS"), LONG2NUM(CLIENT_COMPRESS));
#endif

#ifdef CLIENT_ODBC
  rb_const_set(cMysql2Client, rb_intern("ODBC"), LONG2NUM(CLIENT_ODBC));
#endif

#ifdef CLIENT_LOCAL_FILES
  rb_const_set(cMysql2Client, rb_intern("LOCAL_FILES"),
      LONG2NUM(CLIENT_LOCAL_FILES));
#endif

#ifdef CLIENT_IGNORE_SPACE
  rb_const_set(cMysql2Client, rb_intern("IGNORE_SPACE"),
      LONG2NUM(CLIENT_IGNORE_SPACE));
#endif

#ifdef CLIENT_PROTOCOL_41
  rb_const_set(cMysql2Client, rb_intern("PROTOCOL_41"),
      LONG2NUM(CLIENT_PROTOCOL_41));
#endif

#ifdef CLIENT_INTERACTIVE
  rb_const_set(cMysql2Client, rb_intern("INTERACTIVE"),
      LONG2NUM(CLIENT_INTERACTIVE));
#endif

#ifdef CLIENT_SSL
  rb_const_set(cMysql2Client, rb_intern("SSL"), LONG2NUM(CLIENT_SSL));
#endif

#ifdef CLIENT_IGNORE_SIGPIPE
  rb_const_set(cMysql2Client, rb_intern("IGNORE_SIGPIPE"),
      LONG2NUM(CLIENT_IGNORE_SIGPIPE));
#endif

#ifdef CLIENT_TRANSACTIONS
  rb_const_set(cMysql2Client, rb_intern("TRANSACTIONS"),
      LONG2NUM(CLIENT_TRANSACTIONS));
#endif

#ifdef CLIENT_RESERVED
  rb_const_set(cMysql2Client, rb_intern("RESERVED"), LONG2NUM(CLIENT_RESERVED));
#endif

#ifdef CLIENT_SECURE_CONNECTION
  rb_const_set(cMysql2Client, rb_intern("SECURE_CONNECTION"),
      LONG2NUM(CLIENT_SECURE_CONNECTION));
#else
  /* HACK because MySQL5.7 no longer defines this constant,
   * but we're using it in our default connection flags. */
  rb_const_set(cMysql2Client, rb_intern("SECURE_CONNECTION"), LONG2NUM(0));
#endif

#ifdef HAVE_CONST_MYSQL_OPTION_MULTI_STATEMENTS_ON
  rb_const_set(cMysql2Client, rb_intern("OPTION_MULTI_STATEMENTS_ON"),
      LONG2NUM(MYSQL_OPTION_MULTI_STATEMENTS_ON));
#endif

#ifdef HAVE_CONST_MYSQL_OPTION_MULTI_STATEMENTS_OFF
  rb_const_set(cMysql2Client, rb_intern("OPTION_MULTI_STATEMENTS_OFF"),
      LONG2NUM(MYSQL_OPTION_MULTI_STATEMENTS_OFF));
#endif

#ifdef CLIENT_MULTI_STATEMENTS
  rb_const_set(cMysql2Client, rb_intern("MULTI_STATEMENTS"),
      LONG2NUM(CLIENT_MULTI_STATEMENTS));
#endif

#ifdef CLIENT_PS_MULTI_RESULTS
  rb_const_set(cMysql2Client, rb_intern("PS_MULTI_RESULTS"),
      LONG2NUM(CLIENT_PS_MULTI_RESULTS));
#endif

#ifdef CLIENT_SSL_VERIFY_SERVER_CERT
  rb_const_set(cMysql2Client, rb_intern("SSL_VERIFY_SERVER_CERT"),
      LONG2NUM(CLIENT_SSL_VERIFY_SERVER_CERT));
#endif

#ifdef CLIENT_REMEMBER_OPTIONS
  rb_const_set(cMysql2Client, rb_intern("REMEMBER_OPTIONS"),
      LONG2NUM(CLIENT_REMEMBER_OPTIONS));
#endif

#ifdef CLIENT_ALL_FLAGS
  rb_const_set(cMysql2Client, rb_intern("ALL_FLAGS"),
      LONG2NUM(CLIENT_ALL_FLAGS));
#endif

#ifdef CLIENT_BASIC_FLAGS
  rb_const_set(cMysql2Client, rb_intern("BASIC_FLAGS"),
      LONG2NUM(CLIENT_BASIC_FLAGS));
#endif

#ifdef CLIENT_CONNECT_ATTRS
  rb_const_set(cMysql2Client, rb_intern("CONNECT_ATTRS"),
      LONG2NUM(CLIENT_CONNECT_ATTRS));
#else
  /* HACK because MySQL 5.5 and earlier don't define this constant,
   * but we're using it in our default connection flags. */
  rb_const_set(cMysql2Client, rb_intern("CONNECT_ATTRS"),
      INT2NUM(0));
#endif

#ifdef CLIENT_SESSION_TRACK
  rb_const_set(cMysql2Client, rb_intern("SESSION_TRACK"), INT2NUM(CLIENT_SESSION_TRACK));
  /* From mysql_com.h -- but stable from at least 5.7.4 through 8.0.20 */
  rb_const_set(cMysql2Client, rb_intern("SESSION_TRACK_SYSTEM_VARIABLES"), INT2NUM(SESSION_TRACK_SYSTEM_VARIABLES));
  rb_const_set(cMysql2Client, rb_intern("SESSION_TRACK_SCHEMA"), INT2NUM(SESSION_TRACK_SCHEMA));
  rb_const_set(cMysql2Client, rb_intern("SESSION_TRACK_STATE_CHANGE"), INT2NUM(SESSION_TRACK_STATE_CHANGE));
  rb_const_set(cMysql2Client, rb_intern("SESSION_TRACK_GTIDS"), INT2NUM(SESSION_TRACK_GTIDS));
  rb_const_set(cMysql2Client, rb_intern("SESSION_TRACK_TRANSACTION_CHARACTERISTICS"), INT2NUM(SESSION_TRACK_TRANSACTION_CHARACTERISTICS));
  rb_const_set(cMysql2Client, rb_intern("SESSION_TRACK_TRANSACTION_STATE"), INT2NUM(SESSION_TRACK_TRANSACTION_STATE));
#endif

#if defined(FULL_SSL_MODE_SUPPORT) // MySQL 5.6.36 and MySQL 5.7.11 and above
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_DISABLED"), INT2NUM(SSL_MODE_DISABLED));
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_PREFERRED"), INT2NUM(SSL_MODE_PREFERRED));
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_REQUIRED"), INT2NUM(SSL_MODE_REQUIRED));
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_VERIFY_CA"), INT2NUM(SSL_MODE_VERIFY_CA));
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_VERIFY_IDENTITY"), INT2NUM(SSL_MODE_VERIFY_IDENTITY));
#else
#ifdef HAVE_CONST_MYSQL_OPT_SSL_VERIFY_SERVER_CERT // MySQL 5.7.3 - 5.7.10 & MariaDB 10.x and later
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_VERIFY_IDENTITY"), INT2NUM(SSL_MODE_VERIFY_IDENTITY));
#endif
#ifdef HAVE_CONST_MYSQL_OPT_SSL_ENFORCE // MySQL 5.7.3 - 5.7.10 & MariaDB 10.x and later
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_DISABLED"), INT2NUM(SSL_MODE_DISABLED));
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_REQUIRED"), INT2NUM(SSL_MODE_REQUIRED));
#endif
#endif

#ifndef HAVE_CONST_SSL_MODE_DISABLED
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_DISABLED"), INT2NUM(0));
#endif
#ifndef HAVE_CONST_SSL_MODE_PREFERRED
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_PREFERRED"), INT2NUM(0));
#endif
#ifndef HAVE_CONST_SSL_MODE_REQUIRED
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_REQUIRED"), INT2NUM(0));
#endif
#ifndef HAVE_CONST_SSL_MODE_VERIFY_CA
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_VERIFY_CA"), INT2NUM(0));
#endif
#ifndef HAVE_CONST_SSL_MODE_VERIFY_IDENTITY
  rb_const_set(cMysql2Client, rb_intern("SSL_MODE_VERIFY_IDENTITY"), INT2NUM(0));
#endif
}

#define flag_to_bool(f) ((client->server_status & f) ? Qtrue : Qfalse)

void rb_mysql_set_server_query_flags(MYSQL *client, VALUE result) {
  VALUE server_flags = rb_hash_new();

#ifdef HAVE_CONST_SERVER_QUERY_NO_GOOD_INDEX_USED
  rb_hash_aset(server_flags, sym_no_good_index_used, flag_to_bool(SERVER_QUERY_NO_GOOD_INDEX_USED));
#else
  rb_hash_aset(server_flags, sym_no_good_index_used, Qnil);
#endif

#ifdef HAVE_CONST_SERVER_QUERY_NO_INDEX_USED
  rb_hash_aset(server_flags, sym_no_index_used, flag_to_bool(SERVER_QUERY_NO_INDEX_USED));
#else
  rb_hash_aset(server_flags, sym_no_index_used, Qnil);
#endif

#ifdef HAVE_CONST_SERVER_QUERY_WAS_SLOW
  rb_hash_aset(server_flags, sym_query_was_slow, flag_to_bool(SERVER_QUERY_WAS_SLOW));
#else
  rb_hash_aset(server_flags, sym_query_was_slow, Qnil);
#endif

  rb_iv_set(result, "@server_flags", server_flags);
}
