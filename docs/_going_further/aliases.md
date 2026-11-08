---
title: Aliases
description: Give long attribute paths short names with ransack_alias, for searching
  and sorting.
nav_order: 3
---

You can customize the attribute names for your Ransack searches by using a
`ransack_alias`. This is particularly useful for long attribute names that are
necessary when querying associations or multiple columns.

```ruby
class Post < ActiveRecord::Base
  belongs_to :author

  # Abbreviate :author_first_name_or_author_last_name to :author
  ransack_alias :author, :author_first_name_or_author_last_name
end
```

Now, rather than using `:author_first_name_or_author_last_name_cont` in your
form, you can simply use `:author_cont`. This serves to produce more expressive
query parameters in your URLs.

```erb
<%= search_form_for @q do |f| %>
  <%= f.label :author_cont %>
  <%= f.search_field :author_cont %>
<% end %>
```

You can also use `ransack_alias` for sorting.

```ruby
class Post < ActiveRecord::Base
  belongs_to :author

  # Abbreviate :author_first_name to :author
  ransack_alias :author, :author_first_name
end
```

Now, you can use `:author` instead of `:author_first_name` in a `sort_link`.

```erb
<%= sort_link(@q, :author) %>
```

Note that using `:author_first_name_or_author_last_name_cont` would produce an invalid sql query. In those cases, Ransack ignores the sorting clause.

## Aliases through associations and in compounds

An alias is resolved wherever its name appears: on its own, as a segment of an
`_or_` / `_and_` name, and after an association path when it is defined on
the associated model.

```ruby
class Author < ActiveRecord::Base
  ransack_alias :name, :first_name_or_last_name
end

class Post < ActiveRecord::Base
  belongs_to :author
  ransack_alias :text, :title_or_body
end

Post.ransack(author_name_cont: 'a')        # first_name OR last_name on authors
Post.ransack(text_or_author_name_cont: 'a') # title OR body OR first_name OR last_name
```

An alias that expands to a compound joins with its own combinator, so combine
it with the same one: `text_and_author_name_cont` would mix `_or_` and
`_and_`, which a strict search rejects (see
[Simple Mode](../_getting_started/simple-mode.md)).

The alias name itself does not need to be in `ransackable_attributes`; the
attributes it expands to do. An alias whose target is not a searchable
attribute is ignored, or raises `Ransack::InvalidSearchError` under
`ransack!`, like any other unknown attribute.

Before Ransack 6.0 an alias was only resolved on the searched model and only
as the whole name: `author_name_cont` and `text_or_author_name_cont` produced
SQL referring to columns that do not exist.
