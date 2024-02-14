---
sidebar_position: 6
title: Error Handling
---

Ransack can be configured to raise errors with attributes, predicates or sorting misusing

## Configuring error raising

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

The error raised by Ransack is `Ransack::InvalidSearchError`:

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

Same way, Ransack with raise an error related to invalid `sorting` argument. If an invalid
sorting value is passed and Ransack is enabled to raise errors, it will raise the same `Ransack::InvalidSearchError` error:

```ruby
Article.ransack!(content_eq: 'Ernie', sorts: 1234)
# Ransack::InvalidSearchError: Invalid sorting parameter provided
```

## Rescuing errors

If you want, it's possible to rescue `Ransack::InvalidSearchError` to handle an API response instead
of having this error massing a request. For example, if can add something like this on our `ApplicationController`:

```ruby
class ApplicationController < ActionController::Base
  rescue_from Ransack::InvalidSearchError, with: :invalid_response

  private

  def invalid_response
    render 'shared/errors'
  end
end
```

Here `Ransack::InvalidSearchError` is being rescued and a view `shared/errors` is rendered. If you want, it's also possible
to use this same strategy when using API-only applications.
