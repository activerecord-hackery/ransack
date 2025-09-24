#include <mysql2_ext.h>

VALUE mMysql2, cMysql2Error, cMysql2TimeoutError;

/* Ruby Extension initializer */
void Init_mysql2() {
  mMysql2 = rb_define_module("Mysql2");
  rb_global_variable(&mMysql2);

  cMysql2Error = rb_const_get(mMysql2, rb_intern("Error"));
  rb_global_variable(&cMysql2Error);

  cMysql2TimeoutError = rb_const_get(cMysql2Error, rb_intern("TimeoutError"));
  rb_global_variable(&cMysql2TimeoutError);

  init_mysql2_client();
  init_mysql2_result();
  init_mysql2_statement();
}
