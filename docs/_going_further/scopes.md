---
title: Scopes
description: Use allowlisted scopes and class methods as search conditions, and how
  they handle false.
nav_order: 4
---

A scope or class method can be used as a search condition once it is
allowlisted with `ransackable_scopes` (see [Authorization](../_getting_started/authorization.md)).
The allowlist is an array of *symbols*. By default, all class methods
(e.g. scopes) are ignored.
Scopes will be applied for matching `true` values, or for given values if the
scope accepts a value:

```ruby
class Employee < ActiveRecord::Base
  scope :activated, ->(boolean = true) { where(active: boolean) }
  scope :salary_gt, ->(amount) { where('salary > ?', amount) }

  # Scopes are just syntactical sugar for class methods, which may also be used:

  def self.hired_since(date)
    where('start_date >= ?', date)
  end

  def self.ransackable_scopes(auth_object = nil)
    if auth_object.try(:admin?)
      # allow admin users access to all three methods
      %i(activated hired_since salary_gt)
    else
      # allow other users to search on `activated` and `hired_since` only
      %i(activated hired_since)
    end
  end
end

Employee.ransack({ activated: true, hired_since: '2013-01-01' })

Employee.ransack({ salary_gt: 100_000 }, { auth_object: current_user })
```

Values such as `'true'` and `'1'` from a form are sanitized to booleans. Perhaps
you have `user_id: [1]` and you do not want Ransack to convert
1 into a boolean. (Values sanitized to booleans can be found in the
[constants.rb](https://github.com/activerecord-hackery/ransack/blob/main/lib/ransack/constants.rb#L28)).
To turn this off globally, and handle type conversions yourself, set
`sanitize_custom_scope_booleans` to false in an initializer file like
config/initializers/ransack.rb:

```ruby
Ransack.configure do |c|
  c.sanitize_custom_scope_booleans = false
end
```

To turn this off on a per-scope basis Ransack adds the following method to
`ActiveRecord::Base` that you can redefine to selectively override sanitization:

`ransackable_scopes_skip_sanitize_args`

Add the scope you wish to bypass this behavior to ransackable_scopes_skip_sanitize_args:

```ruby
def self.ransackable_scopes_skip_sanitize_args
  [:scope_to_skip_sanitize_args]
end
```

## Scopes and `false`

A bare `false` (or `'0'` / `'false'`, which are sanitized to `false`) is taken
to mean "this checkbox was not ticked", and the scope is not applied at all.
That is right for a scope with no argument, but wrong for a scope such as
`activated(boolean)` driven by a yes / no / any select, which needs to receive
`false`. List that scope in `ransackable_scopes_skip_sanitize_args`: it then
receives every value as given, including `false`, and can cast for itself:

```ruby
class Employee < ActiveRecord::Base
  # `true` is passed as a bare call, so the argument needs a default.
  scope :activated, ->(value = true) { where(active: ActiveModel::Type::Boolean.new.cast(value)) }

  def self.ransackable_scopes(auth_object = nil)
    %i(activated)
  end

  def self.ransackable_scopes_skip_sanitize_args
    %i(activated)
  end
end

Employee.ransack(activated: false).result   # WHERE "employees"."active" = FALSE
Employee.ransack(activated: '0').result     # the same, from a form
```

Wrapping the value in an array (`activated: [false]`) has always passed it
through and still does.

Scopes are a recent addition to Ransack and currently have a few caveats:
First, a scope involving child associations needs to be defined in the parent
table model, not in the child model. Second, scopes with an array as an
argument are not easily usable yet, because the array currently needs to be
wrapped in an array to function (see
[this issue](https://github.com/activerecord-hackery/ransack/issues/404)),
which is not compatible with Ransack form helpers. For this use case, it may be
better for now to use [ransackers](./ransackers.md) instead,
where feasible. Pull requests with solutions and tests are welcome!

## Scopes are always `AND`ed

A scope is applied by chaining it onto the relation, outside the condition
tree that `m: 'or'` and groupings govern, so it is always `AND`ed with the
rest of the search:

```ruby
Person.ransack(active: true, name_cont: 'foo', m: 'or').result.to_sql
# ... WHERE (active = 1) AND "people"."name" LIKE '%foo%' ESCAPE '\'
```

For something that must take part in an `OR`, use a
[ransacker](./ransackers.md) or a [custom predicate](./custom-predicates.md)
instead of a scope.
