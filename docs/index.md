---
title: Ransack
description: Object-based searching for Active Record. Add search forms and sortable columns to a Rails application with plain Ruby and ERB.
layout: home
permalink: /
hero:
  name: Ransack
  text: Search for Active Record
  tagline: Search forms and sortable columns for your Rails app, in plain Ruby and ERB. No search server, no extra infrastructure.
  image:
    src: /assets/logo/activerecord-hackery.png
    alt: ActiveRecord Hackery
    width: 300
    height: 300
  actions:
    - theme: brand
      text: Get started
      link: /getting-started/
    - theme: alt
      text: Upgrading to 6.x
      link: /getting-started/upgrading/
    - theme: alt
      text: View on GitHub
      link: https://github.com/activerecord-hackery/ransack
features:
  - title: Simple mode
    details: One `search_form_for` and a `sort_link` give any model a search form and sortable columns.
    link: /getting-started/simple-mode/
  - title: Predicates
    details: Name the comparison in the parameter, `title_cont`, `price_gteq`, `deleted_at_null`, and Ransack writes the SQL.
    link: /getting-started/search-matches/
  - title: Associations
    details: Search and sort through associations by name, `author_name_cont`, with the joins built for you.
    link: /going-further/associations/
  - title: Advanced mode
    details: Nested groups of conditions, combined with `AND` and `OR`, for searches a flat form cannot express.
    link: /getting-started/advanced-mode/
  - title: Safe by default
    details: Nothing is searchable until a model allowlists it, or a controller permits it with strong parameters.
    link: /getting-started/authorization/
  - title: Ransackers
    details: Define your own searchable attributes in Arel, for dates, concatenations, JSON and anything SQL can compute.
    link: /going-further/ransackers/
---

## A search in three steps

Allow the attributes a search may use:

```ruby
class Post < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil)
    %w[title published_at]
  end
end
```

Build the search from the request:

```ruby
class PostsController < ApplicationController
  def index
    @q = Post.ransack(params[:q])
    @posts = @q.result
  end
end
```

Render a form and a sortable column:

```erb
<%= search_form_for @q do |f| %>
  <%= f.label :title_cont %>
  <%= f.search_field :title_cont %>
  <%= f.submit %>
<% end %>

<%= sort_link(@q, :published_at) %>
```

`GET /posts?q[title_cont]=ransack&q[s]=published_at+desc` then runs:

```sql
SELECT "posts".* FROM "posts"
WHERE "posts"."title" LIKE '%ransack%' ESCAPE '\'
ORDER BY "posts"."published_at" DESC
```

Ransack supports Rails 8.1 and 8.0 on Ruby 3.3 and later, on PostgreSQL,
MySQL, MariaDB and SQLite. See [Installation](_getting_started/installation.md)
to add it to your app.
