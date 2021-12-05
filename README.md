# Flutter Template

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]


# What to accomplish
1) has tests
2) basic auth flow
3) riverpod as state provider
4) logging (sentry)
5) navigation (I used Beamer last time but might be something better out now)
6) basic dashboard screen display user information
7) basic settings screen to modify user profile.
8) built in responsiveness
9) built in flavors (dev,staging,prod)


# Top TODOs
1) setup login flow
2) make api call using dio and cache response using dio cacher
3) Use auto route for navigtion
4) setup guards for users that are not auth'ed
5) run web integration tests in github actions


# DONE
1) full test suite running in github actions
2) logging with sentry monitoring
3) riverpod
4) Flavors configured
5) built in responsiveness
6) full CI lint/unit/integration 
7) Pre-Push githook to force lint before pushing

---

## Getting Started 🚀

### First step
Run `dart pub global activate derry`
This will allow you to run commands defined in derry.yaml like `derry lint`
Support for running integration tests with flavors is added
https://github.com/flutter/flutter/pull/89045
If you are on master you can run `derry test_all` or `derry e2e_iphone`

To run unit tests `derry unit_test`

This project contains 3 flavors:

- development
- staging
- production

To run the desired flavor either use the launch configuration in VSCode/Android Studio or use the following commands:

```sh
# Development
$ flutter run --flavor development --target lib/main_development.dart

# Staging
$ flutter run --flavor staging --target lib/main_staging.dart

# Production
$ flutter run --flavor production --target lib/main_production.dart
```

_\*Flutter Template works on iOS, Android, and Web._

---

## Running in Docker 

For Web 
In Docker 
1) Run `sh flutter-web.sh `


Locally:
1) Open up an android emulator 
2) type `adb devices` and make sure the device shows
3) in your terminal type `adb tcpip 5555` 

In the docker continer:
1) Run `adb connect host.docker.internal:5555`
2) `sh flutter-android-emulator.sh` 


Errors: 
If you get `The message received from the daemon indicates that the daemon has disappeared.` When trying to launch on android increase your docker memory to 4 gigs. Do this by going to the docker app -> preferences -> resourses 


## Running Tests 🧪

To run all unit and widget tests use the following command:

```sh
$ derry test_all
$ derry e2e
$ derry unit
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov).

```sh
# Generate Coverage Report
$ genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
$ open coverage/index.html
```

---


[coverage_badge]: coverage_badge.svg
[flutter_localizations_link]: https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html
[internationalization_link]: https://flutter.dev/docs/development/accessibility-and-localization/internationalization
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli
