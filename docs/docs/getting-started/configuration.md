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

  # Postgres has a nulls first / nulls last option, this can be configured.
  config.postgres_fields_sort_option = :nulls_first # or e.g. :nulls_always_last

  # Strip leading and trailing whitespace from string search values.
  # Default is true.
  config.strip_whitespace = false

  # Treat blank values as conditions to search for, rather than as absent.
  # Default is true (blank values are ignored).
  config.ignore_blank_values = false
end
```

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

:::caution

Do not turn this off for a search backed by an HTML form. A blank text input
posts `""`, so with `ignore_blank_values = false` an untouched field becomes
`WHERE column = ''` and the form returns nothing.

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
