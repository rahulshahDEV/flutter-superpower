# Package Selection

Choose from the app's needs and installed SDK, not a memorized popularity list.
Existing architecture wins; adding a second state/router/DI/HTTP stack is a migration.

## Decision ladder

Existing project code → Flutter/Dart SDK → installed dependency → maintained package →
small owned implementation. Compare total maintenance and correctness cost: a short native
integration can be harder to own than a well-supported plugin. SDK examples include
AnimatedSwitcher, RefreshIndicator, date pickers, and jsonDecode. The SDK does not provide
a general cross-platform share-sheet API; evaluate a plugin when that capability is needed.

Keep the house architecture for greenfield: flutter_bloc, get_it/injectable, go_router,
dio, dartz/equatable, json_serializable, and flutter_screenutil. Fonts, image caching,
permissions, secure storage, notifications, databases, and Firebase are capability choices,
not an automatic shopping list. `templates/app/pubspec.yaml` is the tested starter;
its constraints are not a claim about today's newest versions.

## Evaluate before adding

1. State the concrete capability and target platforms. Inspect pubspec AND lockfile.
2. Read the candidate's current pub.dev page, official repository, changelog, and relevant
   platform installation docs. Compare one credible alternative when a new package has
   meaningful platform, architecture, size, or maintenance cost. Record source links/date.
3. Check SDK constraints, license, publisher ownership, issue/release health, supported
   platforms, transitive/native dependencies, minimum OS, permissions, privacy impact,
   binary size, offline behavior, and testability. Old publication date alone doesn't prove
   abandonment; assess open compatibility issues and maintainer responses.
4. For native/high-risk capabilities, validate a minimal integration on the target platform
   before building the whole feature around it. Pub resolution alone is insufficient.
5. Record choice, reason, rejected alternative, setup cost, and an exit path proportional to
   risk. A one-sentence note is enough for a small familiar dependency. Never fabricate
   maintenance evidence when browsing is unavailable; label what remains unverified.

Useful local checks:

```bash
flutter pub outdated
dart pub deps --style=compact
```

Do not upgrade unrelated packages just because this output lists newer versions.

## Integrate and verify

```bash
flutter pub add <package>
dart format .
fdev gen # if builders changed; fallback: dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Use compatible constraints, never `any`; commit the app lockfile. Review resolved changes
and native build configuration. Add permissions only for the feature, with denial behavior.
Build/run affected platforms using `fdev` where supported (e.g. `fdev apk dev`; fallback
`flutter build apk --flavor dev -t lib/main_dev.dart`). A device/plugin check is required for
claims about native behavior; do not claim iOS works from an Android build.

Keep domain contracts independent of plugin types. Wrap stateful/native infrastructure when
it provides a useful lifetime, test seam, or replaceable boundary; don't wrap every package
function. Keep one source of truth for initialization and disposal.

Constraint-only bumps to a version already resolved in the lockfile are allowed when needed
for compatibility/analyzer warnings; still disclose them and verify. Review major upgrades
against migration notes in a separate scoped change unless this feature requires one.

## Remove

Use `flutter pub remove <package>`, remove dead adapters/native setup, and inspect the
lockfile/transitive graph. Then format → codegen if needed → analyze → test and affected
platform build. Clean only to resolve a stale artifact (`fdev clean`; fallback
`flutter clean && flutter pub get`), not as a ritual that hides reproducibility problems.
