# Change Log

## Master (unreleased)

*   Fix and a test to handle a scope of an array argument to `ransackable_scopes`
    ([#404](https://github.com/activerecord-hackery/ransack/issues/404))

## Version 1.6.3 - 2015-01-21

*   Fix a regression
    ([#496](https://github.com/activerecord-hackery/ransack/issues/496)) caused
    by [ee571fe](https://github.com/activerecord-hackery/ransack/commit/ee571fe)
    where passing a multi-parameter attribute (like `date_select`) raised
    `RuntimeError: can't add a new key into hash during iteration`, and add a
    regression spec for the issue.

    *Nate Berkopec*, *Jon Atack*

*   Update travis-ci to no longer test Rails 3.1 with Ruby 2.2 and speed up the test matrix.

*   Refactor Nodes::Condition.

    *Jon Atack*


## Version 1.6.2 - 2015-01-14

*   Fix a regression
    ([#494](https://github.com/activerecord-hackery/ransack/issues/494))
    where passing an array of routes to `search_form_for` no longer worked,
    and add a failing/passing test that would have caught the issue.

    *Daniel Rikowski*, *Jon Atack*


## Version 1.6.1 - 2015-01-14

*   Fix a regression with using `in` predicates caused by PR [#488](https://github.com/activerecord-hackery/ransack/pull/488)) and add a test.

*   README improvements to clarify `sort_link` syntax with associations and
    Ransack#search vs #ransack.

*   Default the Gemfile to Rails 4-2-stable.

    *Jon Atack*


## Version 1.6.0 - 2015-01-12
### Added

*   Add support for using Ransack with `Mongoid 4.0` without associations
    ([PR #407](https://github.com/activerecord-hackery/ransack/pull/407)).

    *Zhomart Mukhamejanov*

*   Add support and tests for passing stringy booleans for ransackable scopes
    ([PR #460](https://github.com/activerecord-hackery/ransack/pull/460)).

    *Josh Kovach*

*   Add an sort_link option to not display sort direction arrows
    ([PR #473](https://github.com/activerecord-hackery/ransack/pull/473)).

    *Fred Bergman*

*   Numerous documentation improvements to the README, Contributing Guide and
    wiki.

    *Jon Atack*

### Fixed

*   Fix passing arrays to ransackers with Rails 4.2 / Arel 6.0 (pull requests
    [#486](https://github.com/activerecord-hackery/ransack/pull/486) and
    [#488](https://github.com/activerecord-hackery/ransack/pull/488)).

    *Idean Labib*

*   Make `search_form_for`'s default `:as` option respect the custom search key
    if it has been set
    ([PR #470](https://github.com/activerecord-hackery/ransack/pull/470)).
    Prior to this change, if you set a custom `search_key` option in the
    Ransack initializer file, you'd have to also pass an `as: :whatever` option
    to all of the search forms. Fixes
    [#92](https://github.com/activerecord-hackery/ransack/issues/92).

    *Robert Speicher*

*   Fix sorting on polymorphic associations (missing downcase)
    ([PR #467](https://github.com/activerecord-hackery/ransack/pull/467)).

    *Eugen Neagoe*

*   Fix Rails 5 / Arel 5 compatibility after the Arel and Active Record API
    changed.

*   Fix and add tests for sort_link `default_order` parsing if the option is set
    as a string instead of symbol.

*   Fix and add a test to handle `nil` in options passed to sort_link.

*   Fix #search method name conflicts in the README.

    *Jon Atack*

### Changed

*   Refactor and DRY up FormHelper#SortLink. Encapsulate parsing into a
    Plain Old Ruby Object with few public methods and small, private functional
    methods. Limit mutations to explicit methods and mutate no ivars.

*   Numerous speed improvements by using more specific Ruby methods like:
      - `Hash#each_key` instead of `Hash#keys.each`
      - `#none?` instead of `select#empty?`
      - `#any?` instead of `#select` followed by `#any?`
      - `#flat_map` instead of `#flatten` followed by `#map`
      - `!include?` instead of `#none?`

*   Replace `string#freeze` instances with top level constants to reduce string
    allocations in Ruby < 2.1.

*   Remove unneeded `Ransack::` namespacing on most of the constants.

*   In enumerable methods, pass a symbol as an argument instead of a block.

*   Update Travis-ci for Rails 5.0.0 and 4-2-stable.

*   Update the Travis-ci tests and the Gemfile for Ruby 2.2.

*   Replace `#search` with `#ransack` class methods in the README and wiki
    code examples. Enabling the `#search` alias by default may possibly be
    deprecated in the next major release (Ransack v.2.0.0) to address
    [#369](https://github.com/activerecord-hackery/ransack/issues/369).

    *Jon Atack*


## Version 1.5.1 - 2014-10-30
### Fixed

*   Fix a regression caused by incorrect string constants in `context.rb`.

    *Kazuhiro Nishiyama*

### Added

*   Add base specs for search on fields with `_start` and `_end`.

    *Jon Atack*

*   Add a failing spec for detecting attribute fields containing `_and_` that
    needs to be fixed. Attribute names containing `_and_` and `_or_` are still
    not parsed/detected correctly.

    *Jon Atack*

### Changed

*   Remove duplicate code in `spec/support/schema.rb`.

    *Jon Atack*


## Version 1.5.0 - 2014-10-26
### Added

*   Add support for multiple sort fields and default orders in Ransack
    `sort_link` helpers
    ([PR #438](https://github.com/activerecord-hackery/ransack/pull/438)).

    *Caleb Land*, *James u007*

*   Add tests for `lteq`, `lt`, `gteq` and `gt` predicates. They are also
    tested in Arel, but testing them in Ransack has proven useful to detect
    issues.

    *Jon Atack*

*   Add tests for unknown attribute names.

    *Joe Yates*

*   Add tests for attribute names containing `_or_` and `_and_`.

    *Joe Yates*, *Jon Atack*

*   Add tests for attribute names ending with `_start` and `_end``.

    *Jon Atack*, *Timo Schilling*

*   Add tests for `start`, `not_start`, `end` and `not_end` predicates, with
    emphasis on cases when attribute names end with `_start` and `_end`.

    *Jon Atack*

### Fixed

*   Fix a regression where form labels for attributes through a `belongs_to`
    association without a translation for the attribute in the locales file
    would cause a "no implicit conversion of nil into Hash" crash instead of
    falling back on the attribute name. Added test coverage.

    *John Dell*, *Jon Atack*, *jasdeepgosal*

*   Fix the `form_helper date_select` spec that was failing with Rails 4.2 and
    master.

    *Jon Atack*

*   Improve `attribute_method?` parsing for attribute names containing `_and_`
    and `_or_`. Attributes named like `foo_and_bar` or `foo_or_bar` are
    recognized now instead of running failing checks for `foo` and `bar`.
    CORRECTION October 28, 2014: this feature is still not working!

    *Joe Yates*

*   Improve `attribute_method?` parsing for attribute names ending with a
    predicate like `_start` and `_end`. For instance, a `foo_start` attribute
    is now recognized instead of raising a NoMethodError.

    *Timo Schilling*, *Jon Atack*

### Changed

*   Reduce object allocations and memory footprint (with a slight speed gain as
    well) by extracting commonly used strings into top level constants and
    replacing calls to `#try` methods with simple nil checking.

    *Jon Atack*


## Version 1.4.1 - 2014-09-23
### Fixed

*   Fix README markdown so RubyGems documentation picks up the formatting correctly.

    *Jon Atack*


## Version 1.4.0 - 2014-09-23
### Added

*   Add support for Rails 4.2.0! Let us know if you encounter any issues.

    *Xiang Li*

*   Add `not_true` and `not_false` predicates and update the "Basic Searching"
    wiki. Fixes #123, #353.

    *Pedro Chambino*

*   Add `ro.yml` Romanian translation file.

    *Andreas Philippi*

*   Add new documentation in the README explaining how to group queries by `OR`
    instead of the default `AND` using the `m: 'or'` combinator.

*   Add new documentation in the README and in the source code comments
    explaining in detail how to handle whitelisting/authorization of
    attributes, associations, sorts and scopes.

*   Add new documentation in the README explaining in more detail how to use
    scopes for searching with Ransack.

*   Begin a CHANGELOG.

    *Jon Atack*

### Fixed

*   Fix singular/plural Active Record attribute translations.

    *Andreas Philippi*

*   Fix the params hash being modified by `Search.new` and the Ransack scope.

    *Daniel Rikowski*

*   Apply default scope conditions for association joins (fix for Rails 3).

    Avoid selecting records from joins that would normally be filtered out
    if they were selected from the base table. Only applies to Rails 3, as
    this issue was fixed in Rails 4.

    *Andrew Vit*

*   Fix incoherent code examples in the README Associations section that
    sometimes used `@q` and other times `@search`.

    *Jon Atack*

### Changed

*   Refactor Ransack::Translate.

*   Rewrite much of the Ransack README documentation, including the
    Associations section code examples and the Authorizations section detailing
    how to whitelist attributes, associations, sorts and scopes.

    *Jon Atack*


## Version 1.3.0 - 2014-08-23
### Added

*   Add search scopes by popular demand. Using `ransackable_scopes`, users can
    define whitelists for allowed model scopes on a parent table. Not yet
    implemented for associated models' scopes; scopes must be defined on the
    parent table.

    *Gleb Mazovetskiy*, *Andrew Vit*, *Sven Schwyn*

*   Add `JOINS` merging.

*   Add `OR` grouping on base search.

*   Allow authorizing/whitelisting attributes, associations, sorts and scopes.

*   Improve boolean predicates’ handling of `false` values.

*   Allow configuring Ransack to raise on instead of ignore unknown search
    conditions.

*   Allow passing blank values to search without crashing.

*   Add wildcard escaping compatibility for SQL Server databases.

*   Add various I18n translations.
