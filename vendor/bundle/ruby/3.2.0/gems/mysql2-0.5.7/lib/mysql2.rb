require 'date'
require 'bigdecimal'

# Load libmysql.dll before requiring mysql2/mysql2.so
# This gives a chance to be flexible about the load path
# Or to bomb out with a clear error message instead of a linker crash
if RUBY_PLATFORM =~ /mswin|mingw/
  dll_path = if ENV['RUBY_MYSQL2_LIBMYSQL_DLL']
    # If this environment variable is set, it overrides any other paths
    # The user is advised to use backslashes not forward slashes
    ENV['RUBY_MYSQL2_LIBMYSQL_DLL']
  elsif File.exist?(File.expand_path('../vendor/libmysql.dll', File.dirname(__FILE__)))
    # Use vendor/libmysql.dll if it exists, convert slashes for Win32 LoadLibrary
    File.expand_path('../vendor/libmysql.dll', File.dirname(__FILE__))
  elsif defined?(RubyInstaller)
    # RubyInstaller-2.4+ native build doesn't need DLL preloading
  else
    # This will use default / system library paths
    'libmysql.dll'
  end

  if dll_path
    require 'fiddle'
    kernel32 = Fiddle.dlopen 'kernel32'
    load_library = Fiddle::Function.new(
      kernel32['LoadLibraryW'], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT,
    )
    if load_library.call(dll_path.encode('utf-16le')).zero?
      abort "Failed to load libmysql.dll from #{dll_path}"
    end
  end
end

require 'mysql2/version' unless defined? Mysql2::VERSION
require 'mysql2/error'
require 'mysql2/mysql2'
require 'mysql2/result'
require 'mysql2/client'
require 'mysql2/field'
require 'mysql2/statement'

# = Mysql2
#
# A modern, simple and very fast Mysql library for Ruby - binding to libmysql
module Mysql2
end

if defined?(ActiveRecord::VERSION::STRING) && ActiveRecord::VERSION::STRING < "3.1"
  begin
    require 'active_record/connection_adapters/mysql2_adapter'
  rescue LoadError
    warn "============= WARNING FROM mysql2 ============="
    warn "This version of mysql2 (#{Mysql2::VERSION}) doesn't ship with the ActiveRecord adapter."
    warn "In Rails version 3.1.0 and up, the mysql2 ActiveRecord adapter is included with rails."
    warn "If you want to use the mysql2 gem with Rails <= 3.0.x, please use the latest mysql2 in the 0.2.x series."
    warn "============= END WARNING FROM mysql2 ============="
  end
end

# For holding utility methods
module Mysql2
  module Util
    #
    # Rekey a string-keyed hash with equivalent symbols.
    #
    def self.key_hash_as_symbols(hash)
      return nil unless hash

      Hash[hash.map { |k, v| [k.to_sym, v] }]
    end

    #
    # In Mysql2::Client#query and Mysql2::Statement#execute,
    # Thread#handle_interrupt is used to prevent Timeout#timeout
    # from interrupting query execution.
    #
    # Timeout::ExitException was removed in Ruby 2.3.0, 2.2.3, and 2.1.8,
    # but is present in earlier 2.1.x and 2.2.x, so we provide a shim.
    #
    require 'timeout'
    TIMEOUT_ERROR_CLASS = if defined?(::Timeout::ExitException)
      ::Timeout::ExitException
    else
      ::Timeout::Error
    end
    TIMEOUT_ERROR_NEVER = { TIMEOUT_ERROR_CLASS => :never }.freeze
  end
end
