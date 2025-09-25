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

To release a new version of Ransack and publish it to RubyGems, take the following steps:

### Manual Release Process

1. Update the [`version.rb`](https://github.com/activerecord-hackery/ransack/lib/ransack/version.rb) file to the new release, commit and push to `main`.
2. Create a new release, e.g: v4.4.0 and mark it `Prerelease`.
3. Click the **"Generate release notes"** button to automatically populate the release notes with commits since the last tag.
4. Create and push a tag with the same name:
   ```bash
   git tag v4.4.0
   git push origin v4.4.0
   ```
5. From the terminal, run the following commands:

```bash
rake build
rake release
```

**GitHub Release UI**
- **Tag**: v4.4.0
- **Target**: main  
- **Release title**: v4.4.0 (auto-filled)
- **Release notes**: Click **"Generate release notes"** to auto-populate using the configured categories
- **Set as a pre-release**: **Checked** (required for step 2)
- **Set as the latest release**: Unchecked (correct for prerelease)
- **Action**: Click **"Publish release"** (not "Save draft")

### Release Notes Configuration

The repository includes a release configuration file (`.github/release.yml`) that customizes how release notes are organized when using GitHub's "Generate release notes" button.


