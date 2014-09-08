# Change Log
All notable changes to this project from August 2014 on will be documented here.

## Unreleased
### Added

*   Add `not_true` and `not_false` predicates and update the "Basic Searching"
    wiki.

    Fixes #123, #353.

    *Pedro Chambino*

*   README documentation explaining how to group queries by `OR` instead of the
    default `AND`.

    *Jon Atack*
    
*   README documentation explaining how to do Authorization (whitelisting).

    *Jon Atack*

### Fixed

*   Fixed the params hash being modified by `Search.new` and the Ransack scope.

    *Daniel Rikowski*

*   Apply default scope conditions for association joins (Rails 3).

    Avoid selecting records from joins that would normally be filtered out
    if they were selected from the base table. Only applies to Rails 3, as
    this issue was fixed in Rails 4.

    *Andrew Vit*

*   Fixed incoherent code examples in the README Associations section that
    mixed `q#` and `search#`.

    *Jon Atack*


## Version 1.3.0 - 2014-08-23
### Added

*   Search scopes by popular demand.

*   `JOINS` merging.

*   `OR` grouping on base search.

*   Authorizations for attributes, associations, sorts and scopes.

*   Improved boolean predicates’ handling of `false` values.

*   Allow configuring Ransack to raise on instead of ignore unknown search
    conditions.

*   Allow passing blank values to search without crashing.

*   Wildcard escaping compatibility for SQL Server databases.

*   Various I18n translations.
