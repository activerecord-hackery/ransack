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

## Sorting on Association Attributes

You can sort on attributes of associated models by using the association name followed by the attribute name:

```ruby
# Sort by the name of the associated category
@q = Post.ransack(s: 'category_name asc')
@posts = @q.result

# Sort by attributes of nested associations
@q = Post.ransack(s: 'category_section_title desc')
@posts = @q.result
```

### Sorting on Globalized/Translated Attributes

When working with internationalized models (like those using the Globalize gem), special care is needed when sorting on translated attributes of associations. The simplest approach is to use the `sort_link` helper directly with the translation attribute:

```erb
<!-- This works perfectly for sorting on translated attributes -->
<%= sort_link @q, :translations_name %>
<%= sort_link @q, :category_translations_name %>
```

For programmatic sorting, let Ransack handle the joins first:

```ruby
# Let Ransack establish the necessary joins for sorting
@q = Book.ransack(s: 'category_translations_name asc')
@books = @q.result.joins(:translations)

# For complex scenarios with multiple translations
@q = Book.ransack(s: 'category_translations_name asc')
@books = @q.result.includes(:translations, category: :translations)
```

This ensures that Ransack properly handles the join dependencies between your main model's translations and the associated model's translations.

## Unknown sorts

A sort on an attribute that is not in `ransortable_attributes`, or that does
not exist, is dropped silently. Any other sorts in the same request still
apply, but the model's default ordering does not: once a sort list is given,
Ransack replaces the default order, so a request whose only sort is invalid
comes back with no `ORDER BY` at all. Under a strict search (`ransack!`, or
`ignore_unknown_conditions = false`) an invalid sort raises
`Ransack::InvalidSearchError` instead, the same way an unknown attribute in a
condition does. A sort backed by a `sort_by_<attribute>_<direction>` scope is
always accepted.

```ruby
Person.ransack!(s: 'secret_column asc')
# Ransack::InvalidSearchError: Invalid sort term secret_column
```

Before Ransack 6.0 a strict search checked only conditions, and an invalid sort
was dropped silently.
