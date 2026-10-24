# Orientation and System UI

Platform policy belongs at the app boundary, not scattered through screens. Inspect the
app's supported devices, target SDKs, native configuration, and existing policy first.

## Orientation is a product decision

Default to the OS policy. A portrait-only phone workflow can request
`SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` after binding
initialization and before `runApp`. Await the request; it is not a universal guarantee.
Use an empty list to release a lock. Never lock orientation just to hide an overflow.

Android apps targeting API 36+ cannot impose that lock on displays >=600dp wide. On iPad,
orientation locking is respected only when multitasking is disabled; don't disable it
without a product requirement. If the policy varies with display width, use the current
FlutterView's display size/devicePixelRatio, not letterboxed MediaQuery dimensions, and
re-evaluate on metrics changes. Dispose the observer. A temporary landscape media screen
must restore the app's policy on exit, including interrupted navigation.

Source: [SystemChrome orientation API](https://api.flutter.dev/flutter/services/SystemChrome/setPreferredOrientations.html).
Recheck restrictions against the app's actual SDK when changing platform targets.

## Edge-to-edge and system bars

Configure `SystemUiMode.edgeToEdge` once during supported mobile startup. Targeting Android
15 enables edge-to-edge by default; Android 16 removes the opt-out. Do not lower target SDK
or rely on status/navigation bar background colors to repair contrast. Paint an appropriate
surface behind transparent bars and protect interactive content with insets.

Use `AppBarTheme.systemOverlayStyle` for normal app bars. For a screen without an AppBar,
use `AnnotatedRegion<SystemUiOverlayStyle>` around its painted surface. The scaffold has a
root region for that case; a route with a contrasting photo/header owns its local override.
Don't call `setSystemUIOverlayStyle` from every build and fight AppBar's region.

Choose styles from the brightness of the actual surface behind each bar, which can differ
from theme brightness. The predefined `.dark`/`.light` styles describe status-bar foregrounds; their navigation-bar
defaults may differ. Explicitly set `systemNavigationBarIconBrightness` for its actual surface. Android uses `statusBarIconBrightness`; iOS uses
`statusBarBrightness` with the opposite brightness convention. Prefer the predefined styles
and targeted copyWith overrides to avoid mixing those meanings. Navigation contrast scrims
may be platform-controlled; test both gesture and three-button navigation.

Source: [Flutter edge-to-edge migration](https://docs.flutter.dev/release/breaking-changes/default-systemuimode-edge-to-edge).

## Insets and keyboard ownership

- Let backgrounds extend behind bars; inset content that must be visible/tappable.
- AppBar and bottom navigation already handle some insets. Avoid double SafeArea padding.
- Keep one owner for keyboard displacement: Scaffold resizing or explicitly applied
  viewInsets in an overlay. Don't add the keyboard height twice.
- Dialogs and sheets need safe areas, scrollable content, and reachable actions with the
  keyboard open. Never use orientation locks or text-scale clamps to fix them.

Verify portrait/landscape where supported, narrow and tablet windows, light/dark surfaces,
keyboard open/close, modals, and route return. Widget tests can verify requested platform
calls and overlay values; only device checks establish actual native bar/orientation behavior.
