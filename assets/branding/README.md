# Branding assets

Drop your own artwork here, then regenerate:

```sh
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Both are configured in `pubspec.yaml`.

| File | Size | Notes |
|---|---|---|
| `icon.png` | 1024×1024 | **No transparency, no rounded corners.** Every platform applies its own mask; baking one in produces a double-rounded icon. |
| `icon_foreground.png` | 1024×1024 | Android adaptive foreground. Keep the logo inside the central ~66%, or the launcher will crop it. |
| `splash.png` | ~1152×1152 | Centred logo on a transparent background. Android 12+ crops to a circle, so keep it well inside the frame. |
| `splash_dark.png` | ~1152×1152 | Dark-mode variant. |

Placeholders are **not** committed — a template shipping its own logo into your
app store listing is worse than a build error telling you to add one.

`flutter_native_splash` writes into `android/` and `ios/`; commit what it
generates so a fresh clone does not need the tool to build.
