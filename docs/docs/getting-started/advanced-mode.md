---
sidebar_position: 2
title: Advanced Mode
---


"Advanced" searches Rails's nested attributes functionality in order to
generate complex queries with nested AND/OR groupings, etc. This takes a bit
more work but can generate some pretty cool search interfaces that put a lot of
power in the hands of your users.

A notable drawback with these searches is
that the increased size of the parameter string will typically force you to use
the HTTP POST method instead of GET.


## The search parameter structure

An advanced search is expressed as nested groupings. Each key has a short and a
long spelling, and the two are interchangeable:

| Short | Long | Meaning |
| --- | --- | --- |
| `g` | `groupings` | Nested groupings |
| `c` | `conditions` | The conditions in a grouping |
| `m` | `combinator` | How this grouping's members are joined |
| `a` | `attributes` | The attributes a condition applies to |
| `p` | `predicate` | The predicate to apply |
| `v` | `values` | The values to match against |

```ruby
Person.ransack(
  g: [
    { m: 'or', name_cont: 'Ernie', email_cont: 'ernie' }
  ]
)
```

Groupings nest, so you can express `(A OR B) AND (C OR D)`:

```ruby
Person.ransack(
  m: 'and',
  g: [
    { m: 'or', name_cont: 'Ernie', email_cont: 'ernie' },
    { m: 'or', salary_gteq: 50_000, parent_name_eq: 'Ruby' }
  ]
)
```

## Combinators

`m` (or `combinator`) takes `'and'` or `'or'`, and defaults to `'and'`. Case and
Symbols are accepted, so `'or'`, `'OR'`, `'Or'` and `:or` all mean the same:

```ruby
Person.ransack(g: [{ m: 'OR', name_eq: 'Ernie', email_eq: 'ernie@example.com' }])
# ... WHERE ("people"."name" = 'Ernie' OR "people"."email" = 'ernie@example.com')
```

An unrecognised combinator is ignored and the grouping falls back to `'and'`:

```ruby
Person.ransack(g: [{ m: 'nand', name_eq: 'Ernie', email_eq: 'ernie@example.com' }])
# ... WHERE ("people"."name" = 'Ernie' AND "people"."email" = 'ernie@example.com')
```

This is deliberate — a search built from user input should not blow up on a bad
parameter. If you would rather hear about it, use `ransack!`, or set
`ignore_unknown_conditions` to `false`, and an unrecognised combinator raises
just as an unknown predicate or attribute does:

```ruby
Person.ransack!(name_eq: 'Ernie', combinator: 'nand')
# ArgumentError: Invalid combinator nand
```

:::note

Before Ransack 5.0, `'OR'` and `:or` were not recognised and silently fell back
to `'and'` — a search that looked correct returned the wrong rows. See
[#1465](https://github.com/activerecord-hackery/ransack/pull/1465).

:::

## Tweak your routes

```ruby
resources :people do
  collection do
    match 'search' => 'people#search', via: [:get, :post], as: :search
  end
end
```

## Add a controller action

```ruby
def search
  index
  render :index
end
```

## Update your form

```erb
<%= search_form_for @q, url: search_people_path,
                        html: { method: :post } do |f| %>
```

Once you've done so, you can make use of the helpers in [Ransack::Helpers::FormBuilder](https://github.com/activerecord-hackery/ransack/blob/main/lib/ransack/helpers/form_builder.rb) to
construct much more complex search forms, such as the one on the
[demo app](http://ransack-demo.herokuapp.com/users/advanced_search)
(source code [here](https://github.com/activerecord-hackery/ransack_demo)).
