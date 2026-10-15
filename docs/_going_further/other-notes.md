---
title: Other notes
description: DISTINCT selects, Action Text, encrypted attributes, unknown conditions
  and OR grouping.
nav_order: 14
---

## Problem with DISTINCT selects

If passed `distinct: true`, `result` will generate a `SELECT DISTINCT` to
avoid returning duplicate rows, even if conditions on a join would otherwise
result in some. It generates the same SQL as calling `uniq` on the relation.

Please note that for many databases, a sort on an associated table's columns
may result in invalid SQL with `distinct: true` -- in those cases, you
will need to modify the result as needed to allow these queries to work.

For example, you could call joins and includes on the result which has the
effect of adding those tables columns to the select statement, overcoming
the issue, like so:

```ruby
def index
  @q = Person.ransack(params[:q])
  @people = @q.result(distinct: true)
              .includes(:articles)
              .joins(:articles)
              .page(params[:page])
end
```

If the above doesn't help, you can also use ActiveRecord's `select` query
to explicitly add the columns you need, which brute force's adding the
columns you need that your SQL engine is complaining about, you need to
make sure you give all of the columns you care about, for example:

```ruby
def index
  @q = Person.ransack(params[:q])
  @people = @q.result(distinct: true)
              .select('people.*, articles.name, articles.description')
              .page(params[:page])
end
```

Another method to approach this when using Postgresql is to use ActiveRecords's `.includes` in combination with `.group` instead of `distinct: true`.

For example:
```ruby
def index
  @q = Person.ransack(params[:q])
  @people = @q.result
              .group('persons.id')
              .includes(:articles)
              .page(params[:page])
end

```

A final way of last resort is to call `to_a.uniq` on the collection at the end
with the caveat that the de-duping is taking place in Ruby instead of in SQL,
which is potentially slower and uses more memory, and that it may display
awkwardly with pagination if the number of results is greater than the page size.

For example:

```ruby
def index
  @q = Person.ransack(params[:q])
  @people = @q.result.includes(:articles).page(params[:page]).to_a.uniq
end
```

## Problem with Globalized Attributes and Sorting

When using internationalization gems like [Globalize](https://github.com/globalize/globalize), you may encounter issues when trying to sort on translated attributes of associations while also having pre-existing joins to translation tables.

**Problem scenario:**
```ruby
# This may fail to generate proper joins:
Book.joins(:translations).ransack({ s: ['category_translations_name asc'] }).result
```

**Solution:**
The simplest and most effective approach is to use the `sort_link` helper directly with the translation attribute:

```erb
<!-- This works perfectly for sorting on translated attributes -->
<%= sort_link @search, :translations_name %>
<%= sort_link @search, :category_translations_name %>
```

For programmatic sorting, let Ransack establish the sorting joins first, then add your additional joins:

```ruby
# Let Ransack handle the sorting joins first
search = Book.ransack({ s: ['category_translations_name asc'] })
results = search.result.joins(:translations)

# Or use includes for complex scenarios
search = Book.ransack({ s: ['category_translations_name asc'] })
results = search.result.includes(:translations, category: :translations)
```

This ensures that Ransack properly handles the join dependencies between your main model's translations and the associated model's translations.

### `PG::UndefinedFunction: ERROR: could not identify an equality operator for type json`

If you get the above error while using `distinct: true` that means that
one of the columns that Ransack is selecting is a `json` column.
PostgreSQL does not provide comparison operators for the `json` type.  While
it is possible to work around this, in practice it's much better to convert those
to `jsonb`, as [recommended by the PostgreSQL documentation](https://www.postgresql.org/docs/9.6/static/datatype-json.html).

## Searching Action Text

A rich text attribute is an ordinary `has_one` association to
`ActionText::RichText`, so it is searched like any association once both sides
are allowlisted:

```ruby
# config/initializers/ransack.rb
ActiveSupport.on_load(:action_text_rich_text) do
  def self.ransackable_attributes(auth_object = nil)
    %w[body]
  end
end

class Post < ApplicationRecord
  has_rich_text :content

  def self.ransackable_associations(auth_object = nil)
    %w[rich_text_content]
  end
end

Post.ransack(rich_text_content_body_cont: 'hello')
```

The body is stored as HTML, so tag names and attributes match too. Keep a
plain-text column alongside if that matters.

## Encrypted attributes

A column declared with `encrypts :email, deterministic: true` can be searched
with the equality predicates (`eq`, `not_eq`, `in`, `not_in`): Ransack casts
the value through the attribute type, so Active Record encrypts it before the
comparison. The `LIKE` predicates (`cont`, `start`, `end` and the `i_` forms)
cannot match part of a ciphertext, and a non-deterministic column cannot be
searched at all. Neither is something Ransack can change.

## Handling unknown predicates or attributes

By default, Ransack will ignore any unknown predicates or attributes:

```ruby
Article.ransack(unknown_attr_eq: 'Ernie').result.to_sql
=> SELECT "articles".* FROM "articles"
```

Ransack may be configured to raise an error if passed an unknown predicate or
attributes, by setting the `ignore_unknown_conditions` option to `false` in your
Ransack initializer file at `config/initializers/ransack.rb`:

```ruby
Ransack.configure do |c|
  # Raise errors if a query contains an unknown predicate or attribute.
  # Default is true (do not raise error on unknown conditions).
  c.ignore_unknown_conditions = false
end
```

```ruby
Article.ransack(unknown_attr_eq: 'Ernie')
# Ransack::InvalidSearchError (Invalid search term unknown_attr_eq)
```

As an alternative to setting a global configuration option, the `.ransack!`
class method also raises an error if passed an unknown condition:

```ruby
Article.ransack!(unknown_attr_eq: 'Ernie')
# Ransack::InvalidSearchError: Invalid search term unknown_attr_eq
```

This is equivalent to the `ignore_unknown_conditions` configuration option,
except it may be applied on a case-by-case basis.

## Grouping queries by OR instead of AND

The default `AND` grouping can be changed to `OR` by adding `m: 'or'` to the
query hash.

You can easily try it in your controller code by changing `params[:q]` in the
`index` action to `params[:q].try(:merge, m: 'or')` as follows:

```ruby
def index
  @q = Artist.ransack(params[:q].try(:merge, m: 'or'))
  @artists = @q.result
end
```
Normally, if you wanted users to be able to toggle between `AND` and `OR`
query grouping, you would probably set up your search form so that `m` was in
the URL params hash, but here we assigned `m` manually just to try it out
quickly.

Alternatively, trying it in the Rails console:

```ruby
artists = Artist.ransack(name_cont: 'foo', style_cont: 'bar', m: 'or')
=> Ransack::Search<class: Artist, base: Grouping <conditions: [
  Condition <attributes: ["name"], predicate: cont, values: ["foo"]>,
  Condition <attributes: ["style"], predicate: cont, values: ["bar"]>
  ], combinator: or>>

artists.result.to_sql
=> "SELECT \"artists\".* FROM \"artists\"
    WHERE ((\"artists\".\"name\" LIKE '%foo%'
    OR \"artists\".\"style\" LIKE '%bar%'))"
```

The combinator becomes `or` instead of the default `and`, and the SQL query
becomes `WHERE...OR` instead of `WHERE...AND`.

This works with associations as well. Imagine an Artist model that has many
Memberships, and many Musicians through Memberships:

```ruby
artists = Artist.ransack(name_cont: 'foo', musicians_email_cont: 'bar', m: 'or')
=> Ransack::Search<class: Artist, base: Grouping <conditions: [
  Condition <attributes: ["name"], predicate: cont, values: ["foo"]>,
  Condition <attributes: ["musicians_email"], predicate: cont, values: ["bar"]>
  ], combinator: or>>

artists.result.to_sql
=> "SELECT \"artists\".* FROM \"artists\"
    LEFT OUTER JOIN \"memberships\"
      ON \"memberships\".\"artist_id\" = \"artists\".\"id\"
    LEFT OUTER JOIN \"musicians\"
      ON \"musicians\".\"id\" = \"memberships\".\"musician_id\"
    WHERE ((\"artists\".\"name\" LIKE '%foo%'
    OR \"musicians\".\"email\" LIKE '%bar%'))"
```
