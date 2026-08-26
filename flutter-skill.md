# flutter_template — flutter-skill Integration Test Flows

_Run these flows manually using the flutter-skill MCP tools after connecting to
the app._

Widget tests (974 of them, 93.68% coverage) plus 48 security-rules tests already
cover every screen and rule in isolation. These flows exist for what widget tests structurally cannot reach:
real Firebase, real sqlite on device, process restarts, and the offline→online
transition that the whole sync design ([spec 0002](specs/0002-notes-sync/spec.md))
exists to handle.

---

## Status

**FLOW-00 has been run as written.** The numbered flows below otherwise still
read `⏳ NOT RUN` — a fabricated PASS in this file is worse than no file at all.

| Gate | State |
|---|---|
| `flutter analyze --fatal-infos --fatal-warnings` | ✅ clean |
| `flutter test --exclude-tags golden` | ✅ 974 passed |
| `flutter test --tags golden` | ✅ 12 goldens |
| `cd test_rules && npm test` | ✅ 48 rules tests |
| Coverage (85% floor) | ✅ 93.68% |
| On-device flows | **1 / 33 run** — FLOW-00 ✅ PASS |

### Separately: a fresh fork was exercised end to end (2026-08-25)

Not one of the numbered flows, so nothing below is ticked — but it is the
strongest evidence the template currently has, and it is what these flows exist
to catch. A clean clone was renamed with `tool/rename_package.dart`, given a real
`firebase_options.dart`, and run on an iPhone 17 simulator, first against a real
Firebase project and then against the emulator suite via
`--dart-define=USE_EMULATORS=true`.

Confirmed on device:

- Real Firebase initialises; the setup screen correctly does **not** appear.
- Replacing the generated `firebase_options.dart` no longer breaks the build —
  the reason `FirebaseNotConfigured` was moved out of it.
- `Auth → emulator` / `Firestore → emulator` redirection works ([0016-R6](specs/0016-emulator-and-rules/spec.md)).
- Registration through `firebase_ui_auth` succeeds — the flow that
  [cannot be driven in a widget test](README.md#known-limitations).
- A note written on device reached `users/{uid}/notes/{noteId}` in Firestore,
  with `updatedAt` stored in **UTC**.
- **The failure path is honest.** With `allow create, update: if false` in the
  rules, the list showed a `1 pending` badge and the snackbar read *"Synced, but
  1 note could not upload."* — not a false success. Restoring the rules cleared
  the badge and both notes landed server-side.
- A locale change re-renders live, in Spanish, with no restart ([0013-R10](specs/0013-localisation/spec.md)).

Two things it found, both now fixed: the app **display name** was in no
Milestone 0 item (a fork shipped as "Flutter Template"), and the numbers in this
table were stale.

---

## Critical Notes for Test Execution

### Prerequisite: Firebase, and the QA entrypoint

**Launch `tool/main_dev.dart`, not `lib/main.dart`.** The `flutter_skill` SDK
that these flows drive is a dev_dependency, and Dart forbids `lib/` from
importing one — deliberately, so QA tooling cannot reach production code. The
QA entrypoint registers it and then calls the same `bootstrap`.

Without Firebase configured the app **still launches**, showing the setup screen
([FLOW-00](#flow-00--an-unconfigured-app-explains-itself)). Every other flow needs
a real Firebase project — see [task.md](task.md) Milestone 0.

### Device

Fill in the simulator/device you actually used, and confirm the id first:

```sh
xcrun simctl list devices booted        # iOS
flutter devices                          # everything
```

- **Device:** _(to be filled in)_
- **Device ID:** _(to be filled in)_

### Coordinate mapping — prefer keys

Every interactive element in this app carries a stable `ValueKey`. That is
deliberate: coordinate taps are the single largest source of flaky manual QA, and
they have to be recalibrated for every screen size. **Use `tap(key: "...")` and
only fall back to `tap_at` when a widget genuinely has no key.**

| Key | Element |
|---|---|
| `new_note_button` | FAB on the notes list |
| `notes_list` | The `ListView` |
| `note_<id>` | A specific note row |
| `notes_empty_state` / `notes_error_state` / `notes_loading` | Body states |
| `pending_sync_chip` | "N pending" chip in the app bar |
| `sync_button` / `settings_button` / `profile_button` | App-bar actions |
| `note_title_field` / `note_body_field` / `save_note_button` | Editor |
| `delete_note_button` / `delete_cancel` / `delete_confirm` | Note deletion |
| `editor_back` / `settings_back` / `profile_back` | Back buttons |
| `display_name_field` / `save_name_button` | Profile rename |
| `upload_avatar_button` / `profile_avatar` | Avatar |
| `sign_out_tile` / `delete_account_tile` | Destructive actions |
| `confirm_cancel` / `confirm_action` | Confirmation dialogs |
| `unverified_chip` | "Email not verified" warning |
| `theme_system` / `theme_light` / `theme_dark` | Theme radios |
| `analytics_switch` | Analytics opt-out |
| `pending_sync_tile` / `sync_now_tile` | Settings › Sync |
| `brand_picker` / `brand_<name>` | Accent-colour swatches (`brand_teal`, …) |
| `locale_system` / `locale_<code>` | Language radios (`locale_es`, …) |
| `app_version_tile` / `environment_tile` | Settings › About |
| `offline_banner` | Offline strip, on every screen |
| `environment_banner` | Corner ribbon off production |
| `onboarding_pages` / `onboarding_next` / `onboarding_skip` | First-run intro |
| `error_retry_button` | Retry inside any `AppErrorState` |
| `async_loading` | Generic `AsyncValueView` spinner |
| `brand_picker` / `brand_<name>` | Accent-colour swatches |
| `push_switch` | Settings › Notifications |
| `avatar_from_camera` / `avatar_from_gallery` / `avatar_cancel` | Avatar source sheet |
| `update_required` / `update_action` | Forced-update gate |
| `optional_update_tile` | Settings › About |

If you add a screen and find yourself reaching for `tap_at`, add a key instead.

### Known limitations

1. **The sign-in form is `firebase_ui_auth`'s, not ours.** Its fields have no
   app-supplied keys. Target them by label ("Email", "Password") or by index.
   This is also why the sign-in flow cannot be automated in widget tests — see
   [spec 0001, Known limitation](specs/0001-authentication/spec.md).
2. **Screens with a `CircularProgressIndicator` never settle.** A spinner is a
   perpetual animation. Do not wait for a quiescent frame on `notes_loading`;
   screenshot and move on.
3. **`sync()` is manual.** Nothing retries automatically on reconnect
   ([task.md](task.md) Milestone 5), so any offline flow needs an explicit tap on
   `sync_button`.
4. **Deleting the account is irreversible.** FLOW-16 needs a throwaway account;
   run it last.
5. **Onboarding shows once per device.** To re-run FLOW-21 you must clear app
   data (or uninstall) — the flag lives in the local Drift database, not in the
   account.
6. **The settings list is taller than one screen.** Scroll before targeting
   anything below the Appearance section.
7. **Launch with a flavour.** Add `--dart-define=APP_ENV=staging` to see the
   corner banner and the Settings environment row; a plain `flutter run` is
   `dev`.
8. **Prefer the emulator for destructive flows.** `firebase emulators:start` plus
   `--dart-define=USE_EMULATORS=true` gives a throwaway backend, so FLOW-16
   (delete account) and the sync flows do not touch a real project. Production
   builds ignore the flag by design.
9. **Push needs native setup.** APNs certificate and entitlements are per-app;
   FLOW-29 to FLOW-31 are `⏭️ SKIP` until that is done.
10. **The notes list is paged** at 30 rows. Flows that need a second page must
    seed at least 31 notes.

### Test accounts

Create these in the Firebase console before starting. Do not use a real account.

| Purpose | Email | Password |
|---|---|---|
| Main | `qa+main@example.com` | `qa-password-1` |
| Second device (sync) | same as Main | same |
| Unverified email | `qa+unverified@example.com` | `qa-password-1` |
| Throwaway (FLOW-15) | `qa+delete@example.com` | `qa-password-1` |

---

## Setup

```sh
# 1. Configure Firebase (once per machine)
dart pub global activate flutterfire_cli
flutterfire configure

# 2. Launch the QA entrypoint with the VM Service exposed.
#    APP_ENV=staging so the environment banner and Settings row are visible.
flutter run -t tool/main_dev.dart -d <DEVICE_ID> \
  --dart-define=APP_ENV=staging \
  --vm-service-port=50123 --disable-service-auth-codes \
  > /tmp/flutter_run.log 2>&1 &

# 3. Wait for the VM Service URI
until grep -q "ws://" /tmp/flutter_run.log; do sleep 3; done
```

```
# 4. Connect
mcp__flutter-skill__connect_app(uri: "ws://127.0.0.1:50123/ws")
```

**Baseline to record before you start:** note count on the notes list, and the
current theme setting. Several flows below restore to this baseline; if a run is
interrupted, restore it manually before the next flow.

---

## FLOW-00 · An unconfigured app explains itself

The only flow that runs **without** a Firebase project — and the one a new
contributor hits first. → [spec 0015](specs/0015-first-run/spec.md)

```
# Fresh clone, no `flutterfire configure` run yet.
screenshot()
assert_visible(key: "setup_title")
assert_visible(text: "Firebase setup required")
assert_visible(text: "flutterfire configure")

tap(key: "copy_flutterfire configure")
screenshot()                        # "Copied to clipboard"

tap(key: "setup_error_details")
screenshot()                        # raw FirebaseNotConfigured message
```

**Pass criteria:** the app **launches** — no crash, no red screen. Both commands
are shown and copyable, the restart hint and the `task.md` pointer are visible,
and the raw error is available but collapsed.

### Result — ✅ PASS (verified on iPhone 17 simulator)

Run against a clone with the placeholder `firebase_options.dart`:

```
flutter: │ Firebase is not configured. Run `flutterfire configure` to regenerate
flutter: │ lib/firebase_options.dart, then rerun the app.
flutter: │ ⛔ Firebase failed to initialise; showing the setup screen
```

The screen rendered as specified. **One bug found and fixed on the way:** the
build failed at `pod install` with *"The plugin cloud_firestore requires a higher
minimum iOS deployment version"* — Flutter's scaffold targets iOS 13.0 and
Firebase needs 15.0. Raised in `ios/Podfile` and `IPHONEOS_DEPLOYMENT_TARGET`.

---

## FLOW-01 · Sign up a new account → land on an empty notes list

Covers the first-run path and the signed-out → signed-in redirect
([0004-R4](specs/0004-routing/spec.md)).

```
screenshot()                        # sign-in screen, "Flutter Template" header
assert_visible(text: "Sign in to sync your notes")

tap(text: "Register")               # firebase_ui_auth's sign-up toggle
enter_text(text: "qa+new-<timestamp>@example.com")
tap(text: "Password")
enter_text(text: "qa-password-1")
tap(text: "Register")
screenshot()
```

**Pass criteria:** the app navigates straight to the notes list ("Notes" app bar)
with `notes_empty_state` visible. No manual navigation was needed — the route
guard reacted to the auth stream.

---

## FLOW-02 · Sign in with an existing account

```
tap(text: "Email")
enter_text(text: "qa+main@example.com")
tap(text: "Password")
enter_text(text: "qa-password-1")
tap(text: "Sign in")
screenshot()

assert_visible(text: "Notes")
```

**Pass criteria:** notes list appears, showing the baseline note count. The
avatar in `profile_button` shows the account's initials.

---

## FLOW-03 · A wrong password shows readable copy, not a raw error code

Guards [0001-R6](specs/0001-authentication/spec.md).

```
tap(text: "Email")
enter_text(text: "qa+main@example.com")
tap(text: "Password")
enter_text(text: "definitely-wrong")
tap(text: "Sign in")
screenshot()
```

**Pass criteria:** an error message in plain English. No `wrong-password`,
`invalid-credential`, or `FirebaseAuthException` visible anywhere on screen. Still
on the sign-in screen.

---

## FLOW-04 · Create a note → verify it appears in the list

```
tap(key: "new_note_button")
screenshot()                        # "New note", delete action absent

tap(key: "note_title_field")
enter_text(text: "Groceries")
tap(key: "note_body_field")
enter_text(text: "Milk\nEggs\nCoffee")
tap(key: "save_note_button")
screenshot()

assert_visible(text: "Groceries")
assert_visible(text: "Milk")        # first body line becomes the subtitle
```

**Pass criteria:** back on the notes list, "Groceries" at the top (newest first),
subtitle "Milk" only — not the whole body. `pending_sync_chip` is **absent**,
meaning Firestore confirmed the write.

---

## FLOW-05 · Edit an existing note

```
tap(key: "note_<id-of-Groceries>")
screenshot()                        # "Edit note", fields pre-filled

tap(key: "note_title_field")
enter_text(text: "Weekly groceries")
tap(key: "save_note_button")
screenshot()

assert_visible(text: "Weekly groceries")
assert_text_absent(text: "Groceries")
```

**Pass criteria:** the title updates in place. Exactly one note where there was
one before — no duplicate row.

---

## FLOW-06 · Delete a note — cancel, then confirm

```
tap(key: "note_<id>")
tap(key: "delete_note_button")
screenshot()                        # "Delete note?" / "This cannot be undone."

tap(key: "delete_cancel")
screenshot()                        # still on "Edit note"

tap(key: "delete_note_button")
tap(key: "delete_confirm")
screenshot()
```

**Pass criteria:** Cancel returns to the editor with the note intact. Confirm
returns to the notes list with the note gone. Verify in the Firebase console that
the document is deleted too.

---

## FLOW-07 · An empty note is refused

```
tap(key: "new_note_button")
tap(key: "save_note_button")
screenshot()
assert_visible(text: "Nothing to save")

# Whitespace only should behave identically
tap(key: "note_title_field")
enter_text(text: "   ")
tap(key: "save_note_button")
screenshot()
```

**Pass criteria:** both attempts show "Nothing to save — add a title or some
text." and stay on the editor. Note count unchanged.

---

## FLOW-08 · Offline write → pending chip → reconnect → sync clears it

**The most important flow in this file.** This is the entire point of
[spec 0002](specs/0002-notes-sync/spec.md), and no widget test can reach it.

```
# 1. Go offline (simulator: Settings › Airplane Mode, or disable host networking)

tap(key: "new_note_button")
tap(key: "note_title_field")
enter_text(text: "Written offline")
tap(key: "save_note_button")
screenshot()

assert_visible(text: "Written offline")   # saved locally, immediately
assert_visible(key: "pending_sync_chip")
assert_visible(text: "1 pending")

# 2. Confirm it survives a restart while still offline
hot_restart()
screenshot()
assert_visible(text: "Written offline")
assert_visible(key: "pending_sync_chip")

# 3. Back online
tap(key: "sync_button")
screenshot()
```

**Pass criteria:**
- The save **never blocks** and never errors while offline.
- The pending chip appears and survives a restart.
- After reconnecting and syncing, the snack bar reports `1 up`, the chip
  disappears, and the note is present in the Firestore console.
- **Critically:** the note is *not* deleted by the pull half of the sync. That is
  [0002-R5 and 0002-R6](specs/0002-notes-sync/spec.md) — push before pull, and never
  clobber a pending write.

---

## FLOW-09 · Sync pulls a note created elsewhere

Needs a second client — a second simulator, or the Firestore console.

```
# Create users/<uid>/notes/<newId> in the Firebase console with
#   title: "From another device", body: "", updatedAt: <now>

tap(key: "sync_button")
screenshot()
assert_visible(text: "From another device")
```

**Pass criteria:** the snack bar reports at least `1 down` and the note appears in
the list. Locally-created notes are all still present.

---

## FLOW-10 · Theme choice persists across a restart

```
tap(key: "settings_button")
screenshot()

tap(key: "theme_dark")
screenshot()                        # UI turns dark immediately

hot_restart()
screenshot()                        # still dark, with no flash of light theme
tap(key: "settings_button")
screenshot()                        # "Dark" still selected
```

**Pass criteria:** dark mode applies instantly, survives the restart, and the
radio still reads Dark. Watch specifically for a light-theme flash on relaunch —
that would mean the preference is being read too late.

---

## FLOW-11 · Analytics opt-out persists

```
tap(key: "settings_button")
tap(key: "analytics_switch")
screenshot()                        # switch off

hot_restart()
tap(key: "settings_button")
screenshot()                        # still off
```

**Pass criteria:** the switch stays off across the restart.

**Known gap:** the preference is stored but **not yet honoured** — events are
still collected. This flow verifies persistence only.
[task.md](task.md) Milestone 5.

---

## FLOW-12 · Rename the display name → initials update everywhere

```
tap(key: "profile_button")
screenshot()

tap(key: "display_name_field")
enter_text(text: "Grace Hopper")
tap(key: "save_name_button")
screenshot()
assert_visible(text: "Name updated.")

tap(key: "profile_back")
screenshot()                        # notes list avatar now reads "GH"
```

**Pass criteria:** the profile header and the notes-list avatar both update to
"Grace Hopper" / "GH" without a restart — they read the same
`currentUserProvider`.

---

## FLOW-13 · Avatar upload round-trips through Cloud Storage

```
tap(key: "profile_button")
tap(key: "upload_avatar_button")
screenshot()
assert_visible(text: "Avatar uploaded.")

hot_restart()
tap(key: "profile_button")
screenshot()
```

**Pass criteria:** success message shown. In the Firebase console, an object
exists at `users/<uid>/avatar.jpg` — matching the path the Storage rules protect
([0006-R9](specs/0006-file-storage/spec.md)). The upload is a 1×1 placeholder PNG by
design; there is no image picker.

---

## FLOW-14 · Sign out clears the local cache

Guards [0002-R12](specs/0002-notes-sync/spec.md) — a real privacy issue if it breaks.

```
# Start signed in with at least 2 notes.
tap(key: "profile_button")
tap(key: "sign_out_tile")
screenshot()                        # "Sign out?" dialog

tap(key: "confirm_cancel")
screenshot()                        # still signed in

tap(key: "sign_out_tile")
tap(key: "confirm_action")
screenshot()                        # back on the sign-in screen

# Sign in as a DIFFERENT account
tap(text: "Email")
enter_text(text: "qa+unverified@example.com")
tap(text: "Password")
enter_text(text: "qa-password-1")
tap(text: "Sign in")
screenshot()
```

**Pass criteria:** Cancel keeps the session. Confirm returns to sign-in. The
second account sees **none** of the first account's notes — not even briefly. A
flash of the previous user's notes is a failure.

---

## FLOW-15 · Unverified email is flagged

```
# Signed in as qa+unverified@example.com
tap(key: "profile_button")
screenshot()
assert_visible(key: "unverified_chip")
assert_visible(text: "Email not verified")
```

**Pass criteria:** the chip is present for this account and **absent** for
`qa+main@example.com`.

---

## FLOW-16 · Delete account

⚠️ Irreversible. Use the throwaway account and run this last.

```
# Signed in as qa+delete@example.com
tap(key: "profile_button")
tap(key: "delete_account_tile")
screenshot()                        # "Delete account?"

tap(key: "confirm_cancel")
screenshot()                        # still signed in

tap(key: "delete_account_tile")
tap(key: "confirm_action")
screenshot()
```

**Pass criteria:** returns to the sign-in screen and the user is gone from
Firebase Auth. If Firebase demands a recent login, the app should show "Sign in
again and retry" rather than failing silently.

---

## FLOW-17 · A protected route is unreachable while signed out

Exercises the guard against a real deep link rather than a unit test.

```
# Signed out. Drive the platform deep link:
#   iOS:     xcrun simctl openurl booted "yourapp://profile"
#   Android: adb shell am start -a android.intent.action.VIEW -d "yourapp://profile"
screenshot()
```

**Pass criteria:** the sign-in screen, not the profile. Repeat for `/settings`
and `/notes/some-id`. **Requires per-app deep-link setup** — see
[spec 0004, Non-goals](specs/0004-routing/spec.md). Mark `⏭️ SKIP` if not configured.

---

## FLOW-18 · An unknown route renders the error screen

```
# Signed in. Navigate to a path with no route:
#   xcrun simctl openurl booted "yourapp://nope"
screenshot()
assert_visible(text: "Page not found")
tap(text: "Back to notes")
screenshot()
```

**Pass criteria:** the error screen appears with a working way back. Same
deep-link prerequisite as FLOW-17.

---

## FLOW-19 · List rendering edge cases

```
# Create a note with an empty title and a body of ~200 characters
tap(key: "new_note_button")
tap(key: "note_body_field")
enter_text(text: "<200+ characters on one line>")
tap(key: "save_note_button")
screenshot()
```

**Pass criteria:** the row reads "Untitled note", and the subtitle is truncated to
80 characters ending in `…`. No text overflow warnings, no clipped row.

---

## FLOW-20 · Password reset

```
# Signed out
tap(text: "Forgot password?")
screenshot()
enter_text(text: "qa+main@example.com")
tap(text: "Reset password")
screenshot()
```

**Pass criteria:** confirmation shown and a reset email arrives. If
`firebase_ui_auth`'s layout does not render the link at this window size, mark
`⏭️ SKIP` and note the size.

---

## FLOW-21 · Onboarding shows once, before sign-in

Needs a clean install (or cleared app data).

```
screenshot()                        # "Your notes, everywhere", NOT sign-in
assert_visible(key: "onboarding_pages")

tap(key: "onboarding_next")
screenshot()                        # "Works offline"
tap(key: "onboarding_next")
screenshot()                        # "Yours alone", button reads "Get started"
tap(key: "onboarding_next")
screenshot()

hot_restart()
screenshot()
```

**Pass criteria:** the intro appears **before** the sign-in screen, advances
through three pages, the final button reads "Get started", and finishing lands on
sign-in. After the restart the intro does **not** reappear — that is
[0014-R3](specs/0014-onboarding/spec.md), and a flash of it here is a failure.

---

## FLOW-22 · Skip short-circuits the intro

```
# Clean install again
tap(key: "onboarding_skip")
screenshot()
hot_restart()
screenshot()
```

**Pass criteria:** straight to sign-in, and the intro stays gone after restart.

---

## FLOW-23 · The environment banner names the build

```
# Launched with --dart-define=APP_ENV=staging
screenshot()                        # orange "STAGING" ribbon, top-right

tap(key: "settings_button")
scroll_to(key: "environment_tile")
screenshot()
```

**Pass criteria:** the ribbon reads STAGING and Settings › About shows
`Environment: staging`. Relaunch with `APP_ENV=prod` and confirm **both
disappear**. Relaunch with `dev` and confirm the ribbon is a different colour —
mistaking staging for dev is how a demo ends up on the wrong backend.

---

## FLOW-24 · The accent colour re-themes the whole app

The design system's live test. → [spec 0008](specs/0008-design-system/spec.md)

```
tap(key: "settings_button")
scroll_to(key: "brand_picker")
screenshot()                        # six swatches, current one ringed

tap(key: "brand_crimson")
screenshot()                        # app bar, FAB, radios, focus rings all shift

tap(key: "theme_dark")
screenshot()                        # dark mode uses the same seed

hot_restart()
tap(key: "settings_button")
screenshot()
```

**Pass criteria:** every accent surface changes together — nothing is left on the
old colour. Dark mode is derived from the same seed, not a separate palette. The
choice survives the restart. Check text contrast on the amber and teal brands
specifically; those are the ones most likely to look wrong.

---

## FLOW-25 · Language switching, live

```
tap(key: "settings_button")
scroll_to(key: "locale_es")
tap(key: "locale_es")
screenshot()                        # "Ajustes", no restart needed

tap(key: "settings_back")
screenshot()                        # "Notas", "Aún no hay notas"

tap(key: "sync_button")
screenshot()                        # Spanish snack bar

scroll_to(key: "locale_system")
tap(key: "locale_system")
screenshot()
```

**Pass criteria:** the UI switches immediately with no restart
([0013-R10](specs/0013-localisation/spec.md)). **No English text is left anywhere** —
app bars, empty states, snack bars, dialogs, tooltips. Selecting "Match system"
returns to the device language. Watch for clipped or overflowing text: Spanish
strings are typically 15–30% longer than English.

---

## FLOW-26 · The offline banner and automatic reconnect sync

The most valuable of the new flows. → [spec 0011](specs/0011-connectivity/spec.md)

```
# 1. Online. Note there is no banner.
screenshot()
assert_key_absent(key: "offline_banner")

# 2. Enable Airplane Mode
screenshot()
assert_visible(key: "offline_banner")
assert_visible(text: "Offline")

# 3. Write while offline
tap(key: "new_note_button")
tap(key: "note_title_field")
enter_text(text: "Auto-synced on reconnect")
tap(key: "save_note_button")
screenshot()                        # saved; "1 pending"

# 4. Check the banner is on other screens too
tap(key: "settings_button")
screenshot()                        # banner still visible
tap(key: "settings_back")

# 5. Disable Airplane Mode — and DO NOT tap Sync
screenshot()
```

**Pass criteria:**
- The banner appears and disappears with the connection, on **every** screen
  (it is attached in `MaterialApp.builder`, not per-screen).
- The copy reads "changes are saved on this device" — it must **not** imply the
  save failed, because it did not.
- After reconnecting, the pending chip clears **with no user action**, and the
  note appears in the Firestore console. That is the reconnect coordinator.
- Repeat the offline→online cycle twice more; it must sync each time.

---

## FLOW-27 · Reconnect does not sync on a cold start

The inverse of FLOW-26, and easy to get wrong.

```
# Fully quit and relaunch while online, with nothing pending
screenshot()
```

**Pass criteria:** no sync snack bar, and no Firestore read burst in the console.
A sync on every launch would hammer the backend for nothing
([0011-R7](specs/0011-connectivity/spec.md)).

---

## FLOW-28 · The analytics opt-out is actually honoured

```
tap(key: "settings_button")
scroll_to(key: "analytics_switch")
tap(key: "analytics_switch")        # off
screenshot()

tap(key: "settings_back")
tap(key: "new_note_button")
tap(key: "note_title_field")
enter_text(text: "Should produce no events")
tap(key: "save_note_button")
```

**Pass criteria:** with the switch off, Firebase Analytics DebugView shows **no**
events for these actions — not `note_saved`, not `screen_view`. Turn it back on
and confirm events resume. This used to be a stored-but-ignored preference;
[0005-R9](specs/0005-analytics/spec.md) is what closed it.

Note that DebugView needs `adb shell setprop debug.firebase.analytics.app <pkg>`
(Android) or the `-FIRDebugEnabled` launch argument (iOS), and this flow must be
run against a **staging or prod** build — dev sends nothing either way.

---

## FLOW-29 · Push opt-in prompts only on request

Requires APNs/FCM setup. → [spec 0020](specs/0020-push-notifications/spec.md)

```
# Fresh install. Do NOT expect a permission prompt on launch.
screenshot()

tap(key: "settings_button")
scroll_to(key: "push_switch")
screenshot()                        # off by default

tap(key: "push_switch")
screenshot()                        # system permission prompt appears
# Allow.
screenshot()                        # switch on
```

**Pass criteria:** **no prompt on launch** — prompting unasked is how you get
denied forever. The switch is off initially and only prompts when turned on. In
the Firestore console, a document appears at `users/<uid>/devices/<token>`.

Then deny instead, on another fresh install: the switch must stay off. Then deny
at the OS level and reopen Settings: the switch must be **disabled** and read
"Blocked in system settings."

---

## FLOW-30 · A notification tap opens the right screen

```
# With push enabled, send a test message from the Firebase console with a
# data payload of: { "route": "/settings" }

# 1. App in the foreground — should not navigate on its own.
screenshot()

# 2. App backgrounded, then tap the notification.
screenshot()                        # Settings screen

# 3. Fully quit the app, send another, then tap it.
screenshot()                        # Settings screen again
```

**Pass criteria:** taps navigate in both the backgrounded and **terminated**
cases. The cold-start case comes through a different SDK call
([0020-R11](specs/0020-push-notifications/spec.md)) and is the one that usually
silently does nothing. A payload with `"route": "/nope"` must be ignored, not
navigated to.

---

## FLOW-31 · Token rotation keeps delivery working

```
# With push enabled and a token registered:
# 1. Note the token document id in the Firestore console.
# 2. Delete and reinstall the app, sign in, re-enable push.
# 3. Compare the token documents.
```

**Pass criteria:** a new token document exists and the old one is gone. Register
once at sign-in and skip this, and a device silently stops receiving with no
error anywhere — which is why [0020-R5](specs/0020-push-notifications/spec.md) exists.

---

## FLOW-32 · The forced-update gate blocks and unblocks

```
# In the Firestore console, create config/app_update with:
#   minimumSupported: "99.0.0"
#   storeUrl: "https://example.com"

hot_restart()
screenshot()                        # "Update required", app replaced entirely
assert_key_absent(key: "new_note_button")

# Now lower the floor and raise `latest` instead:
#   minimumSupported: "1.0.0", latest: "99.0.0"
hot_restart()
screenshot()                        # app usable again

tap(key: "settings_button")
scroll_to(key: "optional_update_tile")
screenshot()
```

**Pass criteria:** a required update **replaces** the app — no notes UI reachable.
An optional update does not gate anything and appears as a single Settings row.
Delete the document entirely and confirm the app still works: it must
[fail open](specs/0021-app-updates/spec.md).

---

## FLOW-33 · The notes list pages

Needs 31+ notes; the page size is 30. → [spec 0018](specs/0018-pagination/spec.md)

```
# Seed 60 notes (fastest via the Firestore console or the emulator UI, then Sync).
tap(key: "sync_button")
screenshot()

# Scroll to the bottom repeatedly.
swipe_coordinates(...)              # or repeated drags
screenshot()
```

**Pass criteria:** rows keep appearing as you scroll, with **no spinner parked at
the bottom** ([0018-R9](specs/0018-pagination/spec.md)) and no visible stutter.
Scrolling past the last note stops loading rather than looping.

---

## Results

Copy this table into your run notes and fill it in. Leave `⏳ NOT RUN` for
anything you did not actually execute.

| Flow | Result | Notes |
|---|---|---|
| **FLOW-00 unconfigured launch** | **✅ PASS** | iPhone 17 sim; found the iOS 13→15 build bug |
| FLOW-01 sign up | ⏳ NOT RUN | |
| FLOW-02 sign in | ⏳ NOT RUN | |
| FLOW-03 wrong password | ⏳ NOT RUN | |
| FLOW-04 create note | ⏳ NOT RUN | |
| FLOW-05 edit note | ⏳ NOT RUN | |
| FLOW-06 delete note | ⏳ NOT RUN | |
| FLOW-07 empty note refused | ⏳ NOT RUN | |
| **FLOW-08 offline → sync** | ⏳ NOT RUN | **highest value** |
| FLOW-09 pull from elsewhere | ⏳ NOT RUN | |
| FLOW-10 theme persists | ⏳ NOT RUN | |
| FLOW-11 analytics opt-out | ⏳ NOT RUN | |
| FLOW-12 rename | ⏳ NOT RUN | |
| FLOW-13 avatar upload | ⏳ NOT RUN | |
| **FLOW-14 sign-out clears cache** | ⏳ NOT RUN | **privacy-critical** |
| FLOW-15 unverified chip | ⏳ NOT RUN | |
| FLOW-16 delete account | ⏳ NOT RUN | run last |
| FLOW-17 protected deep link | ⏳ NOT RUN | needs deep-link setup |
| FLOW-18 unknown route | ⏳ NOT RUN | needs deep-link setup |
| FLOW-19 list edge cases | ⏳ NOT RUN | |
| FLOW-20 password reset | ⏳ NOT RUN | |
| FLOW-21 onboarding once | ⏳ NOT RUN | needs clean install |
| FLOW-22 onboarding skip | ⏳ NOT RUN | needs clean install |
| FLOW-23 environment banner | ⏳ NOT RUN | relaunch per flavour |
| FLOW-24 accent re-theme | ⏳ NOT RUN | check amber/teal contrast |
| FLOW-25 language switch | ⏳ NOT RUN | watch for clipped Spanish |
| **FLOW-26 offline → auto-sync** | ⏳ NOT RUN | **highest value of the new set** |
| FLOW-27 no sync on cold start | ⏳ NOT RUN | |
| FLOW-28 analytics opt-out | ⏳ NOT RUN | needs DebugView, staging build |
| FLOW-29 push opt-in | ⏳ NOT RUN | needs APNs/FCM setup |
| **FLOW-30 notification tap** | ⏳ NOT RUN | **cold-start case is the risky one** |
| FLOW-31 token rotation | ⏳ NOT RUN | needs reinstall |
| FLOW-32 update gate | ⏳ NOT RUN | edit config/app_update |
| FLOW-33 list paging | ⏳ NOT RUN | seed 60 notes |

**Final state check:** restore the baseline note count and theme, and sign back
in as the main account.

---

## When a flow finds a bug

1. Record it in the table below with a `BUG-NNN` id.
2. **Write a failing widget or unit test first** if the bug is reachable without
   a device. Most are — the value of these flows is often revealing a case the
   suite could have covered but did not.
3. Fix it, and check whether a spec requirement is missing or wrong. If the bug
   was possible, the spec probably has a gap.

| Bug | Flow | Description | Root cause | Fix | Regression test |
|---|---|---|---|---|---|
| — | — | — | — | — | — |
