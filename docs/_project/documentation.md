---
title: Documentation
description: Build and preview this site locally, and add a page.
nav_order: 3
redirect_from:
- "/going-further/documentation/"
---

The documentation site is built with [Jekyll](https://jekyllrb.com/) and the
[VitePress theme for Jekyll](https://jekyll-vitepress.dev/) from the Markdown files under
`docs/` in the Ransack repository, and published to GitHub Pages on every push
to `main`. To contribute, use the *Edit this page on GitHub* link at the bottom
of any page, or edit locally.

## Local development

```sh
cd docs
bundle install
bundle exec jekyll serve
```

Open <http://localhost:4000/ransack/>. Most changes are reflected live.

## Adding a page

Each sidebar section is a Jekyll collection: `_getting_started/`,
`_going_further/` and `_project/`. Create a Markdown file in one of them with
this front matter, and the page appears in that section of the sidebar,
ordered by `nav_order`:

```yaml
---
title: My page
description: One sentence for search results and link previews.
nav_order: 15
---
```

The title is rendered as the page heading, so start the page body at `##`.
Sections are listed in `_data/sidebar.yml`, and the top navigation in
`_data/navigation.yml`.

For a note or a warning, use a custom block:

```html
<div class="info custom-block" markdown="1">
<p class="custom-block-title">Note</p>

Text, in Markdown.
</div>
```

`info`, `tip`, `warning` and `danger` give the four colours.

When a page moves, add its old URL to `redirect_from` so existing links keep
working.

Link to other pages by their file path, `[Sorting](../_getting_started/sorting.md)`;
the build turns it into the page's URL and the build fails if the target does
not exist.

## Checking the build

The pull request check runs the same build and a link check:

```sh
bundle exec jekyll build --strict_front_matter
bundle exec htmlproofer _site --disable-external --no-enforce-https --swap-urls '^/ransack/:/'
```
