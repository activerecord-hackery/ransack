# sqlite3-ruby Changelog

## 1.7.3 / 2024-03-15

### Dependencies

- Vendored sqlite is updated to [v3.45.2](https://www.sqlite.org/releaselog/3_45_2.html). @flavorjones


## 1.7.2 / 2024-01-30

### Dependencies

- Vendored sqlite is updated to [v3.45.1](https://www.sqlite.org/releaselog/3_45_1.html). @flavorjones


## 1.7.1 / 2024-01-24

### Dependencies

- Vendored sqlite is updated to [v3.45.0](https://www.sqlite.org/releaselog/3_45_0.html). @flavorjones


## 1.7.0 / 2023-12-27

### Ruby

This release introduces native gem support for Ruby 3.3.

This release ends native gem support for Ruby 2.7, for which [upstream support ended 2023-03-31](https://www.ruby-lang.org/en/downloads/branches/). Ruby 2.7 is still generally supported, but will not be shipped in the native gems.

This release ends support for Ruby 1.9.3, 2.0, 2.1, 2.2, 2.3, 2.4, 2.5, and 2.6.

### Improved

- SQLite3::Statement, Database, and Backup objects have been converted to use the TypedData API. See https://bugs.ruby-lang.org/issues/19998 for more context. [#432] @casperisfine


## 1.6.9 / 2023-11-26

### Dependencies

- Vendored sqlite is update to [v3.44.2](https://sqlite.org/releaselog/3_44_2.html). @flavorjones

### Added

- `Database.new` now accepts a `:default_transaction_mode` option (defaulting to `:deferred`), and `Database#transaction` no longer requires a transaction mode to be specified. This should allow higher-level adapters to more easily choose a transaction mode for a database connection. [#426] @masamitsu-murase


## 1.6.8 / 2023-11-01

### Dependencies

- Vendored sqlite is updated to [v3.44.0](https://sqlite.org/releaselog/3_44_0.html). @flavorjones
- rake-compiler-dock updated to v1.3.1 for precompiled native gems. @flavorjones


### Added

- `SQLite3::Database.open` now returns the block result. Previously this returned the Database object. [#415] @toy
- Documentation improvement in `lib/sqlite3/database.rb`. [#421] @szTheory


## 1.6.7 / 2023-10-10

### Dependencies

Vendored sqlite is updated to [v3.43.2](https://sqlite.org/releaselog/3_43_2.html).

Upstream release notes:

> - Fix a couple of obscure UAF errors and an obscure memory leak.
> - Omit the use of the sprintf() function from the standard library in the [CLI](https://sqlite.org/cli.html), as this now generates warnings on some platforms.
> - Avoid conversion of a double into unsigned long long integer, as some platforms do not do such conversions correctly.


### Added

* Compile packaged sqlite3 with additional flags to explicitly enable FTS5, and set synchronous mode to normal when in WAL mode. [#408] (@flavorjones)


## 1.6.6 / 2023-09-12

### Dependencies

Vendored sqlite is updated to [v3.43.1](https://sqlite.org/releaselog/3_43_1.html).

Upstream release notes:

> - Fix a regression in the way that the [sum()](https://sqlite.org/lang_aggfunc.html#sumunc), [avg()](https://sqlite.org/lang_aggfunc.html#avg), and [total()](https://sqlite.org/lang_aggfunc.html#sumunc) aggregate functions handle infinities.
> - Fix a bug in the [json_array_length()](https://sqlite.org/json1.html#jarraylen) function that occurs when the argument comes directly from [json_remove()](https://sqlite.org/json1.html#jrm).
> - Fix the omit-unused-subquery-columns optimization (introduced in in version 3.42.0) so that it works correctly if the subquery is a compound where one arm is DISTINCT and the other is not.
> - Other minor fixes.


## 1.6.5 / 2023-09-08

### Packaging

* Allow setting compiler flags for the sqlite library via a `--with-sqlite-cflags` argument to `extconf.rb`. See [`INSTALLATION.md`](https://github.com/sparklemotion/sqlite3-ruby/blob/master/INSTALLATION.md#controlling-compilation-flags-for-sqlite) for more information. [#401, #402] (@flavorjones)


## 1.6.4 / 2023-08-26

### Dependencies

Vendored sqlite is updated to [v3.43.0](https://sqlite.org/releaselog/3_43_0.html).

Upstream release notes:

> SQLite Release 3.43.0 On 2023-08-24
> * Add support for Contentless-Delete FTS5 Indexes. This is a variety of FTS5 full-text search index that omits storing the content that is being indexed while also allowing records to be deleted.
> * Enhancements to the date and time functions:
>   * Added new time shift modifiers of the form ±YYYY-MM-DD HH:MM:SS.SSS.
>   * Added the timediff() SQL function.
> * Added the octet_length(X) SQL function.
> * Added the sqlite3_stmt_explain() API.
> * Query planner enhancements:
>   * Generalize the LEFT JOIN strength reduction optimization so that it works for RIGHT and FULL JOINs as well. Rename it to OUTER JOIN strength reduction.
>   * Enhance the theorem prover in the OUTER JOIN strength reduction optimization so that it returns fewer false-negatives.
> * Enhancements to the decimal extension:
>   * New function decimal_pow2(N) returns the N-th power of 2 for integer N between -20000 and +20000.
>   * New function decimal_exp(X) works like decimal(X) except that it returns the result in exponential notation - with a "e+NN" at the end.
>   * If X is a floating-point value, then the decimal(X) function now does a full expansion of that value into its exact decimal equivalent.
> * Performance enhancements to JSON processing results in a 2x performance improvement for some kinds of processing on large JSON strings.
> * New makefile target "verify-source" checks to ensure that there are no unintentional changes in the source tree. (Works for canonical source code only - not for precompiled amalgamation tarballs.)
> * Added the SQLITE_USE_SEH compile-time option that enables Structured Exception Handling on Windows while working with the memory-mapped shm file that is part of WAL mode processing. This option is enabled by default when building on Windows using Makefile.msc.
> * The VFS for unix now assumes that the nanosleep() system call is available unless compiled with -DHAVE_NANOSLEEP=0.


## 1.6.3 / 2023-05-16

### Dependencies

Vendored sqlite is updated to [v3.42.0](https://sqlite.org/releaselog/3_42_0.html).

From the release announcement:

> This is a regular enhancement release.  The main new features are:
> * SQLite will now parse and understand JSON5, though it is careful to generate only pure, canonical JSON.
> * The secure-delete option has been added to the FTS5 extension.


## 1.6.2 / 2023-03-27

### Dependencies

Vendored sqlite is updated from v3.41.0 to [v3.41.2](https://sqlite.org/releaselog/3_41_2.html).


### Packaging

* Allow compilation against system libraries without the presence of `mini_portile2`, primarily for the convenience of linux distro repackagers. [#381] (Thank you, @voxik!)


## 1.6.1 / 2023-02-22

### Dependencies

* Vendored sqlite is updated to [v3.41.0](https://sqlite.org/releaselog/3_41_0.html).


## 1.6.0 / 2023-01-13

### Ruby

This release introduces native gem support for Ruby 3.2.

This release ends native gem support for Ruby 2.6, for which [upstream support ended 2022-04-12](https://www.ruby-lang.org/en/downloads/branches/).


### Dependencies

* Vendored sqlite3 is updated to [v3.40.1](https://sqlite.org/releaselog/3_40_1.html).


### Fixes

* `get_boolean_pragma` now returns the correct value. Previously, it always returned true. [#275] (Thank you, @Edouard-chin!)


## 1.5.4 / 2022-11-18

### Dependencies

* Vendored sqlite is updated to [v3.40.0](https://sqlite.org/releaselog/3_40_0.html).


## 1.5.3 / 2022-10-11

### Fixed

* Fixed installation of the "ruby" platform gem when building from source on Fedora. In v1.5.0..v1.5.2, installation failed on some systems due to the behavior of Fedora's pkg-config implementation. [#355]


## 1.5.2 / 2022-10-01

### Packaging

This version correctly vendors the tarball for sqlite v3.39.4 in the vanilla "ruby" platform gem package, so that users will not require network access at installation.

v1.5.0 and v1.5.1 mistakenly packaged the tarball for sqlite v3.38.5 in the vanilla "ruby" platform gem, resulting in downloading the intended tarball over the network at installation time (or, if the network was not available, failure to install). Note that the precompiled native gems were not affected by this issue. [#352]


## 1.5.1 / 2022-09-29

### Dependencies

* Vendored sqlite is updated to [v3.39.4](https://sqlite.org/releaselog/3_39_4.html).

### Security

The vendored version of sqlite, v3.39.4, should be considered to be a security release. From the release notes:

> Version 3.39.4 is a minimal patch against the prior release that addresses issues found since the
> prior release. In particular, a potential vulnerability in the FTS3 extension has been fixed, so
> this should be considered a security update.
>
> In order to exploit the vulnerability, an attacker must have full SQL access and must be able to
> construct a corrupt database with over 2GB of FTS3 content. The problem arises from a 32-bit
> signed integer overflow.

For more information please see [GHSA-mgvv-5mxp-xq67](https://github.com/sparklemotion/sqlite3-ruby/security/advisories/GHSA-mgvv-5mxp-xq67).


## 1.5.0 / 2022-09-08

### Packaging

#### Faster, more reliable installation

Native (precompiled) gems are available for Ruby 2.6, 2.7, 3.0, and 3.1 on all these platforms:

- `aarch64-linux`
- `arm-linux`
- `arm64-darwin`
- `x64-mingw32` and `x64-mingw-ucrt`
- `x86-linux`
- `x86_64-darwin`
- `x86_64-linux`

If you are using one of these Ruby versions on one of these platforms, the native gem is the recommended way to install sqlite3-ruby.

See [the README](https://github.com/sparklemotion/sqlite3-ruby#native-gems-recommended) for more information.


#### More consistent developer experience

Both the native (precompiled) gems and the vanilla "ruby platform" (source) gem include sqlite v3.39.3 by default.

Defaulting to a consistent version of sqlite across all systems means that your development environment behaves exactly like your production environment, and you have access to the latest and greatest features of sqlite.

You can opt-out of the packaged version of sqlite (and use your system-installed library as in versions < 1.5.0). See [the README](https://github.com/sparklemotion/sqlite3-ruby#avoiding-the-precompiled-native-gem) for more information.

[Release notes for this version of sqlite](https://sqlite.org/releaselog/3_39_3.html)


### Rubies and Platforms

* TruffleRuby is supported.
* Apple Silicon is supported (M1, arm64-darwin).
* vcpkg system libraries supported. [#332] (Thanks, @MSP-Greg!)


### Added

* `SQLite3::SQLITE_LOADED_VERSION` contains the version string of the sqlite3 library that is dynamically loaded (compare to `SQLite3::SQLITE_VERSION` which is the version at compile-time).


### Fixed

* `SQLite3::Database#load_extensions` now raises a `TypeError` unless a String is passed as the file path. Previously it was possible to pass a non-string and cause a segfault. [#339]


## 1.4.4 / 2022-06-14

### Fixes

* Compilation no longer fails against SQLite3 versions < 3.29.0. This issue was introduced in v1.4.3. [#324] (Thank you, @r6e!)


## 1.4.3 / 2022-05-25

### Enhancements

* Disable non-standard support for double-quoted string literals via the `:strict` option. [#317] (Thank you, @casperisfine!)
* Column type names are now explicitly downcased on platforms where they may have been in shoutcaps. [#315] (Thank you, @petergoldstein!)
* Support File or Pathname arguments to `Database.new`. [#283] (Thank you, @yb66!)
* Support building on MSVC. [#285] (Thank you, @jmarrec!)


## 1.4.2 / 2019-12-18

* Travis: Drop unused setting "sudo: false"
* The taint mechanism will be deprecated in Ruby 2.7
* Fix Ruby 2.7 rb_check_safe_obj warnings
* Update travis config


## 1.4.1

* Don't mandate dl functions for the extention build
* bumping version


## 1.4.0

### Enhancements

* Better aggregator support

### Bugfixes

* Various


## 1.3.13

### Enhancements

* Support SQLite flags when defining functions
* Add definition for SQLITE_DETERMINISTIC flag


## 1.3.12

### Bugfixes

* OS X install will default to homebrew if available. Fixes #195


## 1.3.11 / 2015-10-10

### Enhancements

* Windows: build against SQLite 3.8.11.1

### Internal

* Use rake-compiler-dock to build Windows binaries. Pull #159 [larskanis]
* Expand Ruby versions being tested for Travis and AppVeyor


## 1.3.10 / 2014-10-30

### Enhancements

* Windows: build against SQLite 3.8.6. Closes #135 [Hubro]


## 1.3.9 / 2014-02-25

### Bugfixes

* Reset exception message. Closes #80
* Reduce warnings due unused pointers. Closes #89
* Add BSD-3 license reference to gemspec. Refs #99 and #106


## 1.3.8 / 2013-08-17

### Enhancements

* Windows: build against SQLite 3.7.17

### Bugfixes

* Reset exception message. Closes #80
* Correctly convert BLOB values to Ruby. Closes #65
* Add MIT license reference to gemspec. Closes #99
* Remove unused pointer. Closes #89

### Internal

* Backport improvements in cross compilation for Windows
* Use of Minitest for internal tests
* Use Gemfile (generated by Hoe) to deal with dependencies
* Cleanup Travis CI


## 1.3.7 / 2013-01-11

### Bugfixes

* Closing a bad statement twice will not segv.
* Aggregate handlers are initialized on each query. Closes #44

### Internal

* Unset environment variables that could affect cross compilation.


## 1.3.6 / 2012-04-16

### Enhancements

* Windows: build against SQLite 3.7.11
* Added SQLite3::ResultSet#each_hash for fetching each row as a hash.
* Added SQLite3::ResultSet#next_hash for fetching one row as a hash.

### Bugfixes

* Support both UTF-16LE and UTF-16BE encoding modes on PPC. Closes #63
* Protect parameters to custom functions from being garbage collected too
  soon. Fixes #60. Thanks hirataya!
* Fix backwards compatibility with 1.2.5 with bind vars and `query` method.
  Fixes #35.
* Fix double definition error caused by defining sqlite3_int64/uint64.
* Fix suspicious version regexp.

### Deprecations

* ArrayWithTypesAndFields#types is deprecated and the class will be removed
  in version 2.0.0.  Please use the `types` method on the ResultSet class
  that created this object.
* ArrayWithTypesAndFields#fields is deprecated and the class will be removed
  in version 2.0.0.  Please use the `columns` method on the ResultSet class
  that created this object.
* The ArrayWithTypesAndFields class will be removed in 2.0.0
* The ArrayWithTypes class will be removed in 2.0.0
* HashWithTypesAndFields#types is deprecated and the class will be removed
  in version 2.0.0.  Please use the `types` method on the ResultSet class
  that created this object.
* HashWithTypesAndFields#fields is deprecated and the class will be removed
  in version 2.0.0.  Please use the `columns` method on the ResultSet class
  that created this object.


## 1.3.5 / 2011-12-03 - ZOMG Holidays are here Edition!

### Enhancements

* Windows: build against SQLite 3.7.9
* Static: enable SQLITE_ENABLE_COLUMN_METADATA
* Added Statement#clear_bindings! to set bindings back to nil

### Bugfixes

* Fixed a segv on Database.new. Fixes #34 (thanks nobu!)
* Database error is not reset, so don't check it in Statement#reset!
* Remove conditional around Bignum statement bindings.
  Fixes #52. Fixes #56. Thank you Evgeny Myasishchev.

### Internal

* Use proper endianness when testing database connection with UTF-16.
  Fixes #40. Fixes #51
* Use -fPIC for static compilation when host is x86_64.


## 1.3.4 / 2011-07-25

### Enhancements

* Windows: build against SQLite 3.7.7.1
* Windows: build static binaries that do not depend on sqlite3.dll be
  installed anymore

### Bugfixes

* Backup API is conditionally required so that older libsqlite3 can be used.
  Thanks Hongli Lai.
* Fixed segmentation fault when nil is passed to SQLite3::Statement.new
* Fix extconf's hardcoded path that affected installation on certain systems.


## 1.3.3 / 2010-01-16

### Bugfixes

* Abort on installation if sqlite3_backup_init is missing. Fixes #19
* Gem has been renamed to 'sqlite3'.  Please use `gem install sqlite3`


## 1.3.2 / 2010-10-30 / RubyConf Uruguay Edition!

### Enhancements

* Windows: build against 3.7.3 version of SQLite3
* SQLite3::Database can now be open as readonly

    db = SQLite3::Database.new('my.db', :readonly => true)

* Added SQLite3::SQLITE_VERSION and SQLite3::SQLITE_VERSION_NUMBER [nurse]

### Bugfixes

* type_translation= works along with Database#execute and a block
* defined functions are kept in a hash to prevent GC. #7
* Removed GCC specific flags from extconf.

### Deprecations

* SQLite3::Database#type_translation= will be deprecated in the future with
  no replacement.
* SQlite3::Version will be deprecated in 2.0.0 with SQLite3::VERSION as the
  replacement.


## 1.3.1 / 2010-07-09

### Enhancements

* Custom collations may be defined using SQLite3::Database#collation

### Bugfixes

* Statements returning 0 columns are automatically stepped. [RF #28308]
* SQLite3::Database#encoding works on 1.8 and 1.9


## 1.3.0 / 2010-06-06

### Enhancements

* Complete rewrite of C-based adapter from SWIG to hand-crafted one [tenderlove]
  See API_CHANGES document for details.
  This closes: Bug #27300, Bug #27241, Patch #16020
* Improved UTF, Unicode, M17N, all that handling and proper BLOB handling [tenderlove, nurse]
* Added support for type translations [tenderlove]

      @db.translator.add_translator('sometime') do |type, thing|
        'output' # this will be returned as value for that column
      end

### Experimental

* Added API to access and load extensions. [kashif]
  These functions maps directly into SQLite3 own enable_load_extension()
  and load_extension() C-API functions. See SQLite3::Database API documentation for details.
  This closes: Patches #9178

### Bugfixes

* Corrected gem dependencies (runtime and development)
* Fixed threaded tests [Alexey Borzenkov]
* Removed GitHub gemspec
* Fixed "No definition for" warnings from RDoc
* Generate zip and tgz files for releases
* Added Luis Lavena as gem Author (maintainer)
* Prevent mkmf interfere with Mighty Snow Leopard
* Allow extension compilation search for common lib paths [kashif]
  (lookup /usr/local, /opt/local and /usr)
* Corrected extension compilation under MSVC [romuloceccon]
* Define load_extension functionality based on availability [tenderlove]
* Deprecation notices for Database#query. Fixes RF #28192


## 1.3.0.beta.2 / 2010-05-15

### Enhancements

* Added support for type translations [tenderlove]

      @db.translator.add_translator('sometime') do |type, thing|
        'output' # this will be returned as value for that column
      end

### Bugfixes

* Allow extension compilation search for common lib paths [kashif]
  (lookup /usr/local, /opt/local and /usr)
* Corrected extension compilation under MSVC [romuloceccon]
* Define load_extension functionality based on availability [tenderlove]
* Deprecation notices for Database#query. Fixes RF #28192


## 1.3.0.beta.1 / 2010-05-10

### Enhancements

* Complete rewrite of C-based adapter from SWIG to hand-crafted one [tenderlove]
  See API_CHANGES document for details.
  This closes: Bug #27300, Bug #27241, Patch #16020
* Improved UTF, Unicode, M17N, all that handling and proper BLOB handling [tenderlove, nurse]

### Experimental

* Added API to access and load extensions. [kashif]
  These functions maps directly into SQLite3 own enable_load_extension()
  and load_extension() C-API functions. See SQLite3::Database API documentation for details.
  This closes: Patches #9178

### Bugfixes

* Corrected gem dependencies (runtime and development)
* Fixed threaded tests [Alexey Borzenkov]
* Removed GitHub gemspec
* Fixed "No definition for" warnings from RDoc
* Generate zip and tgz files for releases
* Added Luis Lavena as gem Author (maintainer)
* Prevent mkmf interfere with Mighty Snow Leopard


## 1.2.5 / 2009-07-25

* Check for illegal nil before executing SQL [Erik Veenstra]
* Switch to Hoe for gem task management and packaging.
* Advertise rake-compiler as development dependency.
* Build gem binaries for Windows.
* Improved Ruby 1.9 support compatibility.
* Taint returned values. Patch #20325.
* Database.open and Database.new now take an optional block [Gerrit Kaiser]


## 1.2.4.1 (internal) / 2009-07-05

* Check for illegal nil before executing SQL [Erik Veenstra]
* Switch to Hoe for gem task management and packaging.
* Advertise rake-compiler as development dependency.
* Build gem binaries for Windows.
* Improved Ruby 1.9 support compatibility.


## 1.2.4 / 2008-08-27

* Package the updated C file for source builds. [Jamis Buck]


## 1.2.3 / 2008-08-26

* Fix incorrect permissions on database.rb and translator.rb [Various]
* Avoid using Object#extend for greater speedups [Erik Veenstra]
* Ruby 1.9 compatibility tweaks for Array#zip [jimmy88@gmail.com]
* Fix linking against Ruby 1.8.5 [Rob Holland <rob@inversepath.com>]


## 1.2.2 / 2008-05-31

* Make the table_info method adjust the returned default value for the rows
  so that the sqlite3 change in 3.3.8 and greater can be handled
  transparently [Jamis Buck <jamis@37signals.com>]
* Ruby 1.9 compatibility tweaks [Roman Le Negrate <roman2k@free.fr>]
* Various performance enhancements [thanks Erik Veenstra]
* Correct busy_handler documentation [Rob Holland <rob@inversepath.com>]
* Use int_bind64 on Fixnum values larger than a 32bit C int can take. [Rob Holland <rob@inversepath.com>]
* Work around a quirk in SQLite's error reporting by calling sqlite3_reset
  to produce a more informative error code upon a failure from
  sqlite3_step. [Rob Holland <rob@inversepath.com>]
* Various documentation, test, and style tweaks [Rob Holland <rob@inversepath.com>]
* Be more granular with time/data translation [Rob Holland <rob@inversepath.com>]
* Use Date directly for parsing rather than going via Time [Rob Holland <rob@inversepath.com>]
* Check for the rt library and fdatasync so we link against that when
  needed [Rob Holland <rob@inversepath.com>]
* Rename data structures to avoid collision on win32. based on patch
  by: Luis Lavena [Rob Holland <rob@inversepath.com>]
* Add test for defaults [Daniel Rodríguez Troitiño]
* Correctly unquote double-quoted pragma defaults [Łukasz Dargiewicz <lukasz.dargiewicz@gmail.com>]
