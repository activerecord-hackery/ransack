---
sidebar_position: 3
title: Configuration
---



Ransack may be easily configured. The best place to put configuration is in an initializer file at `config/initializers/ransack.rb`, containing code such as:

```ruby
Ransack.configure do |config|

  # Change default search parameter key name.
  # Default key name is :q
  config.search_key = :query

  # Raise errors if a query contains an unknown predicate, attribute, combinator
  # or sort. Default is true (do not raise error on unknown conditions).
  config.ignore_unknown_conditions = false

  # Globally display sort links without the order indicator arrow.
  # Default is false (sort order indicators are displayed).
  # This can also be configured individually in each sort link (see the README).
  config.hide_sort_order_indicators = true

  # By default, Ransack displays sort order indicator arrows with HTML codes, but
  # these can be overridden. `up_arrow` is shown when the column is sorted
  # descending and `down_arrow` when it is sorted ascending: the arrow names the
  # direction the link will sort in next, not the current one.
  config.custom_arrows = {
    up_arrow:   '<i class="fa fa-long-arrow-up"></i>', # default: '&#9660;'
    down_arrow: 'U+02193',                             # default: '&#9650;'
    default_arrow: 'U+11047'                           # default: nil 
  }

  # Ransack sanitizes many values in your custom scopes into booleans.
  # You can turn this off for custom scopes.
  config.sanitize_custom_scope_booleans = false

  # Configure a default predicate if an unknown predicate is passed; setting it to
  # e.g. 'eq' allows for allowing for exact matches by just the attribute name.
  config.default_predicate = 'eq'

  # Where NULLs are placed when sorting.
  config.fields_sort_option = :nulls_first # or e.g. :nulls_always_last

  # Strip leading and trailing whitespace from string search values.
  # Default is true.
  config.strip_whitespace = false

  # Treat blank values as conditions to search for, rather than as absent.
  # Default is true (blank values are ignored).
  config.ignore_blank_values = false

  # Name the SQL dialect explicitly instead of detecting it from the adapter.
  # Default is nil (detect). One of :postgresql, :mysql, :sqlite, :generic.
  config.dialect = :postgresql
end
```

## SQL dialect

Nearly everything Ransack generates goes through Arel, which renders it for
whichever database the connection uses. Two things depend on the database
directly: whether a case-insensitive predicate such as `i_cont` needs the
column wrapped in `LOWER()` (PostgreSQL has `ILIKE`, so it does not), and
which function the `length_*` predicates call (`CHAR_LENGTH` on PostgreSQL
and MySQL, `LENGTH` elsewhere).

Ransack decides these from the class of the model's connection adapter, and
an adapter that subclasses one of Rails' own inherits its dialect: the
`postgis` adapter is a subclass of the PostgreSQL adapter and is treated as
PostgreSQL, `trilogy` and `mysql2` share a parent and are both MySQL. Any
other adapter gets the `:generic` dialect, which uses only standard SQL.

If an adapter speaks a known dialect without inheriting from the Rails adapter
for it, name the dialect:

```ruby
Ransack.configure { |config| config.dialect = :postgresql }
```

The setting is global, so it is not suitable for an application that connects
to different kinds of database from different models; there, rely on
detection.

## Whitespace stripping

By default Ransack strips leading and trailing whitespace from string search
values, so a stray space pasted into a search box does not change the result:

```ruby
Person.ransack(name_cont: "  Ernie  ").result.to_sql
# ... WHERE "people"."name" LIKE '%Ernie%'
```

Stripping applies at every level of the parameters, including values nested
inside `g:` groupings and `c:` conditions:

```ruby
Person.ransack(g: [{ name_cont: "  Ernie  ", m: 'or' }]).result.to_sql
# ... WHERE "people"."name" LIKE '%Ernie%'
```

It can be turned off globally, or per search:

```ruby
Ransack.configure { |config| config.strip_whitespace = false }

Person.ransack({ name_cont: "  Ernie  " }, strip_whitespace: false)
```

:::note

Before Ransack 5.0 only top-level values were stripped, so the same search
behaved differently depending on whether it was written in the shorthand or the
grouped form. See
[#1414](https://github.com/activerecord-hackery/ransack/issues/1414).

:::

## Blank values

By default Ransack ignores a condition whose value is blank — an empty string,
or an array of only blank values. This is what makes an HTML search form behave
sensibly: a form submitted with its fields left empty returns every record
rather than none.

```ruby
Person.ransack(name_eq: "").result.to_sql
# => SELECT "people".* FROM "people"
```

For a JSON API this is often the wrong default, because there an empty value is
usually an explicit filter rather than an untouched form field. Setting
`ignore_blank_values` to `false` makes Ransack search for the blank value
instead of dropping it:

```ruby
Ransack.configure { |config| config.ignore_blank_values = false }

Person.ransack(name_eq: "").result.to_sql
# => SELECT "people".* FROM "people" WHERE "people"."name" = ''

Person.ransack(id_in: []).result.to_a
# => []   (an empty allowlist matches nothing, rather than matching everything)
```

A `nil` value is ignored under either setting, so params that were never sent
are still not turned into conditions.

On a non-string column a blank has no literal to compare against, so it is
treated as `NULL`: `parent_id_eq: ""` becomes `parent_id IS NULL`, and the
same applies to boolean and date columns. Inside an `_in` or with a comparison
such as `_gt`, a blank matches nothing at all rather than everything.

:::caution

Do not turn this off for a search backed by an HTML form. A blank text input
posts `""`, so with `ignore_blank_values = false` an untouched field becomes
`WHERE column = ''` and the form returns nothing.

:::

## Sorting NULLs

`fields_sort_option` controls where `NULL`s are placed when sorting:

| Value | Ascending | Descending |
| --- | --- | --- |
| `nil` (default) | backend default | backend default |
| `:nulls_first` | `NULLS FIRST` | `NULLS LAST` |
| `:nulls_last` | `NULLS LAST` | `NULLS FIRST` |
| `:nulls_always_first` | `NULLS FIRST` | `NULLS FIRST` |
| `:nulls_always_last` | `NULLS LAST` | `NULLS LAST` |

```ruby
Ransack.configure { |config| config.fields_sort_option = :nulls_first }

Person.ransack(s: 'name asc').result.to_sql
# ... ORDER BY "people"."name" ASC NULLS FIRST
```

:::note

This was called `postgres_fields_sort_option` before Ransack 5.0, and was built
by interpolating SQL fragments. It now goes through Arel's `nulls_first` /
`nulls_last` nodes, so it works on every database Arel renders them for,
including MySQL, where Arel emulates them as `ORDER BY col IS NULL, col`
(Rails 7.2 and later). The old name still works.

:::

## Custom search parameter key name

Sometimes there are situations when the default search parameter name cannot be used, for instance,
if there are two searches on one page. Another name may be set using the `search_key` option in the `ransack` or `search` methods in the controller, and in the `@search_form_for` method in the view.

### In the controller

```ruby
@search = Log.ransack(params[:log_search], search_key: :log_search)
# or
@search = Log.search(params[:log_search], search_key: :log_search)
```

### In the view

The form helpers read the key from the search object, so nothing extra is
needed:

```erb
<%= search_form_for @search %>
<%= sort_link(@search) %>
```

This emits `log_search[...]` field names rather than the default `q[...]`.

:::note

Before Ransack 5.0 the form helpers ignored a per-search `search_key` and always
used the global default, so the key had to be repeated as `as: :log_search`
(`scope:` for `search_form_with`). Passing it explicitly still works and still
wins. See [#1118](https://github.com/activerecord-hackery/ransack/issues/1118).

:::
