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

Example for release 4.4.0 

1. Update the [`version.rb`](https://github.com/activerecord-hackery/ransack/lib/ransack/version.rb) file to the `4.4.0`, commit and push to `main`.
3. Click the [Draft a new Release](https://github.com/activerecord-hackery/ransack/releases/new) button 
4. Use these settings:
- Tag: v4.4.0
- Release Title: 4.4.0
- Check `Set as the Latest Release`
- Click `Generate release notes`
- Click `Publish Release`

5. Release to RubyGems

```bash
gem signin
rake build
rake release
```



