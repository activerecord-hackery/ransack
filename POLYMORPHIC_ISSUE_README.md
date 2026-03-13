# Polymorphic Filtering Issue Reproduction

This PR reproduces the polymorphic filtering inconsistency issue described in the GitHub issue.

## Problem

When using Ransack to filter records with OR conditions between polymorphic foreign keys, the query fails with:

```
ArgumentError: Polymorphic associations do not support computing the class
```

This is inconsistent because:
1. Single polymorphic foreign key filtering works fine (`from_id_eq`)
2. OR conditions that include non-polymorphic fields work fine (`id_or_from_id_or_to_id_eq`)
3. The error occurs even though we're only filtering by ID values, not accessing the polymorphic associations

## Example Model

```ruby
class Message < ApplicationRecord
  belongs_to :user, class_name: 'Person'
  belongs_to :from, polymorphic: true
  belongs_to :to, polymorphic: true
end
```

## Failing Cases

These should work but currently raise errors:

```ruby
# Core issue from GitHub report
Message.ransack(from_id_or_to_id_eq: '123').result.count
# => ArgumentError: Polymorphic associations do not support computing the class

# Reverse order
Message.ransack(to_id_or_from_id_eq: '123').result.count  
# => ArgumentError: Polymorphic associations do not support computing the class

# Mix of regular and polymorphic FK
Message.ransack(user_id_or_from_id_eq: '123').result.count
# => ArgumentError: Polymorphic associations do not support computing the class
```

## Working Cases

These work correctly:

```ruby
# Single polymorphic FK
Message.ransack(from_id_eq: '123').result.count
# => Works fine

# OR with non-polymorphic field (workaround from issue)
Message.ransack(id_or_from_id_or_to_id_eq: '123').result.count  
# => Works fine

# No polymorphic FKs involved
Message.ransack(user_id_or_id_eq: '123').result.count
# => Works fine
```

## Expected Behavior

OR conditions between polymorphic foreign keys should work just like regular foreign keys since:
1. We're only filtering by ID values, not joining to the polymorphic associations
2. No polymorphic class computation should be needed for simple ID comparisons
3. The behavior should be consistent with single polymorphic FK filtering

## Test Files

- `spec/ransack/adapters/active_record/polymorphic_spec.rb` - Comprehensive RSpec test suite
- `test_polymorphic_issue.rb` - Simple standalone test runner
- `spec/support/schema.rb` - Added Message model and database schema
- `spec/blueprints/messages.rb` - Blueprint for Message model

## Running Tests

To run the RSpec tests:
```bash
bundle exec rspec spec/ransack/adapters/active_record/polymorphic_spec.rb
```

To run the simple test runner:
```bash
ruby test_polymorphic_issue.rb
```

## Root Cause

The issue appears to be in Ransack's attribute resolution logic, which incorrectly tries to compute the polymorphic class even when only filtering by foreign key values in OR conditions.