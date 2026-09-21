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

### Strict searches check more

Under `ransack!` or `ignore_unknown_conditions = false`, two things that were
silently accepted now raise `Ransack::InvalidSearchError`:

- a sort on an attribute that is not ransortable or does not exist, which used
  to drop the whole `ORDER BY` (see [Sorting](./sorting.md#unknown-sorts));
- a condition name that mixes `_and_` and `_or_`, which used to apply the
  first combinator to every attribute (see [Simple Mode](./simple-mode.md)).

Permissive searches are unchanged.

### Values are cast by the declared attribute type

A column redeclared with `attribute :name, :datetime` is now cast as a
datetime; before, the schema column's type won. A `Date` given for a datetime
column now means midnight in `Time.zone`; before, it was midnight in the
server's system time zone, which moved the day boundary when the two differed.
See [Search Matchers](./search-matches.md#attribute-types).

### Scopes that skip sanitizing receive `false`

A scope listed in `ransackable_scopes_skip_sanitize_args` now receives a bare
`false` instead of being skipped, so it can be driven by a yes / no / any
select. Other scopes still treat `false` as an unticked checkbox. See
[Other notes](../going-further/other-notes.md#scopes-and-false).

### Joins already on the relation are reused

A search on a relation that already joins a table, through `joins`,
`left_outer_joins`, an eager-loaded `includes` or a previous search, now
reuses that join. Before, the association was joined again under a fresh
alias, which multiplied rows for a `has_many` and could bind a condition to
the wrong one of two joins to the same table. A query that depended on the
duplicate is unlikely, but row counts from such searches will change. The
joins Ransack adds are now stashed on the relation's `left_outer_joins`
rather than its `joins`; code that inspected `joins_values` for them should
look at `left_outer_joins_values`. See
[Associations](../going-further/associations.md#searching-a-relation-that-already-has-joins).

### `sorts=` replaces instead of appending

`search.sorts = 'name asc'` now sets exactly that sort; before, it added to
whatever sorts the search already had, and `sorts = []` did nothing. Code that
relied on the append should call `build_sort` for each additional sort. See
[Sorting](./sorting.md#assigning-sorts).

### A scope wins over an attribute of the same name in the writer

`Search#build` already applied a `ransackable_scopes` entry before looking for
an attribute of the same name; the attribute writer and reader used by form
builders (`search.salary = 100`, `f.check_box :salary`) checked attributes
first and silently skipped the scope. They agree now.

### `ransack_alias` resolves through associations and in compounds

`author_name_cont` (alias on `Author`) and `text_or_author_name_cont` used to
produce SQL referring to columns that do not exist; they now expand the alias.
The alias name itself no longer needs to be in `ransackable_attributes`, and an
alias whose target does not exist raises under `ransack!` like any unknown
attribute. See
[Ransack Aliases](../going-further/other-notes.md#aliases-through-associations-and-in-compounds).

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
