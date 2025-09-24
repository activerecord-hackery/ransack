# Ruby Interface for SQLite3

## Overview

This library allows Ruby programs to use the SQLite3 database engine (http://www.sqlite.org).

Note that this module is only compatible with SQLite 3.6.16 or newer.

* Source code: https://github.com/sparklemotion/sqlite3-ruby
* Mailing list: http://groups.google.com/group/sqlite3-ruby
* Download: http://rubygems.org/gems/sqlite3
* Documentation: http://www.rubydoc.info/gems/sqlite3

[![Unit tests](https://github.com/sparklemotion/sqlite3-ruby/actions/workflows/sqlite3-ruby.yml/badge.svg)](https://github.com/sparklemotion/sqlite3-ruby/actions/workflows/sqlite3-ruby.yml)
[![Native packages](https://github.com/sparklemotion/sqlite3-ruby/actions/workflows/gem-install.yml/badge.svg)](https://github.com/sparklemotion/sqlite3-ruby/actions/workflows/gem-install.yml)


## Quick start

For help understanding the SQLite3 Ruby API, please read the [FAQ](./FAQ.md) and the [full API documentation](https://rubydoc.info/gems/sqlite3).

A few key classes whose APIs are often-used are:

- SQLite3::Database ([rdoc](https://rubydoc.info/gems/sqlite3/SQLite3/Database))
- SQLite3::Statement ([rdoc](https://rubydoc.info/gems/sqlite3/SQLite3/Statement))
- SQLite3::ResultSet ([rdoc](https://rubydoc.info/gems/sqlite3/SQLite3/ResultSet))

If you have any questions that you feel should be addressed in the FAQ, please send them to [the mailing list](http://groups.google.com/group/sqlite3-ruby) or open a [discussion thread](https://github.com/sparklemotion/sqlite3-ruby/discussions/categories/q-a).


``` ruby
require "sqlite3"

# Open a database
db = SQLite3::Database.new "test.db"

# Create a table
rows = db.execute <<-SQL
  create table numbers (
    name varchar(30),
    val int
  );
SQL

# Execute a few inserts
{
  "one" => 1,
  "two" => 2,
}.each do |pair|
  db.execute "insert into numbers values ( ?, ? )", pair
end

# Find a few rows
db.execute( "select * from numbers" ) do |row|
  p row
end
# => ["one", 1]
#    ["two", 2]

# Create another table with multiple columns
db.execute <<-SQL
  create table students (
    name varchar(50),
    email varchar(50),
    grade varchar(5),
    blog varchar(50)
  );
SQL

# Execute inserts with parameter markers
db.execute("INSERT INTO students (name, email, grade, blog)
            VALUES (?, ?, ?, ?)", ["Jane", "me@janedoe.com", "A", "http://blog.janedoe.com"])

db.execute( "select * from students" ) do |row|
  p row
end
# => ["Jane", "me@janedoe.com", "A", "http://blog.janedoe.com"]
```

## Support

### Installation or database extensions

If you're having trouble with installation, please first read [`INSTALLATION.md`](./INSTALLATION.md).

### General help requests

You can ask for help or support:

* by emailing the [sqlite3-ruby mailing list](http://groups.google.com/group/sqlite3-ruby)
* by opening a [discussion thread](https://github.com/sparklemotion/sqlite3-ruby/discussions/categories/q-a) on Github

### Bug reports

You can file the bug at the [github issues page](https://github.com/sparklemotion/sqlite3-ruby/issues).


## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md).


## License

This library is licensed under `BSD-3-Clause`, see [`LICENSE`](./LICENSE).


### Dependencies

The source code of `sqlite` is distributed in the "ruby platform" gem. This code is public domain, see [`LICENSE-DEPENDENCIES`](./LICENSE-DEPENDENCIES) for details.
