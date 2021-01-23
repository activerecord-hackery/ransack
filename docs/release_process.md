## Release Process

*For maintainers of Ransack.*

To release a new version of Ransack and publish it to RubyGems, take the following steps:

- Create a new release, marked `Prerelease`.
<<<<<<< Updated upstream
- Update the versions file to the new release, commit and push to `master`.
=======
- Update the [version.rb](../lib/ransack/version.rb) file to the new release, commit and push to `master`.
>>>>>>> Stashed changes
- From the terminal, run the following commands

```bash
rake build
rake release
```

![Create a Release](img/create_release.png)
