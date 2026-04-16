fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

Build the app for simulator

### ios test

```sh
[bundle exec] fastlane ios test
```

Run unit tests

### ios ui_test

```sh
[bundle exec] fastlane ios ui_test
```

Run UI tests and generate report

### ios test_all

```sh
[bundle exec] fastlane ios test_all
```

Run all tests (unit + UI)

### ios build_and_test

```sh
[bundle exec] fastlane ios build_and_test
```

Build and test

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Push a new beta build to TestFlight

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload metadata to App Store Connect (no binary)

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Upload screenshots to App Store Connect

### ios release

```sh
[bundle exec] fastlane ios release
```

Push a new release to the App Store

### ios submit

```sh
[bundle exec] fastlane ios submit
```

Submit existing build for App Store review

### ios add_tester

```sh
[bundle exec] fastlane ios add_tester
```

Add external tester to TestFlight

### ios testers

```sh
[bundle exec] fastlane ios testers
```

List TestFlight testers

### ios lint

```sh
[bundle exec] fastlane ios lint
```

Lint Swift code

### ios lint_fix

```sh
[bundle exec] fastlane ios lint_fix
```

Fix SwiftLint warnings

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
