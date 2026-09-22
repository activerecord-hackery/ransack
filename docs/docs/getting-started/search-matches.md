---
title: Search Matchers
---

### Search Matchers

List of all possible predicates


| Predicate | Description | Notes |
| ------------- | ------------- |-------- |
| `*_eq`  | equal  | |
| `*_eq_any`  | equal to any of the provided values  | |
| `*_not_eq` | not equal | |
| `*_matches` | matches with `LIKE` | e.g. `q[email_matches]=%@gmail.com`|
| `*_does_not_match` | does not match with `LIKE` | |
| `*_matches_any` | Matches any | |
| `*_matches_all` | Matches all  | |
| `*_does_not_match_any` | Does not match any | |
| `*_does_not_match_all` | Does not match all | |
| `*_lt` | less than | |
| `*_lteq` | less than or equal | |
| `*_gt` | greater than | |
| `*_gteq` | greater than or equal | |
| `*_present` | not null and not empty | Example: `q[name_present]=1`. On string columns, SQL: `col IS NOT NULL AND col != ''`. On other column types the empty-string half is dropped, giving `col IS NOT NULL` |
| `*_blank` | is null or empty | On string columns, SQL: `col IS NULL OR col = ''`. On other column types, `col IS NULL` |
| `*_null` | is null | |
| `*_not_null` | is not null | |
| `*_in` | match any values in array | e.g. `q[name_in][]=Alice&q[name_in][]=Bob` |
| `*_not_in` | match none of values in array | |
| `*_lt_any` | Less than any |  SQL: `col < value1 OR col < value2` |
| `*_lteq_any` | Less than or equal to any | |
| `*_gt_any` | Greater than any | |
| `*_gteq_any` | Greater than or equal to any | |
| `*_lt_all` | Less than all | SQL: `col < value1 AND col < value2` |
| `*_lteq_all` | Less than or equal to all | |
| `*_gt_all` | Greater than all | |
| `*_gteq_all` | Greater than or equal to all | |
| `*_not_eq_all` | none of values in a set | |
| `*_start` | Starts with | SQL: `col LIKE 'value%'` |
| `*_not_start` | Does not start with | |
| `*_start_any` | Starts with any of | |
| `*_start_all` | Starts with all of | |
| `*_not_start_any` | Does not start with any of | |
| `*_not_start_all` | Does not start with all of | |
| `*_end` | Ends with | SQL: `col LIKE '%value'` |
| `*_not_end` | Does not end with | |
| `*_end_any` | Ends with any of | |
| `*_end_all` | Ends with all of | |
| `*_not_end_any` | | |
| `*_not_end_all` | | |
| `*_cont` | Contains value | uses `LIKE` |
| `*_cont_any` | Contains any of | |
| `*_cont_all` | Contains all of | |
| `*_not_cont` | Does not contain |
| `*_not_cont_any` | Does not contain any of | |
| `*_not_cont_all` | Does not contain all of | |
| `*_i_cont` | Contains value with case insensitive | uses `ILIKE` |
| `*_i_cont_any` | Contains any of values with case insensitive | |
| `*_i_cont_all` | Contains all of values with case insensitive | |
| `*_not_i_cont` | Does not contain with case insensitive |
| `*_not_i_cont_any` | Does not contain any of values with case insensitive | |
| `*_not_i_cont_all` | Does not contain all of values with case insensitive | |
| `*_length_eq` | string length equals | SQL: `LENGTH(col) = value` |
| `*_length_lt` | string length less than | |
| `*_length_lteq` | string length less than or equal | |
| `*_length_gt` | string length greater than | |
| `*_length_gteq` | string length greater than or equal | |
| `*_true` | is true | |
| `*_false` | is false | |


See full list: https://github.com/activerecord-hackery/ransack/blob/main/lib/ransack/locale/en.yml#L16

### Searching by string length

The `length_*` predicates compare the length of a column rather than its
contents, which saves reaching for a ransacker for something this common:

```ruby
Person.ransack(name_length_lteq: 3).result.to_sql
# ... WHERE LENGTH("people"."name") <= 3

Person.ransack(name_length_gt: 10).result
```

The function used depends on the backend: `CHAR_LENGTH` on PostgreSQL, PostGIS
and MySQL, `LENGTH` elsewhere. Both count characters rather than bytes for text
columns.
### Wildcards in `LIKE` predicates

The `LIKE`-based predicates — `cont`, `start`, `end`, their `i_`, `not_` and
`_any` / `_all` variants — treat the search term as a literal string, not as a
pattern. `%` and `_` in a user's input are escaped, and Ransack emits an
explicit `ESCAPE` clause so that escaping is honoured on every backend:

```ruby
Person.ransack(name_cont: "50%").result.to_sql
# => SELECT "people".* FROM "people" WHERE "people"."name" LIKE '%50\%%' ESCAPE '\'
```

This finds names containing the literal text `50%`, rather than names
containing `50` followed by anything.

To match with a pattern of your own, use `matches`, which passes the value
through unescaped:

```ruby
Person.ransack(email_matches: "%@example.com").result
```

:::note

Before Ransack 5.0 the escaping was applied only on MySQL and PostgreSQL, and
no `ESCAPE` clause was emitted. On SQLite and other backends a `%` or `_` in the
search term acted as a wildcard. See
[#1581](https://github.com/activerecord-hackery/ransack/issues/1581).

:::

### Searching `enum` attributes

An Active Record `enum` can be searched by its label rather than its underlying
value. Ransack casts the label before building the query:

```ruby
class Person < ApplicationRecord
  enum :temperament, { sanguine: 1, choleric: 2, melancholic: 3, phlegmatic: 4 }
end

Person.ransack(temperament_eq: 'choleric').result.to_sql
# ... WHERE "people"."temperament" = 2

Person.ransack(temperament_in: ['sanguine', 'choleric']).result.to_sql
# ... WHERE "people"."temperament" IN (1, 2)
```

This means a select built from `Person.temperaments.keys` can be posted
straight back to Ransack without translating the labels yourself.

### Date and time selects

Rails' date and time selects submit a value in pieces, `created_at(1i)` for
the year through `created_at(6i)` for the second, and Ransack folds them back
into one value the way Active Record does. The pieces come from the query
string, so a malformed one is dropped rather than raised on: a key with no
position, a position outside 1 to 16, or a piece for an attribute that was
also given whole. Before Ransack 4.4.2 an out-of-range position was used as
an array index, so a crafted request could make the server allocate an array
of any size (GHSA-vxc9-rm8f-p56j).

### Negative predicates on collections

On a `has_many`, `has_and_belongs_to_many` or `has_many :through`
association, a negative predicate (`not_eq`, `not_cont`, `not_in`, `not_start`
and the rest) means *no associated record matches the positive form*. It is
built as a correlated subquery rather than a join:

```ruby
Person.ransack(articles_title_not_eq: 'Draft').result.to_sql
# ... WHERE "people"."id" NOT IN (
#       SELECT "articles"."person_id" FROM "articles"
#       WHERE "articles"."person_id" = "people"."id"
#         AND NOT ("articles"."title" != 'Draft'))
```

That selects people none of whose articles is titled `Draft`, including people
with no articles. A join would instead select people who have *at least one*
article with a different title, which is a different question; ask it with a
scope or a ransacker if you need it.

`not_null` is the exception: `articles_title_not_null: true` means *at least
one* associated record has a value (`"people"."id" IN (SELECT ... WHERE
"articles"."title" IS NOT NULL)`), so it excludes people with no articles.

On a `belongs_to` or `has_one` the predicate is a plain condition on the
joined table, `"people"."name" != 'x'` after a `LEFT OUTER JOIN`. A record
with no associated record has `NULL` there, and `NULL != 'x'` is not true, so
it is excluded; add `_or_parent_id_null` style logic or a scope if you want
those included.
