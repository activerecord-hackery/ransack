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


## Blank values

A condition whose value is blank is dropped before the query is built, so a
search form submitted with empty fields returns every record rather than none.
This applies to the low-level `c:` form as well as the shorthand:

```ruby
Person.ransack(children_name_eq: '').result.to_sql
# => SELECT "people".* FROM "people"

Person.ransack(c: { '0' => { a: ['children_name'], p: 'eq', v: [''] } }).result.to_sql
# => SELECT "people".* FROM "people"
```

Both forms drop the condition, so neither contributes a join. This applies at
any depth of nested groupings, under the short or long key spellings.

To search *for* a blank value instead of ignoring it, see
[`ignore_blank_values`](./configuration.md#blank-values).

:::note

Before Ransack 5.0 only the shorthand form was pruned. A `c:` condition with an
empty value still built its attribute and contributed a join, producing a
`LEFT OUTER JOIN` with no `WHERE` clause to go with it. See
[#1653](https://github.com/activerecord-hackery/ransack/pull/1653).

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
