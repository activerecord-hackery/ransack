# Ransack

> Search everywhere and in a hurry!

[![Build Status](https://github.com/activerecord-hackery/ransack/workflows/test/badge.svg)](https://github.com/activerecord-hackery/ransack/actions)
[![Gem Version](https://badge.fury.io/rb/ransack.svg)](http://badge.fury.io/rb/ransack)

Ransack adds **searching and sorting to your Rails application** with plain Ruby
and ERB, without a search server or any other infrastructure.

Ransack is supported for Rails 8.1 on Ruby 3.4 and later, on Postgres, MySQL, Trilogy and SQLite.

```ruby
gem 'ransack'
```

```ruby
@q = Post.ransack(params[:q])
@posts = @q.result
```

```erb
<%= search_form_for @q do |f| %>
  <%= f.search_field :title_cont %>
<% end %>
<%= sort_link(@q, :published_at) %>
```

## Documentation

**[activerecord-hackery.github.io/ransack](https://activerecord-hackery.github.io/ransack/)**:
[getting started](https://activerecord-hackery.github.io/ransack/getting-started/),
[authorization](https://activerecord-hackery.github.io/ransack/getting-started/authorization/),
[predicates](https://activerecord-hackery.github.io/ransack/getting-started/search-matches/),
[upgrading](https://activerecord-hackery.github.io/ransack/getting-started/upgrading/)
and more. The site is built from the Markdown under [`docs/`](docs/).

## Getting help and contributing

* Questions belong in [GitHub Discussions](https://github.com/activerecord-hackery/ransack/discussions).
* Reproducible bugs belong in [Issues](https://github.com/activerecord-hackery/ransack/issues).
  Read the [Contributing Guide](CONTRIBUTING.md) first; a failing test is the best bug report.
* Report security vulnerabilities privately, through GitHub
  [private vulnerability reporting](https://github.com/activerecord-hackery/ransack/security/advisories/new)
  or the [Tidelift security contact](https://tidelift.com/security). See the
  [Security Policy](.github/SECURITY.md) for supported versions.

Ransack is maintained by volunteers. If it is useful to you, please consider
supporting us via [Open Collective](https://opencollective.com/ransack), or
through the [Tidelift Subscription](https://tidelift.com/subscription/pkg/rubygems-ransack?utm_source=rubygems-ransack&utm_medium=referral&utm_campaign=enterprise&utm_term=repo)
for commercial support.

## Contributors

Ransack is maintained by [Sean Carroll](https://github.com/scarroll32),
[Deivid Rodriguez](https://github.com/deivid-rodriguez),
[Greg Molnar](https://github.com/gregmolnar) and
[a great group of contributors](https://github.com/activerecord-hackery/ransack/graphs/contributors).
It was created by [Ernie Miller](http://twitter.com/erniemiller). See
[Community and support](https://activerecord-hackery.github.io/ransack/project/community/)
for the full list.

<img src="https://opencollective.com/ransack/contributors.svg?width=890&button=false" />
