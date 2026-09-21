---
title: Custom predicates
parent: Going further
nav_order: 2
---

If you'd like to add your own custom Ransack predicates:

```ruby
# config/initializers/ransack.rb

Ransack.configure do |config|
  config.add_predicate 'equals_diddly', # Name your predicate
    # What non-compound ARel predicate will it use? (eq, matches, etc)
    arel_predicate: 'eq',
    # Format incoming values as you see fit. (Default: Don't do formatting)
    formatter: proc { |v| "#{v}-diddly" },
    # Validate a value. An "invalid" value won't be used in a search.
    # Below is default.
    validator: proc { |v| v.present? },
    # Should compounds be created? Will use the compound (any/all) version
    # of the arel_predicate to create a corresponding any/all version of
    # your predicate. (Default: true)
    compounds: true,
    # Force a specific column type for type-casting of supplied values.
    # (Default: use type from DB column)
    type: :string,
    # Use LOWER(column on database).
    # (Default: false)
    case_insensitive: true
end
```
You can check all Arel predicates [here](https://github.com/rails/rails/blob/main/activerecord/lib/arel/predications.rb).

### What a formatter returns

The formatter runs once per value and its return value is quoted as a single
literal, so it cannot build a piece of SQL. For an `in` / `not_in` predicate
that takes one delimited string, return an `Array` and Ransack quotes each
element:

```ruby
Ransack.configure do |config|
  config.add_predicate 'in_list', arel_predicate: 'in',
    formatter: proc { |v| v.split(';') }
end

Person.ransack(name_in_list: 'Aaron;Ernie').result.to_sql
# ... WHERE "people"."name" IN ('Aaron', 'Ernie')
```

Returning `"Aaron','Ernie"` instead gives `IN ('Aaron'',''Ernie')`: the string
is one value, and treating it as SQL would be an injection vector.

If Arel does not have the predicate you are looking for, consider monkey patching it:

```ruby
# config/initializers/ransack.rb

module Arel
  module Predications
    def gteq_or_null(other)
      left = gteq(other)
      right = eq(nil)
      left.or(right)
    end
  end
end

Ransack.configure do |config|
  config.add_predicate 'gteq_or_null', arel_predicate: 'gteq_or_null'
end
```
