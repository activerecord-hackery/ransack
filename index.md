# Ransack

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
MySQL, MariaDB and SQLite. See [Installation](/ransack/getting-started/)
to add it to your app.
