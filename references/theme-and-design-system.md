# Theme & Design System

## Files

```
core/theme/
├── app_colors.dart        # raw palette only (private ctor, static const)
├── app_semantic_colors.dart  # optional ThemeExtension layer
├── app_text_styles.dart   # static getters, no TextTheme wiring needed
└── app_theme.dart         # lightTheme (+darkTheme if app supports it)
```

`core/res/media.dart` / `media_constants.dart` for asset paths.
`core/constants/string_constants.dart` for copy.

## Colors

```dart
class AppColors {
  AppColors._();

  // ─── Brand ───────────────
  static const Color primary = Color(0xFF3B9AD9);
  static const Color primaryDark = Color(0xFF2E7CB0);

  // ─── Neutrals ────────────
  static const Color black = Color(0xFF323232);
  static const Color background = Color(0xFFF7F7F7);
  static const Color border = Color(0xFFE6E6E6);
  static const Color white = Color(0xFFFFFFFF);

  // ─── Semantic ────────────
  static const Color error = Color(0xFFD9534F);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFCAF17);
}
```

Optional semantic layer for multi-surface apps: `@immutable class AppSemanticColors
extends ThemeExtension<AppSemanticColors>` with ~30 fields (`screenBackground`, `surface`,
`primaryText`, `secondaryText`, `border`, ...), `copyWith` + `lerp`, registered via
`ThemeData(extensions: [semanticColors])`, read as `context.semanticColors`.

Widgets never use raw `Color(0x...)`. Either `AppColors.x` or `context.semanticColors.x`.

## Typography

```dart
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get h1 => _base(32, FontWeight.w700, height: 1.25);
  static TextStyle get h2 => _base(28, FontWeight.w600, height: 1.3);
  static TextStyle get h3 => _base(22, FontWeight.w600, height: 1.3);
  static TextStyle get bodyLarge => _base(17, FontWeight.w400, height: 1.5);
  static TextStyle get body => _base(15, FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall => _base(13, FontWeight.w400, height: 1.4);
  static TextStyle get caption => _base(12, FontWeight.w400, height: 1.3);
  static TextStyle get label => _base(14, FontWeight.w500, height: 1.4);

  static TextStyle _base(double size, FontWeight weight, {required double height}) =>
      GoogleFonts.inter(fontSize: size.sp, fontWeight: weight, height: height, letterSpacing: 0);
}
```

Rules:
- Line-height is passed as a ratio (`height: lineHeight / fontSize`).
- Widgets use `AppTextStyles.body.copyWith(color: colors.primaryText)` — never ad-hoc `TextStyle(fontSize: 14)` and never a new `GoogleFonts.*` call outside `app_text_styles.dart`.
- `AppTheme.lightTheme` maps the same styles into `TextTheme` for Material widgets.

## Sizing (flutter_screenutil)

```dart
// core/extensions/size_extensions.dart
class AppSizes {
  AppSizes._();

  static const Size designSize = Size(390, 844); // some apps use 375x812 — match the app

  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;

  static double get radiusSm => 4.r;
  static double get radiusMd => 8.r;
  static double get radiusLg => 12.r;
  static double get radiusXl => 16.r;
  static double get radius2Xl => 24.r;
  static double get radiusFull => 999.r;
}

class VerticalSpace extends StatelessWidget {
  const VerticalSpace(this.height, {super.key});
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(height: height.h);
}
```

`ScreenUtilInit(designSize: AppSizes.designSize, minTextAdapt: true, splitScreenMode: true)`
wraps `MaterialApp.router` in `app.dart`. Dimensions use `.w/.h/.r/.sp`; spacing/radius
uses `AppSizes` tokens. Never raw `EdgeInsets.only(left: 16)`.

## Design system widgets (`core/widgets/`)

| Widget | API |
|---|---|
| `KButton` | `KButton(text:, onPressed:, isLoading:, variant: primary/secondary/outlined, leadingIcon:, height: 52)` — in-button spinner replaces label while loading |
| `KTextField` | `KTextField(controller:, hintText:, errorText:, prefixIcon:, keyboardType:, borderStyle:)` |
| `ImageRenderer` | `ImageRenderer(imagePath:, fit:, width:, height:)` — asset/network/SVG/file + placeholder/error fallback in one widget |
| `EmptyStateWidget` | icon + title + message |
| `ErrorStateWidget` | message + optional `onRetry` (Retry button label from constants) |
| `LoadingWidget` | centered spinner + optional message |
| shimmer | `AppShimmerZone` / `BaseSkeletonShimmerWidget` + per-feature `_shimmer.dart` skeletons that mirror real layout |
| `AppSnackBar` / `CustomSnackBar` | top-anchored animated overlay: `.show(context, msg)` success, `.showError(context, msg, actionLabel:, onAction:)` — never raw `ScaffoldMessenger` |
| `BottomSheetDivider` | standard drag handle + indents |
| `AppBackButton` | default `context.popRoute()` |
| `AppAlertDialog` | typed `AlertDialogType` enum carrying icon/title/copy; `show()` returns `Future<bool?>` |
| `ConnectivityWrapper` | app-root only; `checkConnectivity()` called from the Dio interceptor |
| selection sheets | `RadioSelectionSheet`, `MultiSelectionSheet`, `CountryCodePickerSheet`, `DateSelectorDialog` |
| `LottieRefreshIndicator` | pull-to-refresh |

Bottom sheets are top-level functions, not classes:

```dart
void showSortSheet(BuildContext context, {required ValueChanged<Sort> onSelected}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.semanticColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radius2Xl)),
    ),
    builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
      const BottomSheetDivider(),
      ...
    ]),
  );
}
```

Loading rules:
- Page first load → shimmer skeleton mirroring layout, or `LoadingWidget`.
- Submitting → `KButton(isLoading: true)`; no separate spinner.
- Pagination → small footer indicator; no full-screen loader.
- Never two loaders on one screen.

## Strings

All copy in `core/constants/string_constants.dart` or
`core/constants/text/<feature>_text.dart`, section-commented. Parameterized copy
is a static function. Widgets never contain string literals for user-visible text.

## Screen composition conventions

- `Scaffold(backgroundColor: colors.screenBackground)` + `SafeArea`.
- `Padding(horizontal: AppSizes.md or 20.w)` page gutter; `SingleChildScrollView` for forms; sticky CTA at the bottom with a fixed gap.
- Keyboard: unfocus on outside tap (`GestureDetector`/`TapRegion`), respect `MediaQuery.viewInsets.bottom`.
- Private `_buildXxx()` helper methods inside the screen file for local sections; extract a widget file only when reused or large.
- Lists: `ListView.builder` with `padding: EdgeInsets.zero` and `AppSizes` gaps; separators via `separatorBuilder`.
