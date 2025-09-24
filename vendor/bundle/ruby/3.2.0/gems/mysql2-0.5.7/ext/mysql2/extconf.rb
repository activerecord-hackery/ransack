require 'mkmf'
require 'English'

### Some helper functions

def asplode(lib)
  if RUBY_PLATFORM =~ /mingw|mswin/
    abort "-----\n#{lib} is missing. Check your installation of MySQL or Connector/C, and try again.\n-----"
  elsif RUBY_PLATFORM =~ /darwin/
    abort "-----\n#{lib} is missing. You may need to 'brew install mysql' or 'port install mysql', and try again.\n-----"
  else
    abort "-----\n#{lib} is missing. You may need to 'sudo apt-get install libmariadb-dev', 'sudo apt-get install libmysqlclient-dev' or 'sudo yum install mysql-devel', and try again.\n-----"
  end
end

def add_ssl_defines(header)
  all_modes_found = %w[SSL_MODE_DISABLED SSL_MODE_PREFERRED SSL_MODE_REQUIRED SSL_MODE_VERIFY_CA SSL_MODE_VERIFY_IDENTITY].inject(true) do |m, ssl_mode|
    m && have_const(ssl_mode, header)
  end
  if all_modes_found
    $CFLAGS << ' -DFULL_SSL_MODE_SUPPORT'
  else
    # if we only have ssl toggle (--ssl,--disable-ssl) from 5.7.3 to 5.7.10
    # and the verify server cert option. This is also the case for MariaDB.
    has_verify_support  = have_const('MYSQL_OPT_SSL_VERIFY_SERVER_CERT', header)
    has_enforce_support = have_const('MYSQL_OPT_SSL_ENFORCE', header)
    $CFLAGS << ' -DNO_SSL_MODE_SUPPORT' if !has_verify_support && !has_enforce_support
  end
end

### Check for Ruby C extension interfaces

# 2.1+
have_func('rb_absint_size')
have_func('rb_absint_singlebit_p')

# 2.7+
have_func('rb_gc_mark_movable')

# Missing in RBX (https://github.com/rubinius/rubinius/issues/3771)
have_func('rb_wait_for_single_fd')

# 3.0+
have_func('rb_enc_interned_str', 'ruby.h')

### Find OpenSSL library

# User-specified OpenSSL if explicitly specified
if with_config('openssl-dir')
  _, lib = dir_config('openssl')
  if lib
    # Ruby versions below 2.0 on Unix and below 2.1 on Windows
    # do not properly search for lib directories, and must be corrected:
    # https://bugs.ruby-lang.org/projects/ruby-trunk/repository/revisions/39717
    unless lib && lib[-3, 3] == 'lib'
      @libdir_basename = 'lib'
      _, lib = dir_config('openssl')
    end
    abort "-----\nCannot find library dir(s) #{lib}\n-----" unless lib && lib.split(File::PATH_SEPARATOR).any? { |dir| File.directory?(dir) }
    warn "-----\nUsing --with-openssl-dir=#{File.dirname lib}\n-----"
    $LDFLAGS << " -L#{lib}"
  end
# Homebrew OpenSSL on MacOS
elsif RUBY_PLATFORM =~ /darwin/ && system('command -v brew')
  openssl_location = `brew --prefix openssl`.strip
  $LIBPATH << "#{openssl_location}/lib" unless openssl_location.empty?
end

if RUBY_PLATFORM =~ /darwin/ && system('command -v brew')
  zstd_location = `brew --prefix zstd`.strip
  $LIBPATH << "#{zstd_location}/lib" unless zstd_location.empty?
end

### Find MySQL client library

# borrowed from mysqlplus
# http://github.com/oldmoe/mysqlplus/blob/master/ext/extconf.rb
dirs = ENV.fetch('PATH').split(File::PATH_SEPARATOR) + %w[
  /opt
  /opt/local
  /opt/local/mysql
  /opt/local/lib/mysql5*
  /opt/homebrew/opt/mysql*
  /usr
  /usr/mysql
  /usr/local
  /usr/local/mysql
  /usr/local/mysql-*
  /usr/local/lib/mysql5*
  /usr/local/opt/mysql5*
  /usr/local/opt/mysql@*
  /usr/local/opt/mysql-client
  /usr/local/opt/mysql-client@*
].map { |dir| "#{dir}/bin" }

# For those without HOMEBREW_ROOT in PATH
dirs << "#{ENV['HOMEBREW_ROOT']}/bin" if ENV['HOMEBREW_ROOT']

GLOB = "{#{dirs.join(',')}}/{mysql_config,mysql_config5,mariadb_config}".freeze

# If the user has provided a --with-mysql-dir argument, we must respect it or fail.
inc, lib = dir_config('mysql')
if inc && lib
  # Ruby versions below 2.0 on Unix and below 2.1 on Windows
  # do not properly search for lib directories, and must be corrected:
  # https://bugs.ruby-lang.org/projects/ruby-trunk/repository/revisions/39717
  unless lib && lib[-3, 3] == 'lib'
    @libdir_basename = 'lib'
    inc, lib = dir_config('mysql')
  end
  abort "-----\nCannot find include dir(s) #{inc}\n-----" unless inc && inc.split(File::PATH_SEPARATOR).any? { |dir| File.directory?(dir) }
  abort "-----\nCannot find library dir(s) #{lib}\n-----" unless lib && lib.split(File::PATH_SEPARATOR).any? { |dir| File.directory?(dir) }
  warn "-----\nUsing --with-mysql-dir=#{File.dirname inc}\n-----"
  rpath_dir = lib
  have_library('mysqlclient')
elsif (mc = (with_config('mysql-config') || Dir[GLOB].first))
  # If the user has provided a --with-mysql-config argument, we must respect it or fail.
  # If the user gave --with-mysql-config with no argument means we should try to find it.
  mc = Dir[GLOB].first if mc == true
  abort "-----\nCannot find mysql_config at #{mc}\n-----" unless mc && File.exist?(mc)
  abort "-----\nCannot execute mysql_config at #{mc}\n-----" unless File.executable?(mc)
  warn "-----\nUsing mysql_config at #{mc}\n-----"
  ver = `#{mc} --version`.chomp.to_f
  includes = `#{mc} --include`.chomp
  abort unless $CHILD_STATUS.success?
  libs = `#{mc} --libs_r`.chomp
  # MySQL 5.5 and above already have re-entrant code in libmysqlclient (no _r).
  libs = `#{mc} --libs`.chomp if ver >= 5.5 || libs.empty?
  abort unless $CHILD_STATUS.success?
  $INCFLAGS += ' ' + includes
  $libs = libs + " " + $libs
  rpath_dir = libs
else
  _, usr_local_lib = dir_config('mysql', '/usr/local')

  asplode("mysql client") unless find_library('mysqlclient', nil, usr_local_lib, "#{usr_local_lib}/mysql")

  rpath_dir = usr_local_lib
end

if have_header('mysql.h')
  prefix = nil
elsif have_header('mysql/mysql.h')
  prefix = 'mysql'
else
  asplode 'mysql.h'
end

%w[errmsg.h].each do |h|
  header = [prefix, h].compact.join('/')
  asplode h unless have_header header
end

mysql_h = [prefix, 'mysql.h'].compact.join('/')
add_ssl_defines(mysql_h)
have_struct_member('MYSQL', 'net.vio', mysql_h)
have_struct_member('MYSQL', 'net.pvio', mysql_h)

# These constants are actually enums, so they cannot be detected by #ifdef in C code.
have_const('MYSQL_DEFAULT_AUTH', mysql_h)
have_const('MYSQL_ENABLE_CLEARTEXT_PLUGIN', mysql_h)
have_const('SERVER_QUERY_NO_GOOD_INDEX_USED', mysql_h)
have_const('SERVER_QUERY_NO_INDEX_USED', mysql_h)
have_const('SERVER_QUERY_WAS_SLOW', mysql_h)
have_const('MYSQL_OPTION_MULTI_STATEMENTS_ON', mysql_h)
have_const('MYSQL_OPTION_MULTI_STATEMENTS_OFF', mysql_h)
have_const('MYSQL_OPT_GET_SERVER_PUBLIC_KEY', mysql_h)

# my_bool is replaced by C99 bool in MySQL 8.0, but we want
# to retain compatibility with the typedef in earlier MySQLs.
have_type('my_bool', mysql_h)

# detect mysql functions
have_func('mysql_ssl_set', mysql_h)

### Compiler flags to help catch errors

# This is our wishlist. We use whichever flags work on the host.
# -Wall and -Wextra are included by default.
wishlist = [
  '-Weverything',
  '-Wno-compound-token-split-by-macro', # Fixed in Ruby 2.7+ at https://bugs.ruby-lang.org/issues/17865
  '-Wno-bad-function-cast', # rb_thread_call_without_gvl returns void * that we cast to VALUE
  '-Wno-conditional-uninitialized', # false positive in client.c
  '-Wno-covered-switch-default', # result.c -- enum_field_types (when fully covered, e.g. mysql 5.5)
  '-Wno-declaration-after-statement', # GET_CLIENT followed by GET_STATEMENT in statement.c
  '-Wno-disabled-macro-expansion', # rubby :(
  '-Wno-documentation-unknown-command', # rubby :(
  '-Wno-missing-field-initializers', # gperf generates bad code
  '-Wno-missing-variable-declarations', # missing symbols due to ruby native ext initialization
  '-Wno-padded', # mysql :(
  '-Wno-reserved-id-macro', # rubby :(
  '-Wno-sign-conversion', # gperf generates bad code
  '-Wno-static-in-inline', # gperf generates bad code
  '-Wno-switch-enum', # result.c -- enum_field_types (when not fully covered, e.g. mysql 5.6+)
  '-Wno-undef', # rubinius :(
  '-Wno-unreachable-code', # rubby :(
  '-Wno-used-but-marked-unused', # rubby :(
]

usable_flags = wishlist.select do |flag|
  try_link('int main() {return 0;}',  "-Werror #{flag}")
end

$CFLAGS << ' ' << usable_flags.join(' ')

### Sanitizers to help with debugging -- many are available on both Clang/LLVM and GCC

enabled_sanitizers = disabled_sanitizers = []
# Specify a comma-separated list of sanitizers, or try them all by default
sanitizers = with_config('sanitize')
case sanitizers
when true
  # Try them all, turn on whatever we can
  enabled_sanitizers = %w[address cfi integer memory thread undefined].select do |s|
    try_link('int main() {return 0;}',  "-Werror -fsanitize=#{s}")
  end
  abort "-----\nCould not enable any sanitizers!\n-----" if enabled_sanitizers.empty?
when String
  # Figure out which sanitizers are supported
  enabled_sanitizers, disabled_sanitizers = sanitizers.split(',').partition do |s|
    try_link('int main() {return 0;}',  "-Werror -fsanitize=#{s}")
  end
end

unless disabled_sanitizers.empty? # rubocop:disable Style/IfUnlessModifier
  abort "-----\nCould not enable requested sanitizers: #{disabled_sanitizers.join(',')}\n-----"
end

unless enabled_sanitizers.empty?
  warn "-----\nEnabling sanitizers: #{enabled_sanitizers.join(',')}\n-----"
  enabled_sanitizers.each do |s|
    # address sanitizer requires runtime support
    if s == 'address' # rubocop:disable Style/IfUnlessModifier
      have_library('asan') || $LDFLAGS << ' -fsanitize=address'
    end
    $CFLAGS << " -fsanitize=#{s}"
  end
  # Options for line numbers in backtraces
  $CFLAGS << ' -g -fno-omit-frame-pointer'
end

### Find MySQL Client on Windows, set RPATH to find the library at runtime

if RUBY_PLATFORM =~ /mswin|mingw/ && !defined?(RubyInstaller)
  # Build libmysql.a interface link library
  require 'rake'

  # Build libmysql.a interface link library
  # Use rake to rebuild only if these files change
  deffile = File.expand_path('../../../support/libmysql.def', __FILE__)
  libfile = File.expand_path(File.join(rpath_dir, 'libmysql.lib'))
  file 'libmysql.a' => [deffile, libfile] do
    when_writing 'building libmysql.a' do
      # Ruby kindly shows us where dllwrap is, but that tool does more than we want.
      # Maybe in the future Ruby could provide RbConfig::CONFIG['DLLTOOL'] directly.
      dlltool = RbConfig::CONFIG['DLLWRAP'].gsub('dllwrap', 'dlltool')
      sh dlltool, '--kill-at',
         '--dllname', 'libmysql.dll',
         '--output-lib', 'libmysql.a',
         '--input-def', deffile, libfile
    end
  end

  Rake::Task['libmysql.a'].invoke
  $LOCAL_LIBS << ' ' << 'libmysql.a'

  # Make sure the generated interface library works (if cross-compiling, trust without verifying)
  unless RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
    abort "-----\nCannot find libmysql.a\n-----" unless have_library('libmysql')
    abort "-----\nCannot link to libmysql.a (my_init)\n-----" unless have_func('my_init')
  end

  # Vendor libmysql.dll
  vendordir = File.expand_path('../../../vendor/', __FILE__)
  directory vendordir

  vendordll = File.join(vendordir, 'libmysql.dll')
  dllfile = File.expand_path(File.join(rpath_dir, 'libmysql.dll'))
  file vendordll => [dllfile, vendordir] do
    when_writing 'copying libmysql.dll' do
      cp dllfile, vendordll
    end
  end

  # Copy libmysql.dll to the local vendor directory by default
  if arg_config('--no-vendor-libmysql')
    # Fine, don't.
    puts "--no-vendor-libmysql"
  else # Default: arg_config('--vendor-libmysql')
    # Let's do it!
    Rake::Task[vendordll].invoke
  end
else
  case explicit_rpath = with_config('mysql-rpath')
  when true
    abort "-----\nOption --with-mysql-rpath must have an argument\n-----"
  when false
    warn "-----\nOption --with-mysql-rpath has been disabled at your request\n-----"
  when String
    # The user gave us a value so use it
    rpath_flags = " -Wl,-rpath,#{explicit_rpath}"
    warn "-----\nSetting mysql rpath to #{explicit_rpath}\n-----"
    $LDFLAGS << rpath_flags
  else
    if (libdir = rpath_dir[%r{(-L)?(/[^ ]+)}, 2])
      rpath_flags = " -Wl,-rpath,#{libdir}"
      if RbConfig::CONFIG["RPATHFLAG"].to_s.empty? && try_link('int main() {return 0;}', rpath_flags)
        # Usually Ruby sets RPATHFLAG the right way for each system, but not on OS X.
        warn "-----\nSetting rpath to #{libdir}\n-----"
        $LDFLAGS << rpath_flags
      else
        if RbConfig::CONFIG["RPATHFLAG"].to_s.empty?
          # If we got here because try_link failed, warn the user
          warn "-----\nDon't know how to set rpath on your system, if MySQL libraries are not in path mysql2 may not load\n-----"
        end
        # Make sure that LIBPATH gets set if we didn't explicitly set the rpath.
        warn "-----\nSetting libpath to #{libdir}\n-----"
        $LIBPATH << libdir unless $LIBPATH.include?(libdir)
      end
    end
  end
end

create_makefile('mysql2/mysql2')
