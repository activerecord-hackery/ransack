# Change Log
All notable changes to this project from August 2014 on will be documented here.

## Unreleased
### Added

*   Add `not_true` and `not_false` predicates and update the "Basic Searching"
    wiki.

    Fixes #123, #353.

    *Pedro Chambino*

*   Start a CHANGELOG.
*   Add new documentation in the README explaining how to group queries by `OR`
    instead of the default `AND` using the `m: 'or'` combinator.

    *Jon Atack*

### Changed

*   Rewrite/improve much of the README doc, including the Associations section
    code examples and the Authorizations section showing how to whitelist
    attributes, associations, sorts and scopes.
    
    *Jon Atack*

### Fixed

*   Fix the params hash being modified by `Search.new` and the Ransack scope.

    *Daniel Rikowski*

*   Apply default scope conditions for association joins (Rails 3).

    Avoid selecting records from joins that would normally be filtered out
    if they were selected from the base table. Only applies to Rails 3, as
    this issue was fixed in Rails 4.

    *Andrew Vit*

*   Fix incoherent code examples in the README Associations section that mixed
    up `@q` and `@search`.

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
