---
title: Versions and Releases
sidebar_position: 11
---


## Semantic Versioning

Ransack attempts to follow semantic versioning in the format of `x.y.z`, where:

`x` stands for a major version (new features that are not backward-compatible).

`y` stands for a minor version (new features that are backward-compatible).

`z` stands for a patch (bug fixes).

In other words: `Major.Minor.Patch`.


## Release Process

*For the maintainers of Ransack.*

Releases are published to RubyGems automatically by the
[`Release to RubyGems`](https://github.com/activerecord-hackery/ransack/blob/main/.github/workflows/release.yml)
workflow, using [RubyGems Trusted Publishing](https://guides.rubygems.org/trusted-publishing/).
There is no API key to hold or rotate: the workflow exchanges a short-lived GitHub OIDC
token for a RubyGems credential at publish time.

### Releasing a new version

Example for release 4.4.1:

1. Update [`version.rb`](https://github.com/activerecord-hackery/ransack/blob/main/lib/ransack/version.rb)
   to `4.4.1`, commit and push to `main`.
2. Click [Draft a new Release](https://github.com/activerecord-hackery/ransack/releases/new) and use these settings:
   - Tag: `v4.4.1`
   - Release Title: `4.4.1`
   - Check `Set as the Latest Release`
   - Click `Generate release notes`
   - Click `Publish Release`
3. Publishing the release triggers the workflow, which verifies that the tag matches
   `Ransack::VERSION` and then builds and pushes the gem. Watch it under
   [Actions](https://github.com/activerecord-hackery/ransack/actions/workflows/release.yml).

If the tag and `Ransack::VERSION` disagree, the workflow fails before pushing anything.
Fix `version.rb`, delete the tag and the release, and redo step 2.

To re-run a publish for a tag that already exists, use the workflow's
`Run workflow` button and pass the tag.

### One-time setup

Trusted Publishing has to be configured once by a gem owner on RubyGems.org, at
[the gem's trusted publishers page](https://rubygems.org/gems/ransack/trusted_publishers):

| Field | Value |
| --- | --- |
| Repository owner | `activerecord-hackery` |
| Repository name | `ransack` |
| Workflow filename | `release.yml` |
| Environment | `rubygems` |

The `rubygems` environment should also exist in the repository's
[environment settings](https://github.com/activerecord-hackery/ransack/settings/environments).
Adding required reviewers to it means a release needs a second maintainer to approve
the push — recommended, but optional.

### Manual fallback

If the workflow is unavailable:

```bash
gem signin
rake build
gem push pkg/ransack-4.4.1.gem
```
