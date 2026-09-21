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

  # Raise errors if a query contains an unknown predicate or attribute.
  # Default is true (do not raise error on unknown conditions).
  config.ignore_unknown_conditions = false

  # Globally display sort links without the order indicator arrow.
  # Default is false (sort order indicators are displayed).
  # This can also be configured individually in each sort link (see the README).
  config.hide_sort_order_indicators = true

  # By default, Ransack displays sort order indicator arrows with HTML codes, but
  # these can be overridden.
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
end
```

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
`nulls_last`, so it applies to any backend Arel supports rather than only
PostgreSQL. The old name still works.

**MySQL is the exception** — it has no `NULLS FIRST` / `NULLS LAST` syntax and
Arel does not emulate it, so setting this option has no effect there. See
[#1373](https://github.com/activerecord-hackery/ransack/issues/1373).

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

```erb
<%= f.search_form_for @search, as: :log_search %>
<%= sort_link(@search) %>
```
