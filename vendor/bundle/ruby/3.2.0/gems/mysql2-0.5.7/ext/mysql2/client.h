#ifndef MYSQL2_CLIENT_H
#define MYSQL2_CLIENT_H

typedef struct {
  VALUE encoding;
  VALUE active_fiber; /* rb_fiber_current() or Qnil */
  long server_version;
  int reconnect_enabled;
  unsigned int connect_timeout;
  int active;
  int automatic_close;
  int initialized;
  int refcount;
  int closed;
  uint64_t affected_rows;
  MYSQL *client;
} mysql_client_wrapper;

void rb_mysql_set_server_query_flags(MYSQL *client, VALUE result);

extern const rb_data_type_t rb_mysql_client_type;

#ifdef NEW_TYPEDDATA_WRAPPER
#define GET_CLIENT(self) \
  mysql_client_wrapper *wrapper; \
  TypedData_Get_Struct(self, mysql_client_wrapper, &rb_mysql_client_type, wrapper);
#else
#define GET_CLIENT(self) \
  mysql_client_wrapper *wrapper; \
  Data_Get_Struct(self, mysql_client_wrapper, wrapper);
#endif

void init_mysql2_client(void);
void decr_mysql2_client(mysql_client_wrapper *wrapper);

#endif
