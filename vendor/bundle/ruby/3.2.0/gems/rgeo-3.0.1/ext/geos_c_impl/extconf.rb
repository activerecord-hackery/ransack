# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Makefile builder for GEOS wrapper
#
# -----------------------------------------------------------------------------
def create_dummy_makefile
  File.write("Makefile", ".PHONY: install\ninstall:\n")
end

if RUBY_DESCRIPTION =~ /^jruby\s/
  create_dummy_makefile
  exit
end

require "mkmf"

if ENV.key?("DEBUG") || ENV.key?("MAINTAINER_MODE")
  $CFLAGS << " -DDEBUG" \
             " -Wall" \
             " -ggdb" \
             " -pedantic" \
             " -std=c17"

  extra_flags = ENV.fetch("MAINTAINER_MODE", ENV.fetch("DEBUG", ""))
  $CFLAGS << " " << extra_flags if extra_flags.strip.start_with?("-")
end

geosconfig = with_config("geos-config") || find_executable("geos-config")

if geosconfig
  puts "Using GEOS compile configuration from #{geosconfig}"
  $INCFLAGS << " " << IO.popen([geosconfig, "--cflags"], &:read).strip
  geos_libs = IO.popen([geosconfig, "--clibs"], &:read)
  geos_libs.split.each do |flag|
    $libs << " " << flag unless $libs.include?(flag)
  end
end

found_geos = false
if have_header("geos_c.h")
  found_geos = true if have_func("GEOSSetSRID_r", "geos_c.h")
  have_func("GEOSPreparedContains_r", "geos_c.h")
  have_func("GEOSPreparedDisjoint_r", "geos_c.h")
  have_func("GEOSUnaryUnion_r", "geos_c.h")
  have_func("GEOSCoordSeq_isCCW_r", "geos_c.h")
  have_func("GEOSDensify", "geos_c.h")
  have_func("rb_memhash", "ruby.h")
  have_func("rb_gc_mark_movable", "ruby.h")
end

if found_geos
  create_makefile("rgeo/geos/geos_c_impl")
else
  puts "**** WARNING: Unable to find GEOS headers or libraries."
  puts "**** Ensure that 'geos-config' is in your PATH or provide that full path via --with-geos-config"
  puts "**** Compiling without GEOS support."

  create_dummy_makefile
end
