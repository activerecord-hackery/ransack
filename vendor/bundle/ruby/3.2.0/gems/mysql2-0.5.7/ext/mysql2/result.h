#ifndef MYSQL2_RESULT_H
#define MYSQL2_RESULT_H

void init_mysql2_result(void);
VALUE rb_mysql_result_to_obj(VALUE client, VALUE encoding, VALUE options, MYSQL_RES *r, VALUE statement);

typedef struct {
  VALUE fields;
  VALUE fieldTypes;
  VALUE rows;
  VALUE client;
  VALUE encoding;
  VALUE statement;
  my_ulonglong numberOfFields;
  my_ulonglong numberOfRows;
  unsigned long lastRowProcessed;
  char is_streaming;
  char streamingComplete;
  char resultFreed;
  MYSQL_RES *result;
  mysql_stmt_wrapper *stmt_wrapper;
  mysql_client_wrapper *client_wrapper;
  /* statement result bind buffers */
  MYSQL_BIND *result_buffers;
  my_bool *is_null;
  my_bool *error;
  unsigned long *length;
} mysql2_result_wrapper;

#endif
