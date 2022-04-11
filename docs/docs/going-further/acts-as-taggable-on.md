---
title: Acts-as-taggable-on
sidebar_position: 13
---

If you have an `ActiveRecord` model and you're using [acts-as-taggable-on](https://github.com/mbleigh/acts-as-taggable-on),
chances are you might want to search on tagged fields.

Suppose you have this model:

```rb
class Task < ApplicationRecord
  acts_as_taggable_on :projects
end
```

and you have the following two instances of `Task`:

```rb
{ id: 1, name: 'Clean up my room',        projects: [ 'Home', 'Personal' ] }
{ id: 2, name: 'Complete math exercises', projects: [ 'Homework', 'Study' ] }
```

When you're writing a `Ransack` search form, you can choose any of the following options:

```erb
<%= search_form_for @search do |f| %>
  <%= f.text_field :projects_name_in   %> <!-- option a -->
  <%= f.text_field :projects_name_eq   %> <!-- option b -->
  <%= f.text_field :projects_name_cont %> <!-- option c -->
<% end %>
```

### Option a - match keys exactly

Option `a` will match keys exactly. This is the solution to choose if you want to distinguish 'Home' from 'Homework': searching for 'Home' will return just the `Task` with id 1. It also allows searching for more than one tag at once (comma separated):
- `Home, Personal` will return task 1
- `Home, Homework` will return task 1 and 2

### Option b - match key combinations

Option `b` will match all keys exactly. This is the solution if you wanna search for specific combinations of tags:
- `Home` will return nothing, as there is no Task with just the `Home` tag
- `Home, Personal` will return task 1

### Option c - match substrings

Option `c` is used to match substrings. This is useful when you don't care for the exact tag, but only for part of it:
- `Home` will return task 1 and 2 (`/Home/` matches both `"Home"` and `"Homework"`)
