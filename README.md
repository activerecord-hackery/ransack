# Ransack

[![Build Status](https://travis-ci.org/ernie/ransack.png?branch=master)](https://travis-ci.org/ernie/ransack)

Ransack is a rewrite of [MetaSearch](https://github.com/ernie/meta_search). While it
supports many of the same features as MetaSearch, its underlying implementation differs
greatly from MetaSearch, and _backwards compatibility is not a design goal._

Ransack enables the creation of both simple and [advanced](http://ransack-demo.herokuapp.com/users/advanced_search)
search forms against your application's models. If you're looking for something that
simplifies query generation at the model or controller layer, you're probably not looking
for Ransack (or MetaSearch, for that matter). Try
[Squeel](https://github.com/ernie/squeel) instead.

## Getting started

In your Gemfile:

For Rails 3:

```ruby
gem "ransack"  # Last officially released gem (Rails 3)
```

Or if you want to use the bleeding edge (Rails 3):

```ruby
gem "ransack", :git => "git://github.com/ernie/ransack.git" # Track git repo (Rails 3)
```

For Rails 4, specify the "rails-4" branch:

```ruby
gem "ransack", github: "ernie/ransack", branch: "rails-4" # Use rails 4 branch
```

## Usage

Ransack can be used in one of two modes, simple or advanced.

### Simple Mode

This mode works much like MetaSearch, for those of you who are familiar with it, and
requires very little setup effort.

If you're coming from MetaSearch, things to note:

  1. The default param key for search params is now `:q`, instead of `:search`. This is
     primarily to shorten query strings, though advanced queries (below) will still
     run afoul of URL length limits in most browsers and require a switch to HTTP
     POST requests. This key is
[configurable](https://github.com/ernie/ransack/wiki/Configuration)
  2. `form_for` is now `search_form_for`, and validates that a Ransack::Search object
     is passed to it.
  3. Common ActiveRecord::Relation methods are no longer delegated by the search object.
     Instead, you will get your search results (an ActiveRecord::Relation in the case of
     the ActiveRecord adapter) via a call to `Search#result`. If passed `:distinct => true`,
     `result` will generate a `SELECT DISTINCT` to avoid returning duplicate rows, even if
     conditions on a join would otherwise result in some.

     Please note that for many databases, a sort on an associated table's columns will
     result in invalid SQL with `:distinct => true` -- in those cases, you're on your own,
     and will need to modify the result as needed to allow these queries to work. Thankfully,
     9 times out of 10, sort against the search's base is sufficient, though, as that's
     generally what's being displayed on your results page.

In your controller:

```ruby
def index
  @q = Person.search(params[:q])
  @people = @q.result(distinct: true)
end
```

In your view:

```erb
<%= search_form_for @q do |f| %>
  <%= f.label :name_cont %>
  <%= f.text_field :name_cont %>
  <%= f.label :articles_title_start %>
  <%= f.text_field :articles_title_start %>
  <%= f.submit %>
<% end %>
```

`cont` (contains) and `start` (starts with) are just two of the available search predicates.
See [Constants](https://github.com/ernie/ransack/blob/master/lib/ransack/constants.rb) for a full list and the [wiki](https://github.com/ernie/ransack/wiki/Basic-Searching) for more description.

### Advanced Mode

"Advanced" searches (ab)use Rails' nested attributes functionality in order to generate
complex queries with nested AND/OR groupings, etc. This takes a bit more work but can
generate some pretty cool search interfaces that put a lot of power in the hands of
your users. A notable drawback with these searches is that the increased size of the
parameter string will typically force you to use the HTTP POST method instead of GET. :(

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
                        html: {method: :post} do |f| %>
```

Once you've done so, you can make use of the helpers in Ransack::Helpers::FormBuilder to
construct much more complex search forms, such as the one on the
[demo page](http://ransack-demo.heroku.com).

### has_many and belongs_to associations

You can easily use Ransack to search in associated objects.

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
    @search = Supervisor.search(params[:q])
    @supervisors = @search.result(distinct: true)
  end
end
```

... you might set up your form like this ...

```erb
<%= search_form_for @search do |f| %>
  <%= f.label :last_name_cont %>
  <%= f.text_field :last_name_cont %>

  <%= f.label :department_title_cont %>
  <%= f.text_field :department_title_cont %>

  <%= f.label :employees_last_name_cont %>
  <%= f.text_field :employees_last_name_cont %>

  <%= f.submit "search" %>
<% end %>
```


## Contributions

To support the project:

* Use Ransack in your apps, and let us know if you encounter anything that's broken or missing.
  A failing spec is awesome. A pull request is even better!
* Spread the word on Twitter, Facebook, and elsewhere if Ransack's been useful to you. The more
  people who are using the project, the quicker we can find and fix bugs!

## Copyright

Copyright &copy; 2011 [Ernie Miller](http://twitter.com/erniemiller)