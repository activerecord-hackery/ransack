---
sidebar_position: 1
title: Associations
---

### Associations

You can easily use Ransack to search for objects in `has_many` and `belongs_to`
associations.

Given these associations...

```ruby
class Employee < ActiveRecord::Base
  belongs_to :supervisor

  # has attributes first_name:string and last_name:string
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

... and a controller...

```ruby
class SupervisorsController < ApplicationController
  def index
    @q = Supervisor.ransack(params[:q])
    @supervisors = @q.result.includes(:department, :employees)
  end
end
```

... you might set up your form like this...

```erb
<%= search_form_for @q do |f| %>
  <%= f.label :last_name_cont %>
  <%= f.search_field :last_name_cont %>

  <%= f.label :department_title_cont %>
  <%= f.search_field :department_title_cont %>

  <%= f.label :employees_first_name_or_employees_last_name_cont %>
  <%= f.search_field :employees_first_name_or_employees_last_name_cont %>

  <%= f.submit "search" %>
<% end %>
...
<%= content_tag :table do %>
  <%= content_tag :th, sort_link(@q, :last_name) %>
  <%= content_tag :th, sort_link(@q, :department_title) %>
  <%= content_tag :th, sort_link(@q, :employees_last_name) %>
<% end %>
```

If you have trouble sorting on associations, try using an SQL string with the
pluralized table (`'departments.title'`,`'employees.last_name'`) instead of the
symbolized association (`:department_title)`, `:employees_last_name`).

### Searching a relation that already has joins

A search can start from a relation rather than a model, and the relation may
already join the tables the search needs — through `joins`,
`left_outer_joins`, an `includes` that will be eager loaded, or a previous
search. Ransack reuses those joins: the condition is bound to the alias
Active Record gives the existing join, and no second join is added.

```ruby
Supervisor.joins(:department).where(departments: { title: 'Sales' })
          .ransack(department_title_cont: 'Eng').result.to_sql
# ... INNER JOIN "departments" ON ... WHERE "departments"."title" = 'Sales'
#     AND "departments"."title" LIKE '%Eng%' ESCAPE '\'

Supervisor.joins(:department, :backup_department)   # both belongs_to Department
          .ransack(backup_department_title_eq: 'Ops').result.to_sql
# ... INNER JOIN "departments" ON ...
#     INNER JOIN "departments" AS "backup_departments_supervisors" ON ...
#     WHERE "backup_departments_supervisors"."title" = 'Ops'
```

This also covers the alias Active Record picks when a `where` hash is keyed by
the association name (`where(department: { ... })` joins `departments` as
`department`), and a search chained onto the result of another search.

Before Ransack 6.0 the join tree was built from the model class alone, so a
join already on the relation was joined a second time under a new alias, which
multiplied rows for a `has_many`, and a condition could land on the wrong one
of two joins to the same table.

The joins Ransack adds itself are `LEFT OUTER JOIN`s, so a search on an
association does not drop records that have nothing associated unless the
condition itself does. To search with inner joins, join the association on the
relation first.
