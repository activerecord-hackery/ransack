---
title: Polymorphic Searches
parent: Going further
nav_order: 16
---

When making searches from polymorphic models it is necessary to specify the type of model you are searching. 

For example:

Given two models

```ruby
class House < ActiveRecord::Base
  has_one :location, as: :locatable
end

class Location < ActiveRecord::Base
  belongs_to :locatable, polymorphic: true
end
```

Normally (without polymorphic relationship) you would be able to search as per below:

```ruby
Location.ransack(locatable_number_eq: 100).result
```

However when this is searched you will get the following error

```ruby
ActiveRecord::EagerLoadPolymorphicError: Can not eagerly load the polymorphic association :locatable
```

In order to search for locations by house number when the relationship is polymorphic you have to specify the type of records you will be searching and construct your search as below:

```ruby
Location.ransack(locatable_of_House_type_number_eq: 100).result
```

note the `_of_House_type_` added to the search key. This allows Ransack to correctly specify the table names in SQL join queries.

For namespaced models you should use a quoted string containing the standard Ruby module notation

```ruby
Location.ransack('locatable_of_Residences::House_type_number_eq' => 100).result
```

The type must name a model. A suffix naming anything else, such as a constant
that does not exist, a lowercase word or a class with no table, is not a
polymorphic reference, and the key is treated like any other unknown
attribute: ignored by default, or raised as `Ransack::InvalidSearchError` when
`ignore_unknown_conditions` is `false`.

```ruby
Location.ransack(locatable_of_Nowhere_type_number_eq: 100).result
# => every location; the condition is ignored

Location.ransack!(locatable_of_Nowhere_type_number_eq: 100)
# Ransack::InvalidSearchError: Invalid search term locatable_of_Nowhere_type_number_eq
```

{: .note }
> Before 6.0 the type was looked up with `Kernel.const_get`, so a suffix that
> named no constant raised `NameError` from the query string, whatever
> `ignore_unknown_conditions` was set to. See
> [#1738](https://github.com/activerecord-hackery/ransack/issues/1738).
