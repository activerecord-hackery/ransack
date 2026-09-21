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

### Ruby 3.2 and Rails 7.2.2.1 or later are required

Ruby 3.1 reached end of life in March 2025 and no longer receives security
fixes. Ransack 6.0 requires Ruby 3.2 or later, which is also the floor for
Rails 8.0. If you are on Ruby 3.1 you are already limited to Rails 7.2; stay on
Ransack 5.x until you can upgrade Ruby.

The minimum Active Record version moves from 7.2.0 to 7.2.2.1, the December
2024 security release. Ransack carried a second copy of its join-building code
for the four earlier 7.2 patch releases; it is gone.

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
