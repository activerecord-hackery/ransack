---
sidebar_position: 4
title: Upgrading
---

Ransack follows [semantic versioning](../going-further/release_process.md#semantic-versioning):
a major release is the only place a breaking change can land. This page lists
what changed in each major release and what to do about it. The full list of
changes in every release is in the
[GitHub release notes](https://github.com/activerecord-hackery/ransack/releases).

## Upgrading to 6.0

### Ruby 3.2 or later is required

Ruby 3.1 reached end of life in March 2025 and no longer receives security
fixes. Ransack 6.0 requires Ruby 3.2 or later, which is also the floor for
Rails 8.0. If you are on Ruby 3.1 you are already limited to Rails 7.2; stay on
Ransack 5.x until you can upgrade Ruby.

### `cont` is case-sensitive on PostgreSQL

Ransack never told Arel whether a `LIKE` should be case-sensitive, and Arel's
PostgreSQL visitor renders the default as `ILIKE`. So on PostgreSQL `cont`,
`start`, `end` and `matches` all ignored case, while the docs said `cont` used
`LIKE`. They now do: `cont` is `LIKE` and `i_cont` is `ILIKE`. A PostgreSQL
application that relied on `cont` ignoring case should switch those searches
to `i_cont`. MySQL and SQLite are unaffected; their `LIKE` follows the
column's collation as before. See
[Search Matchers](./search-matches.md#case-sensitivity).

### Database dialects are detected from the adapter class

A few places generate different SQL per database. They used to compare the
adapter's name against a list (`"PostgreSQL"`, `"PostGIS"`, `"Mysql2"`,
`"Trilogy"`), so an adapter that was not on the list — even one built on a
known adapter — got the wrong SQL, and PostGIS was carried as a development
dependency just to keep it on the list. The dialect is now read from the
adapter class's ancestry, so PostGIS is PostgreSQL without being named, and
`config.dialect` overrides the detection. The `activerecord-postgis-adapter`
development dependency and its CI job are gone. See
[Configuration](./configuration.md#sql-dialect).

### `Polyamorous` is gone; `Ransack::Adapters::ActiveRecord` is deprecated

The Active Record integration now lives under `Ransack::ActiveRecord`. See
[How Ransack is built](../going-further/architecture.md) for the layout.

- `Ransack::Adapters::ActiveRecord::Base` and `::Context` still resolve, with a
  deprecation warning, and will be removed in 7.0. An initializer that reopens
  `Ransack::Adapters::ActiveRecord::Base` to change the `ransackable_*`
  defaults should reopen `Ransack::ActiveRecord::Base` instead.
- The `Polyamorous` namespace and the `polyamorous/polyamorous` require path
  are removed. `Polyamorous::Join` is `Ransack::ActiveRecord::Join`;
  `Polyamorous::InnerJoin` and `OuterJoin` were aliases for
  `Arel::Nodes::InnerJoin` and `Arel::Nodes::OuterJoin`, so use those.
- `Ransack::SUPPORTS_ATTRIBUTE_ALIAS` is removed; every supported Active Record
  version supports attribute aliases.
- `Ransack::Context.for_class` and `for_object` are replaced by a resolver
  registry, `Ransack::Context.register`, so another ORM can plug in without
  patching Ransack.

## Upgrading to 5.0

Ransack 5.0 shipped on 2026-09-21 with these behaviour changes. Each is
described in more detail on the page it links to.

- `LIKE` wildcards (`%` and `_`) in search values are escaped on every database,
  and every `LIKE` carries an explicit `ESCAPE` clause. A value of `100%` now
  matches the literal text `100%`. See [Search Matchers](./search-matches.md).
- Empty arrays and blank strings can be treated as real filter values with
  `config.ignore_blank_values = false`. See [Configuration](./configuration.md).
- An unknown combinator (`m:`) raises under `ransack!` or
  `ignore_unknown_conditions: false` rather than silently meaning `and`, and
  `OR` / `:or` are normalised to `or`. See [Advanced Mode](./advanced-mode.md).
- `config.postgres_fields_sort_option` is renamed `config.fields_sort_option`,
  because `NULLS FIRST` / `NULLS LAST` are emitted through Arel and work on
  every database that supports them. The old name still works. See
  [Sorting](./sorting.md).
- The monkey patch on `ActionView::Helpers::Tags::Base#value` is gone. Form
  fields read their values through the search object's own readers, so nothing
  changes for `search_form_for`, but code that depended on the patch
  indirectly should be checked.
