# Flutter Template

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]


# To use as template

### To Replace the app name with your app name
1) open and add your add name to replace_app_name.sh
2) run the script

### To replace the signin screen url
https://github.com/jeremiahlukus/flutter_template/blob/master/lib/auth/infrastructure/webapp_authenticator.dart#L47-L56

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
1) run web integration tests in github actions


# DONE
1) full test suite running in github actions
2) logging with sentry monitoring
3) riverpod
4) Flavors configured
5) built in responsiveness
6) full CI lint/unit/integration
7) Pre-Push githook to force lint before pushing
8) setup login flow

---

## Getting Started 🚀

### First step
Setup your backend to login a user.
On login the path needs to be be `/callback?state=6meYRKLtQMSGctx2UXsxCd4L`
the state is your api token.
I logout using the api part of my backend `/api/v1/auth` in this call i delete the users token.
Soon ill add a refresh token endpoint.

I separated the WebAppAuthenticator so you can easily replace with your solution.

### Second step
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

### Start local emulator
1) install android studio and set up a emulator
2) `ln -s ~/Library/Android/sdk/tools/emulator /usr/local/bin/emulator`
3) `emulator -list-avds` should list out your installed devices
4) export the paths
```
export ANDROID_SDK=$HOME/Library/Android/sdk
export PATH=$ANDROID_SDK/emulator:$ANDROID_SDK/tools:$PATH

```
5) run `emulator -avd $(emulator -list-avds)` to open the emulator.
6) `adb tcpip 5555`
After doing all the setup above you only need to run this command from here on out.



### Setup
1) Download [Visual Studio](https://code.visualstudio.com/)
2) Install [Docker Plugin](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)
3) Install [Remote Development Plugin](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)
4) Optional Download [Docker Desktop](https://www.docker.com/products/docker-desktop)

Once you have installed all of these, open Visual Studio and open this project. Visual Studio will auto detect the Dockerfile and build it for you as well as copy the project files in the docker container using settings from the devcontainer.json file. If you have a andriod emulator open and have typed `adb tcpip 5555` into your terminal the device should show up in the docker container type `adb devices` to make sure if not follow the steps below

### For Web
In Docker
1) Run `sh flutter-web.sh `


### For Android:
1) Open up an android emulator / or plugin your device
2) type `adb devices` and make sure the device shows if it doesnt kill and restart your server `adb kill-server` & `adb start-server`
3) in your terminal type `adb tcpip 5555`

In the docker continer:
1) Run `adb connect host.docker.internal:5555`
2) clilck allow permission on the andriod
3) `sh flutter-android-emulator.sh`


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
