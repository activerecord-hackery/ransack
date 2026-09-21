---
title: Documentation
parent: Going further
nav_order: 13
---

The documentation site is built with [Jekyll](https://jekyllrb.com/) and the
[Just the Docs](https://just-the-docs.com/) theme from the Markdown files under
`docs/` in the Ransack repository, and published to GitHub Pages on every push
to `main`. To contribute, use the *Edit this page on GitHub* link at the bottom
of any page, or edit locally.

### Local development

```sh
cd docs
bundle install
bundle exec jekyll serve
```

Open <http://localhost:4000/ransack/>. Most changes are reflected live.

### Adding a page

Create a Markdown file under `getting-started/` or `going-further/` with this
front matter, and the page appears in the navigation:

```yaml
---
title: My page
parent: Going further
nav_order: 19
---
```

Link to other pages by their file path, `[Sorting](../getting-started/sorting.md)`;
the build turns it into the page's URL and the build fails if the target does
not exist.

### Checking the build

The pull request check runs the same build and a link check:

```sh
bundle exec jekyll build --strict_front_matter
bundle exec htmlproofer _site --disable-external --no-enforce-https --swap-urls '^/ransack/:/'
```
