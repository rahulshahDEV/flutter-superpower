# Theme and Design System

Read `ui-workflow.md` for screen implementation, `fonts.md` for font delivery, and
`platform-ui.md` for system bars. The runnable baseline lives in `templates/app/lib/core/`.

## Ownership

| File | Responsibility |
|---|---|
| `theme/app_colors.dart` | Raw brand palette; no colors inline in widgets |
| `theme/app_text_styles.dart` | Shared type roles, font metrics, optional bundled family |
| `theme/app_theme.dart` | ColorScheme, TextTheme, component themes, overlay defaults |
| `extensions/size_extensions.dart` | AppSizes spacing/radius tokens and gap widgets |
| `constants/string_constants.dart` | User-visible copy; ARB when localization is required |
| `constants/media_constants.dart` | Asset paths |

Use ColorScheme semantic pairs (`primary/onPrimary`, `surface/onSurface`, error roles) in
components. AppColors is the palette, not a reason to hardcode light colors across dark UI.
Add a ThemeExtension only for roles not already expressible by Material's schemes. When
dark mode is required, define and inspect both themes; don't claim support from a brightness
flag or mechanical inversion. Existing apps retain their established semantic-color API.

Map AppTextStyles into TextTheme so dialogs, inputs, buttons, and explicit app text use the
same metrics. Preserve inherited foreground colors. Widgets use named type roles or
`AppTextStyles.body.copyWith(...)`, not ad-hoc TextStyle/GoogleFonts calls. Line-height is a
ratio. The baseline uses system fonts with stable logical sizes and preserves TextScaler.

## Sizing contract

ScreenUtil is a design-sizing tool, not the responsive-layout algorithm. Initialize it once
at the app root with the app's design size, `minTextAdapt`, and `splitScreenMode`.
Use LayoutBuilder/constraints for layout changes and AppSizes for spacing. The baseline
bounds spacing scale so a tablet doesn't become a magnified phone; choose actual bounds
from the product and inspect both extremes.

Gap widgets accept already-resolved logical pixels. `VerticalSpace(AppSizes.md)` and
`HorizontalSpace(AppSizes.sm)` must not apply `.h`/`.w` again. If an existing app's gap API
accepts raw design values, keep that contract and don't feed it pre-scaled tokens.
Never apply ScreenUtil twice to a value or use scaled values for platform touch minimums.
Use content-driven heights, minimum control sizes, flexible columns, and capped text width.
Don't multiply type size by full tablet width. Preserve the user's TextScaler.

## Components

Reuse the project's K-widgets before adding new wrappers. The scaffold includes KButton,
KTextField, loading/empty/error widgets, and AppSnackBar. Other useful components (image
renderer, skeleton, drag handle, selection sheets) are capability examples, not files that
already exist or an instruction to create them all.

- KButton: text, nullable callback, variant, optional icon, loading, optional minimum height.
  It expands for long/large text, disables duplicate taps, and keeps an accessible name while
  busy. The minimum is not a fixed-height promise. Prefer existing Material states for hover,
  focus, pressed, disabled, and semantics; don't replace a button with GestureDetector.
- KTextField: forward the APIs required by the flow. A validating form needs TextFormField
  or an existing form abstraction, validators, focus, autofill, and submission wiring. Don't
  hide validation/focus limitations behind an attractive wrapper. Controllers belong to UI.
- Error state: a safe message plus retry when meaningful. Empty state explains what happens
  next. Image failures preserve layout and provide appropriate semantics.
- AppSnackBar may wrap ScaffoldMessenger; centralization does not require a custom overlay.
  Prefer inline error feedback for failed content and snackbars for transient actions;
  don't announce the same failure twice.

Configure common button/input/card behavior in ThemeData when shared. Keep semantic APIs
(e.g. primary/secondary action), avoid a bag of unrelated booleans, and promote a component
to core only for genuine cross-feature use. Keep private section widgets local.

## Screen composition

- Decide which region owns safe-area and keyboard padding; AppBar already handles top insets.
- Forms scroll; bottom actions stay reachable with large text and the keyboard open.
- Use directional padding/alignment when meaning follows reading direction.
- Prefer private StatelessWidgets for distinct layout/rebuild responsibilities. Tiny pure
  helper methods are fine; don't split everything into files or leak business logic into UI.
- Use ListView.builder/separated for long data; don't nest an unconstrained scrolling list
  inside a scroll view. Set padding deliberately, not always to zero.
- First load uses a skeleton matching content or one loader. Refresh keeps usable content;
  submit uses button progress; pagination uses a footer. Independent concurrent actions may
  each show progress, but don't stack duplicate indicators for the same operation.

## Verification

Cover interaction states, long copy, 2x text, a narrow width and a wide window. Test minimum
tap size, overflow, duplicate submissions, and accessible names in reusable controls.
Check text/background contrast, including disabled/loading states, with actual colors.
Use `design-review.md` for visual evidence; analyzer success doesn't establish UI quality.
