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



### bump_patch

```sh
[bundle exec] fastlane bump_patch
```

Bump patch version (e.g., 0.2.2 → 0.2.3)

### bump_minor

```sh
[bundle exec] fastlane bump_minor
```

Bump minor version (e.g., 0.2.2 → 0.3.0)

### bump_major

```sh
[bundle exec] fastlane bump_major
```

Bump major version (e.g., 0.2.2 → 1.0.0)

### set_version

```sh
[bundle exec] fastlane set_version
```

Set a specific version number

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

### build_and_bump

```sh
[bundle exec] fastlane build_and_bump
```

Build with automatic build number bump

### release

```sh
[bundle exec] fastlane release
```

Release: bump version, commit, tag, and optionally push

### release_version

```sh
[bundle exec] fastlane release_version
```

Release with specific version, commit, and tag

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
