# Installation

Ransack is supported for Rails 8.1 on Ruby 3.3 and later.

Add it to your Gemfile and run `bundle install`:

```ruby
gem 'ransack'
```

There is nothing to generate. Every Active Record model gets a `ransack`
class method, and every view gets the `search_form_for` and `sort_link`
helpers. Optional settings go in an initializer; see
[Configuration](/ransack/getting-started/configuration/).

## Bleeding edge

To use changes that are not yet released to RubyGems, use the `main` branch:

```ruby
gem 'ransack', github: 'activerecord-hackery/ransack', branch: 'main'
```

## Databases

Ransack generates SQL through Arel, so it works with any database Active
Record can talk to. Three are tested on every change and get first-class
treatment for the handful of places where the SQL differs:

| Database | Adapters | Tested in CI |
| --- | --- | --- |
| PostgreSQL | `postgresql`, and any adapter built on it such as `postgis` | yes |
| MySQL / MariaDB | `mysql2`, `trilogy` | yes |
| SQLite | `sqlite3` | yes |

An adapter that subclasses one of Rails' own is recognised as that database
without any configuration. Other adapters (`sqlserver`, `oracle_enhanced`)
are treated as standard SQL; they are known to work but are not tested here,
and the [`dialect` option](/ransack/getting-started/configuration/#sql-dialect) lets you name a
dialect explicitly if one of the known ones is a better fit.

## Demo application

The [Ransack Demo application](https://github.com/activerecord-hackery/ransack_demo)
shows how to build [simple](http://ransack-demo.herokuapp.com) and
[advanced](http://ransack-demo.herokuapp.com/users/advanced_search) search
forms in a Rails application.

## Next steps

1. [Simple mode](/ransack/getting-started/simple-mode/): a search form and sortable columns.
2. [Authorization](/ransack/getting-started/authorization/): nothing is searchable until a model
   says so.
3. [Using predicates](/ransack/getting-started/using-predicates/): `eq`, `cont`, `in`, `null` and
   the rest.
