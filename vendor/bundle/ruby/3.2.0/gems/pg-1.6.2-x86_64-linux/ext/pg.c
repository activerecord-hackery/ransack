/*
 * pg.c - Toplevel extension
 * $Id$
 *
 * Author/s:
 *
 * - Jeff Davis <ruby-pg@j-davis.com>
 * - Guy Decoux (ts) <decoux@moulon.inra.fr>
 * - Michael Granger <ged@FaerieMUD.org>
 * - Lars Kanis <lars@greiz-reinsdorf.de>
 * - Dave Lee
 * - Eiji Matsumoto <usagi@ruby.club.or.jp>
 * - Yukihiro Matsumoto <matz@ruby-lang.org>
 * - Noboru Saitou <noborus@netlab.jp>
 *
 * See Contributors.rdoc for the many additional fine people that have contributed
 * to this library over the years.
 *
 * Copyright (c) 1997-2019 by the authors.
 *
 * You may redistribute this software under the same terms as Ruby itself; see
 * https://www.ruby-lang.org/en/about/license.txt or the BSDL file in the source
 * for details.
 *
 * Portions of the code are from the PostgreSQL project, and are distributed
 * under the terms of the PostgreSQL license, included in the file "POSTGRES".
 *
 * Portions copyright LAIKA, Inc.
 *
 *
 * The following functions are part of libpq, but not available from ruby-pg,
 * because they are deprecated, obsolete, or generally not useful:
 *
 * - PQfreemem -- unnecessary: copied to ruby object, then freed. Ruby object's
 *                memory is freed when it is garbage collected.
 * - PQprint -- not very useful
 * - PQsetdb -- not very useful
 * - PQoidStatus -- deprecated, use PQoidValue
 * - PQrequestCancel -- deprecated, use PQcancel
 * - PQfn -- use a prepared statement instead
 * - PQgetline -- deprecated, use PQgetCopyData
 * - PQgetlineAsync -- deprecated, use PQgetCopyData
 * - PQputline -- deprecated, use PQputCopyData
 * - PQputnbytes -- deprecated, use PQputCopyData
 * - PQendcopy -- deprecated, use PQputCopyEnd
 */

#include "pg.h"

int pg_skip_deprecation_warning;
VALUE rb_mPG;
VALUE rb_mPGconstants;


/*
 * Document-class: PG::Error
 *
 * This is the exception class raised when an error is returned from
 * a libpq API call.
 *
 * The attributes +connection+ and +result+ are set to the connection
 * object and result set object, respectively.
 *
 * If the connection object or result set object is not available from
 * the context in which the error was encountered, it is +nil+.
 */

/*
 * M17n functions
 */

/**
 * The mapping from canonical encoding names in PostgreSQL to ones in Ruby.
 */
const char * const (pg_enc_pg2ruby_mapping[][2]) = {
	{"UTF8",          "UTF-8"       },
	{"BIG5",          "Big5"        },
	{"EUC_CN",        "GB2312"      },
	{"EUC_JP",        "EUC-JP"      },
	{"EUC_JIS_2004",  "EUC-JP"      },
	{"EUC_KR",        "EUC-KR"      },
	{"EUC_TW",        "EUC-TW"      },
	{"GB18030",       "GB18030"     },
	{"GBK",           "GBK"         },
	{"ISO_8859_5",    "ISO-8859-5"  },
	{"ISO_8859_6",    "ISO-8859-6"  },
	{"ISO_8859_7",    "ISO-8859-7"  },
	{"ISO_8859_8",    "ISO-8859-8"  },
	/* {"JOHAB",         "JOHAB"       }, dummy */
	{"KOI8",          "KOI8-R"      },
	{"KOI8R",         "KOI8-R"      },
	{"KOI8U",         "KOI8-U"      },
	{"LATIN1",        "ISO-8859-1"  },
	{"LATIN2",        "ISO-8859-2"  },
	{"LATIN3",        "ISO-8859-3"  },
	{"LATIN4",        "ISO-8859-4"  },
	{"LATIN5",        "ISO-8859-9"  },
	{"LATIN6",        "ISO-8859-10" },
	{"LATIN7",        "ISO-8859-13" },
	{"LATIN8",        "ISO-8859-14" },
	{"LATIN9",        "ISO-8859-15" },
	{"LATIN10",       "ISO-8859-16" },
	{"MULE_INTERNAL", "Emacs-Mule"  },
	{"SJIS",          "Windows-31J" },
	{"SHIFT_JIS_2004","Windows-31J" },
	/* {"SQL_ASCII",     NULL          },  special case*/
	{"UHC",           "CP949"       },
	{"WIN866",        "IBM866"      },
	{"WIN874",        "Windows-874" },
	{"WIN1250",       "Windows-1250"},
	{"WIN1251",       "Windows-1251"},
	{"WIN1252",       "Windows-1252"},
	{"WIN1253",       "Windows-1253"},
	{"WIN1254",       "Windows-1254"},
	{"WIN1255",       "Windows-1255"},
	{"WIN1256",       "Windows-1256"},
	{"WIN1257",       "Windows-1257"},
	{"WIN1258",       "Windows-1258"}
};


/*
 * Return the given PostgreSQL encoding ID as an rb_encoding.
 *
 * - returns NULL if the client encoding is 'SQL_ASCII'.
 * - returns ASCII-8BIT if the client encoding is unknown.
 */
static rb_encoding *
pg_get_pg_encoding_as_rb_encoding( int enc_id )
{
	const char *name = pg_encoding_to_char( enc_id );
	return pg_get_pg_encname_as_rb_encoding( name );
}

/*
 * Return the given PostgreSQL encoding name as an rb_encoding.
 */
rb_encoding *
pg_get_pg_encname_as_rb_encoding( const char *pg_encname )
{
	size_t i;

	/* Trying looking it up in the conversion table */
	for ( i = 0; i < sizeof(pg_enc_pg2ruby_mapping)/sizeof(pg_enc_pg2ruby_mapping[0]); ++i ) {
		if ( strcmp(pg_encname, pg_enc_pg2ruby_mapping[i][0]) == 0 )
			return rb_enc_find( pg_enc_pg2ruby_mapping[i][1] );
	}

	/* Fallthrough to ASCII-8BIT */
	return rb_ascii8bit_encoding();
}

/*
 * Get the client encoding of the specified connection handle and return it as a rb_encoding.
 */
rb_encoding *
pg_conn_enc_get( PGconn *conn )
{
	int enc_id = PQclientEncoding( conn );
	return pg_get_pg_encoding_as_rb_encoding( enc_id );
}


/*
 * Returns the given rb_encoding as the equivalent PostgreSQL encoding string.
 */
const char *
pg_get_rb_encoding_as_pg_encoding( rb_encoding *enc )
{
	const char *rb_encname = rb_enc_name( enc );
	const char *encname = NULL;
	size_t i;

	for (i = 0; i < sizeof(pg_enc_pg2ruby_mapping)/sizeof(pg_enc_pg2ruby_mapping[0]); ++i) {
		if (strcmp(rb_encname, pg_enc_pg2ruby_mapping[i][1]) == 0) {
			encname = pg_enc_pg2ruby_mapping[i][0];
		}
	}

	if ( !encname ) encname = "SQL_ASCII";

	return encname;
}


/*
 * Ensures that the given string has enough capacity to take expand_len
 * more data bytes. The new data part of the String is not initialized.
 *
 * current_out must be a pointer within the data part of the String object.
 * This pointer is returned and possibly adjusted, because the location of the data
 * part of the String can change through this function.
 *
 * PG_RB_STR_ENSURE_CAPA can be used to do fast inline checks of the remaining capacity.
 * end_capa it is then set to the first byte after the currently reserved memory,
 * if not NULL.
 *
 * Before the String can be used with other string functions or returned to Ruby space,
 * the string length has to be set with rb_str_set_len().
 *
 * Usage example:
 *
 *   VALUE string;
 *   char *current_out, *end_capa;
 *   PG_RB_STR_NEW( string, current_out, end_capa );
 *   while( data_is_going_to_be_processed ){
 *     PG_RB_STR_ENSURE_CAPA( string, 2, current_out, end_capa );
 *     *current_out++ = databyte1;
 *     *current_out++ = databyte2;
 *   }
 *   rb_str_set_len( string, current_out - RSTRING_PTR(string) );
 *
 */
char *
pg_rb_str_ensure_capa( VALUE str, long expand_len, char *curr_ptr, char **end_ptr )
{
	long curr_len = curr_ptr - RSTRING_PTR(str);
	long curr_capa = rb_str_capacity( str );
	if( curr_capa < curr_len + expand_len ){
		rb_str_set_len( str, curr_len );
		rb_str_modify_expand( str, (curr_len + expand_len) * 2 - curr_capa );
		curr_ptr = RSTRING_PTR(str) + curr_len;
	}
	if( end_ptr )
		*end_ptr = RSTRING_PTR(str) + rb_str_capacity( str );
	return curr_ptr;
}


/**************************************************************************
 * Module Methods
 **************************************************************************/

/*
 * call-seq:
 *   PG.library_version -> Integer
 *
 * Get the version of the libpq library in use. The number is formed by
 * converting the major, minor, and revision numbers into two-decimal-
 * digit numbers and appending them together.
 * For example, version 7.4.2 will be returned as 70402, and version
 * 8.1 will be returned as 80100 (leading zeroes are not shown). Zero
 * is returned if the connection is bad.
 */
static VALUE
pg_s_library_version(VALUE self)
{
	UNUSED( self );
	return INT2NUM(PQlibVersion());
}


/*
 * call-seq:
 *    PG.isthreadsafe            -> Boolean
 *    PG.is_threadsafe?          -> Boolean
 *    PG.threadsafe?             -> Boolean
 *
 * Returns +true+ if libpq is thread-safe, +false+ otherwise.
 */
static VALUE
pg_s_threadsafe_p(VALUE self)
{
	UNUSED( self );
	return PQisthreadsafe() ? Qtrue : Qfalse;
}

static int
pg_to_bool_int(VALUE value)
{
	switch( TYPE(value) ){
		case T_FALSE:
			return 0;
		case T_TRUE:
			return 1;
		default:
			return NUM2INT(value);
	}
}

/*
 * call-seq:
 *    PG.init_openssl(do_ssl, do_crypto)  -> nil
 *
 * Allows applications to select which security libraries to initialize.
 *
 * If your application initializes libssl and/or libcrypto libraries and libpq is
 * built with SSL support, you should call PG.init_openssl() to tell libpq that the
 * libssl and/or libcrypto libraries have been initialized by your application,
 * so that libpq will not also initialize those libraries.
 *
 * When do_ssl is +true+, libpq will initialize the OpenSSL library before first
 * opening a database connection. When do_crypto is +true+, the libcrypto library
 * will be initialized. By default (if PG.init_openssl() is not called), both libraries
 * are initialized. When SSL support is not compiled in, this function is present but does nothing.
 *
 * If your application uses and initializes either OpenSSL or its underlying libcrypto library,
 * you must call this function with +false+ for the appropriate parameter(s) before first opening
 * a database connection. Also be sure that you have done that initialization before opening a
 * database connection.
 *
 */
static VALUE
pg_s_init_openssl(VALUE self, VALUE do_ssl, VALUE do_crypto)
{
	UNUSED( self );
	PQinitOpenSSL(pg_to_bool_int(do_ssl), pg_to_bool_int(do_crypto));
	return Qnil;
}


/*
 * call-seq:
 *    PG.init_ssl(do_ssl)  -> nil
 *
 * Allows applications to select which security libraries to initialize.
 *
 * This function is equivalent to <tt>PG.init_openssl(do_ssl, do_ssl)</tt> . It is sufficient for
 * applications that initialize both or neither of OpenSSL and libcrypto.
 */
static VALUE
pg_s_init_ssl(VALUE self, VALUE do_ssl)
{
	UNUSED( self );
	PQinitSSL(pg_to_bool_int(do_ssl));
	return Qnil;
}


/**************************************************************************
 * Initializer
 **************************************************************************/

void
Init_pg_ext(void)
{

#ifdef HAVE_RB_EXT_RACTOR_SAFE
	rb_ext_ractor_safe(PQisthreadsafe());
#endif

	if( RTEST(rb_eval_string("ENV['PG_SKIP_DEPRECATION_WARNING']")) ){
		/* Set all bits to disable all deprecation warnings. */
		pg_skip_deprecation_warning = 0xFFFF;
	} else {
		pg_skip_deprecation_warning = 0;
	}

	rb_mPG = rb_define_module( "PG" );
	rb_mPGconstants = rb_define_module_under( rb_mPG, "Constants" );

	/*************************
	 *  PG module methods
	 *************************/
	rb_define_singleton_method( rb_mPG, "library_version", pg_s_library_version, 0 );
	rb_define_singleton_method( rb_mPG, "isthreadsafe", pg_s_threadsafe_p, 0 );
	SINGLETON_ALIAS( rb_mPG, "is_threadsafe?", "isthreadsafe" );
	SINGLETON_ALIAS( rb_mPG, "threadsafe?", "isthreadsafe" );

	rb_define_singleton_method( rb_mPG, "init_openssl", pg_s_init_openssl, 2 );
	rb_define_singleton_method( rb_mPG, "init_ssl", pg_s_init_ssl, 1 );


	/******     PG::Connection CLASS CONSTANTS: Connection Status     ******/

	/* Connection succeeded */
	rb_define_const(rb_mPGconstants, "CONNECTION_OK", INT2FIX(CONNECTION_OK));
	/* Connection failed */
	rb_define_const(rb_mPGconstants, "CONNECTION_BAD", INT2FIX(CONNECTION_BAD));

	/******     PG::Connection CLASS CONSTANTS: Nonblocking connection status     ******/

	/* Waiting for connection to be made. */
	rb_define_const(rb_mPGconstants, "CONNECTION_STARTED", INT2FIX(CONNECTION_STARTED));
	/* Connection OK; waiting to send. */
	rb_define_const(rb_mPGconstants, "CONNECTION_MADE", INT2FIX(CONNECTION_MADE));
	/* Waiting for a response from the server. */
	rb_define_const(rb_mPGconstants, "CONNECTION_AWAITING_RESPONSE", INT2FIX(CONNECTION_AWAITING_RESPONSE));
	/* Received authentication; waiting for backend startup. */
	rb_define_const(rb_mPGconstants, "CONNECTION_AUTH_OK", INT2FIX(CONNECTION_AUTH_OK));
	/* This state is no longer used. */
	rb_define_const(rb_mPGconstants, "CONNECTION_SETENV", INT2FIX(CONNECTION_SETENV));
	/* Negotiating SSL encryption. */
	rb_define_const(rb_mPGconstants, "CONNECTION_SSL_STARTUP", INT2FIX(CONNECTION_SSL_STARTUP));
	/* Internal state - PG.connect() needed. */
	rb_define_const(rb_mPGconstants, "CONNECTION_NEEDED", INT2FIX(CONNECTION_NEEDED));
#if PG_MAJORVERSION_NUM >= 10
	/* Checking if session is read-write. Available since PostgreSQL-10. */
	rb_define_const(rb_mPGconstants, "CONNECTION_CHECK_WRITABLE", INT2FIX(CONNECTION_CHECK_WRITABLE));
#endif
#if PG_MAJORVERSION_NUM >= 10
	/* Consuming any extra messages. Available since PostgreSQL-10. */
	rb_define_const(rb_mPGconstants, "CONNECTION_CONSUME", INT2FIX(CONNECTION_CONSUME));
#endif
#if PG_MAJORVERSION_NUM >= 12
	/* Negotiating GSSAPI. Available since PostgreSQL-12. */
	rb_define_const(rb_mPGconstants, "CONNECTION_GSS_STARTUP", INT2FIX(CONNECTION_GSS_STARTUP));
#endif
#if PG_MAJORVERSION_NUM >= 13
	/* Checking target server properties. Available since PostgreSQL-13. */
	rb_define_const(rb_mPGconstants, "CONNECTION_CHECK_TARGET", INT2FIX(CONNECTION_CHECK_TARGET));
#endif
#if PG_MAJORVERSION_NUM >= 14
	/* Checking if server is in standby mode. Available since PostgreSQL-14. */
	rb_define_const(rb_mPGconstants, "CONNECTION_CHECK_STANDBY", INT2FIX(CONNECTION_CHECK_STANDBY));
#endif
#if PG_MAJORVERSION_NUM >= 17
	/* Waiting for connection attempt to be started. Available since PostgreSQL-17. */
	rb_define_const(rb_mPGconstants, "CONNECTION_ALLOCATED", INT2FIX(CONNECTION_ALLOCATED));
#endif

	/******     PG::Connection CLASS CONSTANTS: Nonblocking connection polling status     ******/

	/* Async connection is waiting to read */
	rb_define_const(rb_mPGconstants, "PGRES_POLLING_READING", INT2FIX(PGRES_POLLING_READING));
	/* Async connection is waiting to write */
	rb_define_const(rb_mPGconstants, "PGRES_POLLING_WRITING", INT2FIX(PGRES_POLLING_WRITING));
	/* Async connection failed or was reset */
	rb_define_const(rb_mPGconstants, "PGRES_POLLING_FAILED", INT2FIX(PGRES_POLLING_FAILED));
	/* Async connection succeeded */
	rb_define_const(rb_mPGconstants, "PGRES_POLLING_OK", INT2FIX(PGRES_POLLING_OK));

	/******     PG::Connection CLASS CONSTANTS: Transaction Status     ******/

	/* Transaction is currently idle ( Connection#transaction_status ) */
	rb_define_const(rb_mPGconstants, "PQTRANS_IDLE", INT2FIX(PQTRANS_IDLE));
	/* Transaction is currently active; query has been sent to the server, but not yet completed. ( Connection#transaction_status ) */
	rb_define_const(rb_mPGconstants, "PQTRANS_ACTIVE", INT2FIX(PQTRANS_ACTIVE));
	/* Transaction is currently idle, in a valid transaction block ( Connection#transaction_status ) */
	rb_define_const(rb_mPGconstants, "PQTRANS_INTRANS", INT2FIX(PQTRANS_INTRANS));
	/* Transaction is currently idle, in a failed transaction block ( Connection#transaction_status ) */
	rb_define_const(rb_mPGconstants, "PQTRANS_INERROR", INT2FIX(PQTRANS_INERROR));
	/* Transaction's connection is bad ( Connection#transaction_status ) */
	rb_define_const(rb_mPGconstants, "PQTRANS_UNKNOWN", INT2FIX(PQTRANS_UNKNOWN));

	/******     PG::Connection CLASS CONSTANTS: Error Verbosity     ******/

	/* Error verbosity level ( Connection#set_error_verbosity ).
	 * In TERSE mode, returned messages include severity, primary text, and position only; this will normally fit on a single line. */
	rb_define_const(rb_mPGconstants, "PQERRORS_TERSE", INT2FIX(PQERRORS_TERSE));
	/* Error verbosity level ( Connection#set_error_verbosity ).
	 * The DEFAULT mode produces messages that include the above plus any detail, hint, or context fields (these might span multiple lines). */
	rb_define_const(rb_mPGconstants, "PQERRORS_DEFAULT", INT2FIX(PQERRORS_DEFAULT));
	/* Error verbosity level ( Connection#set_error_verbosity ).
	 * The VERBOSE mode includes all available fields. */
	rb_define_const(rb_mPGconstants, "PQERRORS_VERBOSE", INT2FIX(PQERRORS_VERBOSE));

/* PQERRORS_SQLSTATE was introduced in PG-12 together with PQresultMemorySize() */
#ifdef HAVE_PQRESULTMEMORYSIZE
	/* Error verbosity level ( Connection#set_error_verbosity ).
	 * The SQLSTATE mode includes only the error severity and the SQLSTATE error code, if one is available (if not, the output is like TERSE mode).
	 *
	 * Available since PostgreSQL-12.
	 */
	rb_define_const(rb_mPGconstants, "PQERRORS_SQLSTATE", INT2FIX(PQERRORS_SQLSTATE));
#endif

	/* See Connection#set_error_context_visibility */
	rb_define_const(rb_mPGconstants, "PQSHOW_CONTEXT_NEVER", INT2FIX(PQSHOW_CONTEXT_NEVER));
	/* See Connection#set_error_context_visibility */
	rb_define_const(rb_mPGconstants, "PQSHOW_CONTEXT_ERRORS", INT2FIX(PQSHOW_CONTEXT_ERRORS));
	/* See Connection#set_error_context_visibility */
	rb_define_const(rb_mPGconstants, "PQSHOW_CONTEXT_ALWAYS", INT2FIX(PQSHOW_CONTEXT_ALWAYS));

	/******     PG::Connection CLASS CONSTANTS: Check Server Status ******/

	/* Server is accepting connections. */
	rb_define_const(rb_mPGconstants, "PQPING_OK", INT2FIX(PQPING_OK));
	/* Server is alive but rejecting connections. */
	rb_define_const(rb_mPGconstants, "PQPING_REJECT", INT2FIX(PQPING_REJECT));
	/* Could not establish connection. */
	rb_define_const(rb_mPGconstants, "PQPING_NO_RESPONSE", INT2FIX(PQPING_NO_RESPONSE));
	/* Connection not attempted (bad params). */
	rb_define_const(rb_mPGconstants, "PQPING_NO_ATTEMPT", INT2FIX(PQPING_NO_ATTEMPT));

	/******     PG::Connection CLASS CONSTANTS: Large Objects     ******/

	/* Flag for Connection#lo_creat, Connection#lo_open -- open for writing */
	rb_define_const(rb_mPGconstants, "INV_WRITE", INT2FIX(INV_WRITE));
	/* Flag for Connection#lo_creat, Connection#lo_open -- open for reading */
	rb_define_const(rb_mPGconstants, "INV_READ", INT2FIX(INV_READ));
	/* Flag for Connection#lo_lseek -- seek from object start */
	rb_define_const(rb_mPGconstants, "SEEK_SET", INT2FIX(SEEK_SET));
	/* Flag for Connection#lo_lseek -- seek from current position */
	rb_define_const(rb_mPGconstants, "SEEK_CUR", INT2FIX(SEEK_CUR));
	/* Flag for Connection#lo_lseek -- seek from object end */
	rb_define_const(rb_mPGconstants, "SEEK_END", INT2FIX(SEEK_END));

	/******     PG::Result CONSTANTS: result status      ******/

	/* Result#result_status constant - The string sent to the server was empty. */
	rb_define_const(rb_mPGconstants, "PGRES_EMPTY_QUERY", INT2FIX(PGRES_EMPTY_QUERY));
	/* Result#result_status constant - Successful completion of a command returning no data. */
	rb_define_const(rb_mPGconstants, "PGRES_COMMAND_OK", INT2FIX(PGRES_COMMAND_OK));
	/* Result#result_status constant - Successful completion of a command returning data (such as a SELECT or SHOW). */
	rb_define_const(rb_mPGconstants, "PGRES_TUPLES_OK", INT2FIX(PGRES_TUPLES_OK));
	/* Result#result_status constant - Copy Out (from server) data transfer started. */
	rb_define_const(rb_mPGconstants, "PGRES_COPY_OUT", INT2FIX(PGRES_COPY_OUT));
	/* Result#result_status constant - Copy In (to server) data transfer started. */
	rb_define_const(rb_mPGconstants, "PGRES_COPY_IN", INT2FIX(PGRES_COPY_IN));
	/* Result#result_status constant - The server’s response was not understood. */
	rb_define_const(rb_mPGconstants, "PGRES_BAD_RESPONSE", INT2FIX(PGRES_BAD_RESPONSE));
	/* Result#result_status constant - A nonfatal error (a notice or warning) occurred. */
	rb_define_const(rb_mPGconstants, "PGRES_NONFATAL_ERROR",INT2FIX(PGRES_NONFATAL_ERROR));
	/* Result#result_status constant - A fatal error occurred. */
	rb_define_const(rb_mPGconstants, "PGRES_FATAL_ERROR", INT2FIX(PGRES_FATAL_ERROR));
	/* Result#result_status constant - Copy In/Out data transfer in progress. */
	rb_define_const(rb_mPGconstants, "PGRES_COPY_BOTH", INT2FIX(PGRES_COPY_BOTH));
	/* Result#result_status constant - Single tuple from larger resultset. */
	rb_define_const(rb_mPGconstants, "PGRES_SINGLE_TUPLE", INT2FIX(PGRES_SINGLE_TUPLE));
#ifdef HAVE_PQSETCHUNKEDROWSMODE
	/* Result#result_status constant - tuple chunk from larger resultset. */
	rb_define_const(rb_mPGconstants, "PGRES_TUPLES_CHUNK", INT2FIX(PGRES_TUPLES_CHUNK));
#endif

#ifdef HAVE_PQENTERPIPELINEMODE
	/* Result#result_status constant - The PG::Result represents a synchronization point in pipeline mode, requested by Connection#pipeline_sync.
	 *
	 * This status occurs only when pipeline mode has been selected. */
	rb_define_const(rb_mPGconstants, "PGRES_PIPELINE_SYNC", INT2FIX(PGRES_PIPELINE_SYNC));

	/* Result#result_status constant - The PG::Result represents a pipeline that has received an error from the server.
	 *
	 * Connection#get_result must be called repeatedly, and each time it will return this status code until the end of the current pipeline, at which point it will return PG::PGRES_PIPELINE_SYNC and normal processing can resume.
	 */
	rb_define_const(rb_mPGconstants, "PGRES_PIPELINE_ABORTED", INT2FIX(PGRES_PIPELINE_ABORTED));
#endif

	/******     Result CONSTANTS: result error field codes      ******/

	/* Result#result_error_field argument constant
	 *
	 * The severity; the field contents are ERROR, FATAL, or PANIC (in an error message), or WARNING, NOTICE, DEBUG, INFO, or LOG (in a notice message), or a localized translation
	 * of one of these.
	 * Always present.
	 */
	rb_define_const(rb_mPGconstants, "PG_DIAG_SEVERITY", INT2FIX(PG_DIAG_SEVERITY));

	/* Result#result_error_field argument constant
	 *
	 * The severity; the field contents are ERROR, FATAL, or PANIC (in an error message), or WARNING, NOTICE, DEBUG, INFO, or LOG (in a notice message).
	 * This is identical to the PG_DIAG_SEVERITY field except that the contents are never localized.
	 *
	 */
	rb_define_const(rb_mPGconstants, "PG_DIAG_SEVERITY_NONLOCALIZED", INT2FIX(PG_DIAG_SEVERITY_NONLOCALIZED));

	/* Result#result_error_field argument constant
	 *
	 * The SQLSTATE code for the error.
	 * The SQLSTATE code identifies the type of error that has occurred; it can be used by front-end applications to perform specific operations (such as error handling) in response to a particular database error.
	 * For a list of the possible SQLSTATE codes, see Appendix A.
	 * This field is not localizable, and is always present.
	 */
	rb_define_const(rb_mPGconstants, "PG_DIAG_SQLSTATE", INT2FIX(PG_DIAG_SQLSTATE));
	/* Result#result_error_field argument constant
	 *
	 * The primary human-readable error message (typically one line).
	 * Always present. */
	rb_define_const(rb_mPGconstants, "PG_DIAG_MESSAGE_PRIMARY", INT2FIX(PG_DIAG_MESSAGE_PRIMARY));
	/* Result#result_error_field argument constant
	 *
	 * Detail: an optional secondary error message carrying more detail about the problem.
	 * Might run to multiple lines.
	 */
	rb_define_const(rb_mPGconstants, "PG_DIAG_MESSAGE_DETAIL", INT2FIX(PG_DIAG_MESSAGE_DETAIL));
	/* Result#result_error_field argument constant
	 *
	 * Hint: an optional suggestion what to do about the problem.
	 * This is intended to differ from detail in that it offers advice (potentially inappropriate) rather than hard facts.
	 * Might run to multiple lines.
	 */
	rb_define_const(rb_mPGconstants, "PG_DIAG_MESSAGE_HINT", INT2FIX(PG_DIAG_MESSAGE_HINT));
	/* Result#result_error_field argument constant
	 *
	 * A string containing a decimal integer indicating an error cursor position as an index into the original statement string.
	 *
	 * The first character has index 1, and positions are measured in characters not bytes.
	 */
	rb_define_const(rb_mPGconstants, "PG_DIAG_STATEMENT_POSITION", INT2FIX(PG_DIAG_STATEMENT_POSITION));
	/* Result#result_error_field argument constant
	 *
	 * This is defined the same as the PG_DIAG_STATEMENT_POSITION field, but it is used when the cursor position refers to an internally generated command rather than the one submitted by the client.
	 * The PG_DIAG_INTERNAL_QUERY field will always appear when this field appears.
	 */
	rb_define_const(rb_mPGconstants, "PG_DIAG_INTERNAL_POSITION", INT2FIX(PG_DIAG_INTERNAL_POSITION));
	/* Result#result_error_field argument constant
	 *
	 * The text of a failed internally-generated command.
	 * This could be, for example, a SQL query issued by a PL/pgSQL function.
	 */
	rb_define_const(rb_mPGconstants, "PG_DIAG_INTERNAL_QUERY", INT2FIX(PG_DIAG_INTERNAL_QUERY));
	/* Result#result_error_field argument constant
	 *
	 * An indication of the context in which the error occurred.
	 * Presently this includes a call stack traceback of active procedural language functions and internally-generated queries.
	 * The trace is one entry per line, most recent first.
	 */
	rb_define_const(rb_mPGconstants, "PG_DIAG_CONTEXT", INT2FIX(PG_DIAG_CONTEXT));
	/* Result#result_error_field argument constant
	 *
	 * The file name of the source-code location where the error was reported. */
	rb_define_const(rb_mPGconstants, "PG_DIAG_SOURCE_FILE", INT2FIX(PG_DIAG_SOURCE_FILE));

	/* Result#result_error_field argument constant
	 *
	 * The line number of the source-code location where the error was reported. */
	rb_define_const(rb_mPGconstants, "PG_DIAG_SOURCE_LINE", INT2FIX(PG_DIAG_SOURCE_LINE));

	/* Result#result_error_field argument constant
	 *
	 * The name of the source-code function reporting the error. */
	rb_define_const(rb_mPGconstants, "PG_DIAG_SOURCE_FUNCTION", INT2FIX(PG_DIAG_SOURCE_FUNCTION));

#ifdef PG_DIAG_TABLE_NAME
	/* Result#result_error_field argument constant
	 *
	 * If the error was associated with a specific database object, the name of the schema containing that object, if any. */
	rb_define_const(rb_mPGconstants, "PG_DIAG_SCHEMA_NAME", INT2FIX(PG_DIAG_SCHEMA_NAME));

	/* Result#result_error_field argument constant
	 *
	 * If the error was associated with a specific table, the name of the table.
	 * (When this field is present, the schema name field provides the name of the table's schema.) */
	rb_define_const(rb_mPGconstants, "PG_DIAG_TABLE_NAME", INT2FIX(PG_DIAG_TABLE_NAME));

	/* Result#result_error_field argument constant
	 *
	 * If the error was associated with a specific table column, the name of the column.
	 * (When this field is present, the schema and table name fields identify the table.) */
	rb_define_const(rb_mPGconstants, "PG_DIAG_COLUMN_NAME", INT2FIX(PG_DIAG_COLUMN_NAME));

	/* Result#result_error_field argument constant
	 *
	 * If the error was associated with a specific datatype, the name of the datatype.
	 * (When this field is present, the schema name field provides the name of the datatype's schema.) */
	rb_define_const(rb_mPGconstants, "PG_DIAG_DATATYPE_NAME", INT2FIX(PG_DIAG_DATATYPE_NAME));

	/* Result#result_error_field argument constant
	 *
	 * If the error was associated with a specific constraint, the name of the constraint.
	 * The table or domain that the constraint belongs to is reported using the fields listed above.
	 * (For this purpose, indexes are treated as constraints, even if they weren't created with constraint syntax.) */
	rb_define_const(rb_mPGconstants, "PG_DIAG_CONSTRAINT_NAME", INT2FIX(PG_DIAG_CONSTRAINT_NAME));
#endif

#ifdef HAVE_PQENTERPIPELINEMODE
	/* Connection#pipeline_status constant
	 *
	 * The libpq connection is in pipeline mode.
	 */
	rb_define_const(rb_mPGconstants, "PQ_PIPELINE_ON", INT2FIX(PQ_PIPELINE_ON));

	/* Connection#pipeline_status constant
	 *
	 * The libpq connection is not in pipeline mode.
	 */
	rb_define_const(rb_mPGconstants, "PQ_PIPELINE_OFF", INT2FIX(PQ_PIPELINE_OFF));

	/* Connection#pipeline_status constant
	 *
	 * The libpq connection is in pipeline mode and an error occurred while processing the current pipeline.
	 * The aborted flag is cleared when PQgetResult returns a result of type PGRES_PIPELINE_SYNC.
	 */
	rb_define_const(rb_mPGconstants, "PQ_PIPELINE_ABORTED", INT2FIX(PQ_PIPELINE_ABORTED));
#endif

	/* Invalid OID constant */
	rb_define_const(rb_mPGconstants, "INVALID_OID", INT2FIX(InvalidOid));
	rb_define_const(rb_mPGconstants, "InvalidOid", INT2FIX(InvalidOid));

	/* PostgreSQL compiled in default port */
	rb_define_const(rb_mPGconstants, "DEF_PGPORT", INT2FIX(DEF_PGPORT));

#ifdef PG_IS_BINARY_GEM
	rb_define_const(rb_mPG, "IS_BINARY_GEM", Qtrue);
#else
	rb_define_const(rb_mPG, "IS_BINARY_GEM", Qfalse);
#endif

	/* Add the constants to the toplevel namespace */
	rb_include_module( rb_mPG, rb_mPGconstants );

	/* Initialize the main extension classes */
	init_pg_connection();
	init_pg_result();
	init_pg_errors();
	init_pg_type_map();
	init_pg_type_map_all_strings();
	init_pg_type_map_by_class();
	init_pg_type_map_by_column();
	init_pg_type_map_by_mri_type();
	init_pg_type_map_by_oid();
	init_pg_type_map_in_ruby();
	init_pg_coder();
	init_pg_text_encoder();
	init_pg_text_decoder();
	init_pg_binary_encoder();
	init_pg_binary_decoder();
	init_pg_copycoder();
	init_pg_recordcoder();
	init_pg_tuple();
	init_pg_cancon();
}
