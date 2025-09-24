---
sidebar_position: 5
title: Merging searches
---

## Chainable Search Methods (New!)

The easiest way to combine searches is using the new chainable `and` and `or` methods:

```ruby
# Simple OR operation
search_parents = Person.ransack(parent_name_eq: "A")
search_children = Person.ransack(children_name_eq: "B")

combined_search = search_parents.or(search_children)
results = combined_search.result

# Simple AND operation  
search_name = Person.ransack(name_cont: "John")
search_email = Person.ransack(email_cont: "example.com")

combined_search = search_name.and(search_email)
results = combined_search.result

# Chained operations
search1 = Person.ransack(name_eq: "Alice")
search2 = Person.ransack(name_eq: "Bob") 
search3 = Person.ransack(name_eq: "Charlie")

# Find records matching any of the three names
combined_search = search1.or(search2).or(search3)
results = combined_search.result

# Mixed AND/OR operations
search_johns = Person.ransack(name_eq: "John")
search_admins = Person.ransack(role_eq: "admin")
search_managers = Person.ransack(role_eq: "manager")

# Find Johns who are admins, OR anyone who is a manager
combined_search = search_johns.and(search_admins).or(search_managers)
results = combined_search.result
```

This approach automatically handles context sharing and join management, making it much simpler than the manual approach below.

## Manual Approach (Advanced)

To find records that match multiple searches, it's possible to merge all the ransack search conditions into an ActiveRecord relation to perform a single query. In order to avoid conflicts between joined table names it's necessary to set up a shared context to track table aliases used across all the conditions before initializing the searches:

```ruby
shared_context = Ransack::Context.for(Person)

search_parents = Person.ransack(
  { parent_name_eq: "A" }, context: shared_context
)

search_children = Person.ransack(
  { children_name_eq: "B" }, context: shared_context
)

shared_conditions = [search_parents, search_children].map { |search|
  Ransack::Visitor.new.accept(search.base)
}

Person.joins(shared_context.join_sources)
  .where(shared_conditions.reduce(&:or))
  .to_sql
```
Produces:
```sql
SELECT "people".*
FROM "people"
LEFT OUTER JOIN "people" "parents_people"
  ON "parents_people"."id" = "people"."parent_id"
LEFT OUTER JOIN "people" "children_people"
  ON "children_people"."parent_id" = "people"."id"
WHERE (
  ("parents_people"."name" = 'A' OR "children_people"."name" = 'B')
  )
ORDER BY "people"."id" DESC
```

The manual approach gives you more control but requires more setup. For most use cases, the chainable methods provide a simpler and more intuitive API.
