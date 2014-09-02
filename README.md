# Ransack

[![Build Status](https://travis-ci.org/activerecord-hackery/ransack.svg)]
(https://travis-ci.org/activerecord-hackery/ransack)
[![Gem Version](https://badge.fury.io/rb/ransack.svg)]
(http://badge.fury.io/rb/ransack)

Ransack is a rewrite of [MetaSearch]
(https://github.com/activerecord-hackery/meta_search)
created by [Ernie Miller](http://twitter.com/erniemiller)
and maintained by [Ryan Bigg](http://twitter.com/ryanbigg),
[Jon Atack](http://twitter.com/jonatack) and a great group of [contributors]
(https://github.com/activerecord-hackery/ransack/graphs/contributors).
While it supports many of the same features as MetaSearch, its underlying
implementation differs greatly from MetaSearch,
and backwards compatibility is not a design goal.

Ransack enables the creation of both simple and
[advanced](http://ransack-demo.herokuapp.com/users/advanced_search)
search forms against your application's models (demo source code
[here](https://github.com/activerecord-hackery/ransack_demo)).
If you're looking for something that simplifies query generation at the model
or controller layer, you're probably not looking for Ransack (or MetaSearch,
for that matter). Try [Squeel](https://github.com/activerecord-hackery/squeel)
instead.

## Getting started

Because ActiveRecord has been evolving quite a bit, your friendly Ransack is
available in several flavors! Take your pick:

In your Gemfile, for the last officially released gem compatible with Rails
3.x, 4.0 and 4.1 (for Rails 4.2, use the dedicated `rails-4.2` branch described
below for now):

```ruby
gem 'ransack'
```

Or if you want to use the latest updates on the Ransack master branch:

```ruby
gem 'ransack', github: 'activerecord-hackery/ransack'
```

If you are using Rails 4.1, you may prefer the dedicated [Rails 4.1 branch]
(https://github.com/activerecord-hackery/ransack/tree/rails-4.1) which
contains the latest updates, supports only 4.1, and is lighter and somewhat
faster:

```ruby
gem 'ransack', github: 'activerecord-hackery/ransack', branch: 'rails-4.1'
```

Similarly, if you are using Rails 4.0, you may prefer the dedicated
[Rails 4 branch](https://github.com/activerecord-hackery/ransack/tree/rails-4)
for the same reasons:

```ruby
gem 'ransack', github: 'activerecord-hackery/ransack', branch: 'rails-4'
```

Last but definitely not least, an experimental [Rails 4.2 branch]
(https://github.com/activerecord-hackery/ransack/tree/rails-4.2) is available:

```ruby
gem 'ransack', github: 'activerecord-hackery/ransack', branch: 'rails-4.2'
```

## Usage

Ransack can be used in one of two modes, simple or advanced.

### Simple Mode

This mode works much like MetaSearch, for those of you who are familiar with
it, and requires very little setup effort.

If you're coming from MetaSearch, things to note:

  1. The default param key for search params is now `:q`, instead of `:search`.
  This is primarily to shorten query strings, though advanced queries (below)
  will still run afoul of URL length limits in most browsers and require a
  switch to HTTP POST requests. This key is [configurable]
  (https://github.com/activerecord-hackery/ransack/wiki/Configuration).

  2. `form_for` is now `search_form_for`, and validates that a Ransack::Search
  object is passed to it.

  3. Common ActiveRecord::Relation methods are no longer delegated by the
  search object. Instead, you will get your search results (an
  ActiveRecord::Relation in the case of the ActiveRecord adapter) via a call to
  `Search#result`. If passed `distinct: true`, `result` will generate a `SELECT
  DISTINCT` to avoid returning duplicate rows, even if conditions on a join
  would otherwise result in some.

  Please note that for many databases, a sort on an associated table's columns
  will result in invalid SQL with `distinct: true` -- in those cases, you're on
  your own, and will need to modify the result as needed to allow these queries
  to work. Thankfully, 9 times out of 10, sort against the search's base is
  sufficient, though, as that's generally what's being displayed on your
  results page.

####In your controller

```ruby
def index
  @q = Person.search(params[:q])
  @people = @q.result(distinct: true)
end
```
or without `distinct:true`, for sorting on an associated table's columns (in
this example, with preloading each Person's Articles and pagination):

```ruby
def index
  @q = Person.search(params[:q])
  @people = @q.result.includes(:articles).page(params[:page])
end
```

####In your view

The two primary Ransack view helpers are `search_form_for` and `sort_link`,
which are defined in
[Ransack::Helpers::FormHelper](lib/ransack/helpers/form_helper.rb).

#####1. Ransack's `search_form_for` helper replaces `form_for` for creating the view search form:

```erb
<%= search_form_for @q do |f| %>
  <%= f.label :name_cont %>
  <%= f.search_field :name_cont %>
  <%= f.label :articles_title_start %>
  <%= f.search_field :articles_title_start %>
  <%= f.submit %>
<% end %>
```

`cont` (contains) and `start` (starts with) are just two of the available
search predicates. See [Constants]
(https://github.com/activerecord-hackery/ransack/blob/master/lib/ransack/constants.rb)
for a full list and the [wiki]
(https://github.com/activerecord-hackery/ransack/wiki/Basic-Searching)
for more information.

The `search_form_for` answer format can be set like this:
```erb
<%= search_form_for(@q, format: :pdf) do |f| %>

<%= search_form_for(@q, format: :json) do |f| %>
```

#####2. Ransack's `sort_link` helper creates table headers that are sortable links:

```erb
<%= content_tag :th, sort_link(@q, :name) %>
```
Additional options can be passed after the column attribute, like a different
column title or a default sort order:

```erb
<%= content_tag :th, sort_link(@q, :name, 'Last Name', default_order: :desc) %>
```

### Advanced Mode

"Advanced" searches (ab)use Rails' nested attributes functionality in order to
generate complex queries with nested AND/OR groupings, etc. This takes a bit
more work but can generate some pretty cool search interfaces that put a lot of
power in the hands of your users. A notable drawback with these searches is
that the increased size of the parameter string will typically force you to use
the HTTP POST method instead of GET. :(

This means you'll need to tweak your routes...

```ruby
resources :people do
  collection do
    match 'search' => 'people#search', via: [:get, :post], as: :search
  end
end
```

... and add another controller action ...

```ruby
def search
  index
  render :index
end
```

... and update your `search_form_for` line in the view ...

```erb
<%= search_form_for @q, url: search_people_path,
                        html: { method: :post } do |f| %>
```

Once you've done so, you can make use of the helpers in [Ransack::Helpers::FormBuilder](lib/ransack/helpers/form_builder.rb) to
construct much more complex search forms, such as the one on the
[demo page](http://ransack-demo.heroku.com) (source code [here](https://github.com/activerecord-hackery/ransack_demo)).

### Ransack #search method

Ransack will try to to make `#search` available in your models, but in the case
that `#search` has already been defined, you can use `#ransack` instead. For
example the following would be equivalent:

```ruby
Article.search(params[:q])
Article.ransack(params[:q])
```

### Associations

You can easily use Ransack to search for objects in `has_many` and `belongs_to`
associations.

Given you have these associations ...

```ruby
class Employee < ActiveRecord::Base
  belongs_to :supervisor

  # has attribute last_name:string
end

class Department < ActiveRecord::Base
  has_many :supervisors

  # has attribute title:string
end

class Supervisor < ActiveRecord::Base
  belongs_to :department
  has_many :employees

  # has attribute last_name:string
end
```

... and a controller ...

```ruby
class SupervisorsController < ApplicationController
  def index
    @q = Supervisor.search(params[:q])
    @supervisors = @q.result.includes(:department, :employees)
  end
end
```

... you might set up your form like this ...

```erb
<%= search_form_for @q do |f| %>
  <%= f.label :last_name_cont %>
  <%= f.search_field :last_name_cont %>

  <%= f.label :department_title_cont %>
  <%= f.search_field :department_title_cont %>

  <%= f.label :employees_last_name_cont %>
  <%= f.search_field :employees_last_name_cont %>

  <%= f.submit "search" %>
<% end %>
...
<%= content_tag :table %>
  <%= content_tag :th, sort_link(@q, :last_name) %>
  <%= content_tag :th, sort_link(@q, 'departments.title') %>
  <%= content_tag :th, sort_link(@q, 'employees.last_name') %>
<% end %>
```

### Using Ransackers to add custom search functions via Arel

The main premise behind Ransack is to provide access to
**Arel predicate methods**. Ransack provides special methods, called
_ransackers_, for creating additional search functions via Arel. More
information about `ransacker` methods can be found [here in the wiki]
(https://github.com/activerecord-hackery/ransack/wiki/Using-Ransackers).
Feel free to contribute working `ransacker` code examples to the wiki!

### Using SimpleForm

If you want to combine form builders of ransack and SimpleForm, just set the
RANSACK_FORM_BUILDER environment variable before Rails started, e.g. in
``config/application.rb`` before ``require 'rails/all'`` and of course use
``gem 'simple_form'`` in your ``Gemfile``:

```ruby
require File.expand_path('../boot', __FILE__)

ENV['RANSACK_FORM_BUILDER'] = '::SimpleForm::FormBuilder'

require 'rails/all'
```

### Authorization (whitelisting/blacklisting)

By default, searching and sorting are authorized on any column of your model.
Ransack adds four methods to `ActiveRecord::Base` that you can redefine as
class methods in your models to apply selective authorization:
`ransackable_attributes`, `ransackable_associations`, `ransackable_scopes` and
`ransortable_attributes`.

Here is how these four methods are implemented in Ransack:

```ruby
def ransackable_attributes(auth_object = nil)
  # Returns the string names of all columns and any defined ransackers.
  column_names + _ransackers.keys
end

def ransackable_associations(auth_object = nil)
  # Returns the names of all associations.
  reflect_on_all_associations.map { |a| a.name.to_s }
  end

def ransackable_scopes(auth_object = nil)
  # For overriding with a whitelist of symbols.
  []
end

def ransortable_attributes(auth_object = nil)
  # Here so users can overwrite the attributes that show up in the sort_select.
  ransackable_attributes(auth_object)
end
```

Any values not returned from these methods will be ignored by Ransack.

All four methods can receive a single optional parameter, `auth_object`. When
you call the search or ransack method on your model, you can provide a value
for an `auth_object` key in the options hash which can be used by your own
overridden methods.

Here is an example that puts all this together, adapted from
[this blog post by Ernie Miller]
(http://erniemiller.org/2012/05/11/why-your-ruby-class-macros-might-suck-mine-did/).
In an `Article` model, add the following `ransackable_attributes` class method
(preferably private):
```ruby
# article.rb
class Article < ActiveRecord::Base

  private

  def self.ransackable_attributes(auth_object = nil)
    if auth_object == :admin
      # whitelist all attributes for admin
      super
    else
      # whitelist only the title and body attributes for other users
      super & %w(title body) 
    end
  end
end
```
Here is example code for the `articles_controller`:
```ruby
# articles_controller.rb
class ArticlesController < ApplicationController

  def index
    @q = Article.search(params[:q], auth_object: set_ransack_auth_object)
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

> Article.search(id_eq: 1).result.to_sql
=> SELECT "articles".* FROM "articles"  # Note that search param was ignored!

> Article.search({ id_eq: 1 }, { auth_object: nil }).result.to_sql
=> SELECT "articles".* FROM "articles"  # Search param still ignored!

> Article.search({ id_eq: 1 }, { auth_object: :admin }).result.to_sql
=> SELECT "articles".* FROM "articles"  WHERE "articles"."id" = 1
```
That's it! Now you know how to whitelist/blacklist various elements in Ransack.

### Scopes

Continuing on from the preceding section, searching by scope requires defining
a whitelist of `ransackable_scopes` on the model class. By default, all class
methods (e.g. scopes) are ignored. Scopes will be applied for matching `true`
values, or for given values if the scope accepts a value:

```ruby
Employee.search({ active: true, hired_since: '2013-01-01' })

Employee.search({ salary_gt: 100_000 }, { auth_object: current_user })
```

### I18n

Ransack translation files are available in
[Ransack::Locale](lib/ransack/locale). You may also be interested in one of the
many translations for Ransack available at
http://www.localeapp.com/projects/2999.

## Contributions

To support the project:

* Use Ransack in your apps, and let us know if you encounter anything that's
broken or missing. A failing spec is awesome. A pull request with tests that
pass is even better! Before filing an issue or pull request, be sure to read
the [Contributing Guide](CONTRIBUTING.md).
* Spread the word on Twitter, Facebook, and elsewhere if Ransack's been useful
to you. The more people who are using the project, the quicker we can find and
fix bugs!

## Copyright

Copyright &copy; 2011-2014 [Ernie Miller](http://twitter.com/erniemiller)
