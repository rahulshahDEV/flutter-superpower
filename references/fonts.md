# Fonts and Typography Delivery

Choose typography from the product's content, language coverage, and brand. Keep an existing
app's family unless changing it is in scope. System fonts are a valid offline default;
Google Fonts is an option, not a requirement for every app.

## Choose a delivery path

| Need | Choice |
|---|---|
| No specified brand face | System font + shared type roles; no new dependency |
| Fixed custom face with known weights | Bundle licensed font files via pubspec fonts |
| Google Fonts API already used | Bundle matching assets, disable runtime fetching |
| User-selectable online font catalog | Explicit runtime-download UX, loading/failure/cache behavior |

For `google_fonts`, verify the installed package's supported Flutter/Dart versions and font
metadata. Add only the family/styles actually used; include italic and weight variants when
needed, avoid fake bold/italic, and check script fallback. Keep the font license in the app's
license registry (e.g. LicenseRegistry.addLicense) and distribution. Don't fetch font assets
on first launch in a fixed-brand production app or in golden tests.

Before the first `GoogleFonts.*` style is built, set:

```dart
import 'package:google_fonts/google_fonts.dart';

void configureGoogleFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
}
```

This setting does NOT bundle fonts. Obtain the matching font files, preserve the naming
expected by that package version, declare the directory in pubspec `assets`, and verify all
used styles resolve. Missing assets must fail validation rather than be hidden with a test
mock. With direct `fontFamily` delivery, declare files/weights under `flutter: fonts:`
instead. Do not maintain two delivery paths for the same face without a reason.

Official setup: [google_fonts asset bundling and licensing](https://pub.dev/packages/google_fonts).

## One typography system

`AppTextStyles` defines roles once. Map them into `ThemeData.textTheme` so Material controls,
forms, dialogs, and explicit app text share metrics. Use theme roles for inherited surface
colors; never bake a light-theme foreground into every style. Add semantic ThemeExtensions
only for roles ColorScheme/TextTheme cannot express.

Keep font sizing independent of full-window width on tablets. If the app scales type using
ScreenUtil, bound the design scale once; preserve Flutter's user TextScaler afterwards.
Never shrink-to-fit or globally clamp accessibility scaling to rescue a layout.
Use flexible controls and wrapping labels. Test Latin and supported non-Latin scripts,
long translations, digits, bold/italic, and 2x text scale.

## Evidence

Run a clean-install offline launch (a warm font cache can hide missing assets). Widget and
golden tests must load the same bundled fonts or explicitly use the scaffold's system font;
record which. Inspect the license screen and package contents. Measure font asset size and
first-frame behavior before adding more families/weights.
