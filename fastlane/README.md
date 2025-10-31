fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### setup_signing

```sh
[bundle exec] fastlane setup_signing
```



### build

```sh
[bundle exec] fastlane build
```

Build and archive macOS app

### test

```sh
[bundle exec] fastlane test
```



### set_build

```sh
[bundle exec] fastlane set_build
```

Set build number to a specific value

### bump_build

```sh
[bundle exec] fastlane bump_build
```

Bump build number only

### show_version

```sh
[bundle exec] fastlane show_version
```

Show current version and build number

### release

```sh
[bundle exec] fastlane release
```

Release: bump version, commit, tag, and optionally push

Usage:

  fastlane release type:patch           # Bump patch (0.2.2 → 0.2.3)

  fastlane release type:minor           # Bump minor (0.2.2 → 0.3.0)

  fastlane release type:major           # Bump major (0.2.2 → 1.0.0)

  fastlane release version:1.2.3        # Set specific version

  fastlane release type:patch push:true # Auto-push to remote

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
