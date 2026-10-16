# Assets guide

The factory prepares native icon/splash configuration and validates files. It
never invents brand artwork: supply real source graphics or report them
missing. Validation checks files, not store acceptance.

## Source art

Per app, configured in `app.yaml` under `assets`:

| Key | Path | Requirement |
|---|---|---|
| `icon` | `assets/branding/icon.png` | 1024×1024 PNG, no alpha (iOS strips it) |
| `splash` | `assets/branding/splash.png` | Centered mark with padding; Android 12+ and iOS launch constraints differ |

Keep source art, generated variants, and store screenshots inside the app's
own directories. Never reuse another app's brand.

## Workflow

```bash
python3 automation/scripts/factory.py assets battery_analyzer   # prepare + validate config
python3 automation/scripts/factory.py assets battery_analyzer --execute  # generate native variants (needs real art)
```

`assets` writes `flutter_launcher_icons.yaml` and
`flutter_native_splash.yaml` (refuses to overwrite differing configs
silently); `--execute` resolves the generator dependencies and runs them.
Verify the home-screen icon and launch appearance on a device or simulator.

## Screenshots

Check the current official size/device requirements in
`docs/android-publishing.md` and `docs/ios-publishing.md` before capturing.
One phone screenshot does not cover every required device family. Mark
`assets.reviewed: true` only after genuine visual review.
