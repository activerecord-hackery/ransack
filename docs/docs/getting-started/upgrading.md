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
