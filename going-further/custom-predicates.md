# Custom predicates

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

## What a formatter returns

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

### Combining two conditions: `arel_node`

`arel_predicate` names one Arel method with one argument, so it cannot
combine two conditions on its own. For a predicate like `gteq_or_null`,
pass `arel_node` instead: a two-argument callable that receives the
attribute and the formatted values, and returns a finished Arel node
directly.

```ruby
# config/initializers/ransack.rb

Ransack.configure do |config|
  config.add_predicate 'gteq_or_null',
    arel_node: ->(attr, val) { attr.gteq(val).or(attr.eq(nil)) }
end
```

`val` is user-submitted search input. Pass it only through Arel methods such
as `attr.gteq(val)`, which quote it. Never interpolate it into a string or
pass it to `Arel.sql`: that is an injection vector. The callable must return an
Arel node, and Ransack raises `ArgumentError` for anything else, including
`nil`.

`arel_node` and `arel_predicate` are mutually exclusive on one predicate,
and `arel_node` has no compound (`_any`/`_all`) form, since those are
built by appending a suffix to an Arel method name.

Avoid monkey patching `Arel::Predications` to add a method like
`gteq_or_null` instead: the module is undocumented in every version of
ActiveRecord Ransack supports, and its internals differ between
versions.
