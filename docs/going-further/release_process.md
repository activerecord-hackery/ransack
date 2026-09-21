---
title: Versions and Releases
parent: Going further
nav_order: 14
---

## Semantic Versioning

Ransack attempts to follow semantic versioning in the format of `x.y.z`, where:

`x` stands for a major version (new features that are not backward-compatible).

`y` stands for a minor version (new features that are backward-compatible).

`z` stands for a patch (bug fixes).

In other words: `Major.Minor.Patch`.


## Release Process

*For the maintainers of Ransack.*

Publishing to RubyGems is automatic. Publishing a GitHub Release triggers the
[`Release to RubyGems`](https://github.com/activerecord-hackery/ransack/blob/main/.github/workflows/release.yml)
workflow, which builds the gem and pushes it using
[RubyGems Trusted Publishing](https://guides.rubygems.org/trusted-publishing/).
There is no API key to hold or rotate, and nothing to run locally.

### The flow

Example for release 5.1.0.

1. **Merge the pull requests** that make up the release. Everything on `main` at the
   time of the version bump is what ships, so check the queue is in the state you want.

2. **Merge a version pull request.** Open a PR that changes only
   [`version.rb`](https://github.com/activerecord-hackery/ransack/blob/main/lib/ransack/version.rb):

   ```ruby
   module Ransack
     VERSION = '5.1.0'
   end
   ```

   Merge it last, so the bump is the final commit before the tag.

3. **Create the release.** Click
   [Draft a new release](https://github.com/activerecord-hackery/ransack/releases/new) and set:

   | Field | Value |
   | --- | --- |
   | Tag | `v5.1.0` — *Create new tag on publish*, target `main` |
   | Release title | `5.1.0` |
   | Notes | Click **Generate release notes**. GitHub lists every merged PR since the previous release; group them under headings (breaking changes, features, bug fixes) and remove anything internal |
   | Set as the latest release | checked |

4. **Publish the release.** That is the trigger. Within a minute the workflow starts;
   watch it under [Actions → Release to RubyGems](https://github.com/activerecord-hackery/ransack/actions/workflows/release.yml).
   It checks out the tag, verifies the tag matches `Ransack::VERSION`, builds the gem,
   exchanges a short-lived OIDC token for RubyGems credentials, and pushes. When it
   finishes, the version is live at https://rubygems.org/gems/ransack.

Since 4.4.0 the release notes are the changelog; `CHANGELOG.md` is not updated.

### If something goes wrong

**The tag and `Ransack::VERSION` disagree.** The workflow refuses to publish and fails on
the *Check the tag matches* step before building anything. This happens when the
release is published before the version PR is merged, or with a typo in the tag. Delete
the release and the tag, fix `main`, and redo step 3.

**The workflow failed after the tag exists** (for example a RubyGems outage). Don't
create a new tag. Re-run it from the Actions tab with **Run workflow**, passing the
existing tag (`v5.1.0`). The same check runs, then the publish.

**`No trusted publisher configured for this workflow`.** The trusted publisher on
RubyGems.org is missing or its details changed. A gem owner re-creates it — see below —
then re-runs the workflow as above.

### Trusted publisher configuration

Configured once by a gem owner at
[the gem's trusted publishers page](https://rubygems.org/gems/ransack/trusted_publishers).
Already in place; recorded here in case it ever needs to be re-created:

| Field | Value |
| --- | --- |
| Repository owner | `activerecord-hackery` |
| Repository name | `ransack` |
| Workflow filename | `release.yml` |
| Environment | `rubygems` |

The `rubygems` environment exists in the repository's
[environment settings](https://github.com/activerecord-hackery/ransack/settings/environments).
Adding required reviewers to it makes every publish wait for a second maintainer's
approval — optional, but a reasonable safeguard for a gem with this many downloads.

### Manual fallback

Only if the workflow cannot be used at all:

```bash
gem signin
rake build
gem push pkg/ransack-5.1.0.gem
```
