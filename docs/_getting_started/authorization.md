---
title: Authorization
description: Allowlist the attributes, associations, scopes and sorts a search may
  use, in the model or with strong parameters.
nav_order: 3
---

By default, searching and sorting are not authorized on any column of your model
and no class methods/scopes are allowlisted.

Ransack adds four methods to `ActiveRecord::Base` that you can redefine as
class methods in your models to apply selective authorization:

- `ransackable_attributes`
- `ransackable_associations`
- `ransackable_scopes`
- `ransortable_attributes`

Here is how these four methods could be implemented in your application:

```ruby
  # `ransackable_attributes` returns searchable column names
  # and any defined ransackers as an array of strings.
  #
  def ransackable_attributes(auth_object = nil)
    %w(title body) + _ransackers.keys
  end

  # `ransackable_associations` returns the names
  # of searchable associations as an array of strings.
  #
  def ransackable_associations(auth_object = nil)
    %w[author]
  end

  # `ransortable_attributes` by default returns the names
  # of all attributes available for sorting as an array of strings.
  #
  def ransortable_attributes(auth_object = nil)
    ransackable_attributes(auth_object)
  end

  # `ransackable_scopes` by default returns an empty array
  # i.e. no class methods/scopes are authorized.
  # For overriding with an allowlist, return an array of *symbols*.
  #
  def ransackable_scopes(auth_object = nil)
    []
  end
```

Any values not returned from these methods will be ignored by Ransack, i.e.
they are not authorized.

## Searching everything

Ransack also defines `authorizable_ransackable_attributes` and
`authorizable_ransackable_associations`, which return every column, ransacker
and alias, and every association. To restore the pre-4.0 behaviour where
everything is searchable, delegate to them once in the base class:

```ruby
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.ransackable_attributes(auth_object = nil)
    authorizable_ransackable_attributes
  end

  def self.ransackable_associations(auth_object = nil)
    authorizable_ransackable_associations
  end
end
```

Think before doing this in an application that exposes search params to
users: it makes `encrypted_password`, `reset_token` and every other column
searchable. They are also a convenient base for an exclusion list:
`authorizable_ransackable_attributes - %w[encrypted_password]`.

For models that inherit from `ActiveRecord::Base` directly (some gems define
their own), put the two methods in a module and extend every model with it
from an initializer: `ActiveSupport.on_load(:active_record) { extend TheModule }`.

## Strong parameters instead of model allowlists

The model allowlists decide what any caller may search. A controller often
knows better, per action and per user, and Rails already gives it the tool:
strong parameters. A model that defines none of `ransackable_attributes`,
`ransackable_associations` and `ransortable_attributes` hands the decision to
the controller. A search built from an `ActionController::Parameters` the
controller has permitted may then use every permitted key that names a real
column, ransacker, alias or association:

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  belongs_to :author
  # no ransackable_attributes, ransackable_associations or ransortable_attributes
end

# app/controllers/articles_controller.rb
def index
  @q = Article.ransack(search_params)
  @articles = @q.result
end

private

def search_params
  params.fetch(:q, {}).permit(:title_cont, :author_name_cont, :created_at_gteq, :s, s: [])
end
```

What is permitted is the condition key, so `title_cont` allows exactly that
and not `title_eq`. `s` is a string for a single sort and an array for
several, hence both forms. Use `fetch` rather than `require`, because a request
with no search is a normal request.

A model that defines a list keeps it, and the list applies on top of the
controller's permit: a key must be permitted *and* in the list. Nothing
changes for a model that already has its lists, and giving a model a list is
how to restrict what any controller may permit for it. Each model on the path
is asked for itself, so `author_name_cont` above consults `Author`'s lists if
`Author` has them, whatever `Article` defines.

A permitted key must still name something that exists, so a typo is dropped,
or raises under `ransack!`, as before. Three things hold whatever the model
defines:

- `ransackable_scopes` is always consulted. A permitted condition key can
  never call a class method the model has not listed. (The
  `sort_by_<attribute>_<direction>` convention for sort scopes is separate:
  it is reachable by name, takes nothing from the request, and permitting
  neither opens nor closes it.)
- A plain Hash has no permitted flag, so a search built in the console, a job
  or a test needs the model lists and raises without them, as before.
- Unpermitted parameters need the model lists too.

Sorting is the one place where `permit` cannot express a list. Permitting `s`
permits the key, not the column names inside its value, so on a model with no
list a permitted `s` can sort by any column, ransacker or alias, and through
any association. Where sorting has to stay restricted, define
`ransortable_attributes` on the model, or validate the value in the
controller before passing it on:

```ruby
SORTS = %w[title created_at].freeze

def search_params
  permitted = params.fetch(:q, {}).permit(:title_cont, :s)
  permitted.delete(:s) unless SORTS.include?(permitted[:s].to_s.split.first)
  permitted
end
```

<div class="warning custom-block" markdown="1">
<p class="custom-block-title">Warning</p>

`permit(q: {})`, which advanced mode's `g` and `c` groupings need, permits
everything under `q`, and Ransack cannot tell that apart from an explicit
list. For a model with no allowlist, that action can search and sort every
column and association. Permit the exact nested shape instead, or give the
model a list.
</div>

All four methods can receive a single optional parameter, `auth_object`. When
you call the search or ransack method on your model, you can provide a value
for an `auth_object` key in the options hash which can be used by your own
overridden methods.

Here is an example that puts all this together, adapted from
[this blog post by Ernie Miller](https://ernie.io/2012/05/11/why-your-ruby-class-macros-might-suck-mine-did/).
In an `Article` model, add the following `ransackable_attributes` class method
(preferably private):

```ruby
class Article < ActiveRecord::Base
  def self.ransackable_attributes(auth_object = nil)
    if auth_object == :admin
      # allow all attributes for admin
      column_names + _ransackers.keys
    else
      # allow only the title and body attributes for other users
      %w(title body)
    end
  end

  private_class_method :ransackable_attributes
end
```

The allowlists may be given as strings or as symbols — `%w[title body]` and
`%i[title body]` behave identically.

<div class="info custom-block" markdown="1">
<p class="custom-block-title">Note</p>

Before Ransack 5.0 a symbol allowlist was compared against strings without
normalising, so `%i[title body]` matched nothing and every search on those
attributes was silently ignored. See
[#1538](https://github.com/activerecord-hackery/ransack/issues/1538).
</div>

Here is example code for the `articles_controller`:

```ruby
class ArticlesController < ApplicationController
  def index
    @q = Article.ransack(params[:q], auth_object: set_ransack_auth_object)
    @articles = @q.result
  end

  private

  def set_ransack_auth_object
    current_user.admin? ? :admin : nil
  end
end
```

Trying it out in `rails console`:

```ruby
> Article
=> Article(id: integer, person_id: integer, title: string, body: text)

> Article.ransackable_attributes
=> ["title", "body"]

> Article.ransackable_attributes(:admin)
=> ["id", "person_id", "title", "body"]

> Article.ransack(id_eq: 1).result.to_sql
=> SELECT "articles".* FROM "articles"  # Note that search param was ignored!

> Article.ransack({ id_eq: 1 }, { auth_object: nil }).result.to_sql
=> SELECT "articles".* FROM "articles"  # Search param still ignored!

> Article.ransack({ id_eq: 1 }, { auth_object: :admin }).result.to_sql
=> SELECT "articles".* FROM "articles"  WHERE "articles"."id" = 1
```

That's it! Now you know how to allow/block various elements in Ransack.
