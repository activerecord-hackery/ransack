---
sidebar_position: 10
title: How Ransack is built
---

This page is for anyone reading or changing Ransack's source. It describes the
pieces, where the boundary with Active Record is, and which parts of Active
Record Ransack reaches into.

## The pieces

A search goes through four stages. Each has a home under `lib/ransack/`.

| Stage | Where | What it does |
| --- | --- | --- |
| Parse | `search.rb`, `nodes/` | Turns the params hash into a tree of `Grouping`, `Condition`, `Attribute`, `Value` and `Sort` nodes. Nothing here knows about the database. |
| Resolve | `context.rb`, `active_record/context.rb` | Maps attribute names like `articles_title` onto tables, columns and the joins needed to reach them. |
| Build | `visitor.rb`, `predicate.rb`, `constants.rb` | Walks the node tree and produces Arel predicates and orderings. |
| Integrate | `active_record/` | Everything that touches Active Record: the class methods added to models, the join machinery, and the `Context` that evaluates the search into a relation. |

Around those sit `configuration.rb` (global options and the predicate registry),
`translate.rb` and `locale/` (i18n), `helpers/` (the form builder and view
helpers, loaded only when Action Controller is) and `ransacker.rb` (custom
attributes).

## The Active Record boundary

`Ransack::Context` is the seam. The generic class holds what every ORM would
need: binding attribute names to nodes, walking association paths, checking
the `ransackable_*` allowlists and chaining scopes. Everything that needs a real
database sits in the subclass `Ransack::ActiveRecord::Context`.

A context is chosen through a registry rather than a hard-coded check, so an
integration for another ORM can register its own:

```ruby
Ransack::Context.register do |object, options|
  MyOrm::Context.new(object, options) if object.is_a?(MyOrm::Document)
end
```

The resolver receives whatever was passed to `ransack` (a class or a relation)
and returns a context or `nil`. Ransack's own Active Record resolver is
registered in `lib/ransack/active_record/context.rb`. A context subclass
implements `relation_for`, `type_for`, `evaluate`, `attribute_method?`,
`table_for`, `klassify` and the join-building methods; the Active Record
context is the reference implementation.

## What Ransack takes from Active Record's internals

Active Record's public query interface cannot express two things Ransack
needs: an outer join that is added one association at a time on top of a
relation that already has joins, and a join through a polymorphic `belongs_to`
to one named class. To get them, `lib/ransack/active_record/` prepends small
modules onto three internal classes:

| Active Record class | Ransack module | Why |
| --- | --- | --- |
| `Associations::JoinDependency` | `JoinDependencyExtensions` | Accept `Ransack::ActiveRecord::Join` nodes in the association tree, and hand back the aliased tables for an association so a later correlated subquery can reuse them. |
| `Associations::JoinDependency::JoinAssociation` | `JoinAssociationExtensions` | Carry the join type and the polymorphic target class; build join constraints against tables Ransack already aliased. |
| `Reflection::AbstractReflection` | `ReflectionExtensions` | Add the `type = 'ClassName'` constraint when a polymorphic association is joined to one class. |

Before 6.0 these lived in a separate top-level `Polyamorous` namespace, a
remnant of the gem of that name that was merged into Ransack in 2019.

These are private APIs. They are the part of Ransack most likely to need
attention when a new Rails version ships, which is why the nightly CI job runs
the suite against Rails `main`. Keeping this list short, and moving items off
it as Active Record grows public equivalents, is an explicit goal.

Everything else goes through public API: `reflect_on_all_associations`,
`columns_hash`, `type_for_attribute`, `attribute_aliases`, `defined_enums`,
`arel_table`, the relation query methods, and the connection pool's schema
cache for column types.
