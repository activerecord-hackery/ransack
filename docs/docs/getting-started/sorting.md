---
title: Sorting
---


# Sorting

## Sorting in the View

You can add a form to capture sorting and filtering options together.

```erb
# app/views/posts/index.html.erb

<%= search_form_for @q do |f| %>
  <%= f.label :title_cont %>
  <%= f.search_field :title_cont %>

  <%= f.submit "Search" %>
<% end %>

<table>
  <thead>
    <tr>
      <th><%= sort_link(@q, :title, "Title") %></th>
      <th><%= sort_link(@q, :category, "Category") %></th>
      <th><%= sort_link(@q, :created_at, "Created at") %></th>
    </tr>
  </thead>

  <tbody>
    <% @posts.each do |post| %>
      <tr>
        <td><%= post.title %></td>
        <td><%= post.category %></td>
        <td><%= post.created_at.to_s(:long) %></td>
      </tr>
    <% end %>
  </tbody>
</table>
```

## Sorting in the Controller

To specify a default search sort field + order in the controller `index`:

```ruby
# app/controllers/posts_controller.rb
class PostsController < ActionController::Base
  def index
    @q = Post.ransack(params[:q])
    @q.sorts = 'title asc' if @q.sorts.empty?

    @posts = @q.result(distinct: true)
  end
end
```

Multiple sorts can be set by:

```ruby
# app/controllers/posts_controller.rb
class PostsController < ActionController::Base
  def index
    @q = Post.ransack(params[:q])
    @q.sorts = ['title asc', 'created_at desc'] if @q.sorts.empty?

    @posts = @q.result(distinct: true)
  end
end
```
