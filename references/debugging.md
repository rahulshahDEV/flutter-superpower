# Debugging (house style)

## The loop

```
1. Reproduce        — exact screen, exact state, dev flavor, device/emulator
2. Locate the layer — symptom → layer table below
3. Hypothesize      — one sentence: "X is null because Y"
4. Verify           — log/breakpoint BEFORE editing
5. Fix root cause   — grep every caller of the thing you're touching; fix where all callers route through
6. Add a check      — a test that fails if it regresses (see testing.md)
```

Never edit code to "see if it fixes it". One hypothesis at a time. If two fixes were
needed, one of them was wrong.

## Symptom → layer

| Symptom | Layer to inspect first |
|---|---|
| UI shows nothing / wrong widget | cubit state + `switch`/`maybeMap` exhaustiveness |
| Spinner forever | cubit emitted loading but fold path never emits loaded/failed |
| Snackbar never shows | `BlocListener` not wrapping the right subtree; failure swallowed by repo |
| `Failure` message is generic | data source threw non-typed exception; `safeApiCall` fell into `on Object` |
| 401/redirect loop | token refresh single-flight guard; auth whitelist path matching |
| Screen blank after navigate | route builder returned fallback (bad `extra`); check `fromExtra` |
| Overflow stripes | fixed sizes in a constrained row/column; missing `Expanded`/`Flexible` |
| Data renders then vanishes | stale async response (missing request-id guard) or `safeEmit` after close |
| Only prod broken | `.env.prod` key missing; proguard/R8; release signing; FCM APNs config |

## Tools (in order of cheapness)

1. `flutter analyze` — most bugs are analyzer errors; run it before anything else.
2. `AppLogger.d/i/w/e(message, name: 'Class')` — dev-only, already everywhere. Add temporary
   logs at layer boundaries (repo in/out, cubit emit), remove them after.
3. Dio `PrettyDioLogger` (dev only) — request/response bodies + status codes. For non-Dio
   (or the `http`-based variant), `HttpPrettyLoggerInterceptor` does the same.
4. Breakpoints / `debugger()` in the IDE — for control flow, not data shapes.
5. DevTools: widget inspector (tree + overflow), performance (jank), network (if using `http`),
   memory (image/video leaks).
6. `flutter run --verbose` — plugin/native build failures (pods, gradle, manifest merge).
7. `flutter doctor -v`, `dart pub deps --style=compact` — environment/dependency conflicts.

## House-style failure modes

| Error | Cause | Fix |
|---|---|---|
| `Object/factory with type X is not registered inside GetIt` | annotation missing, or generated DI stale | add `@injectable`/`@LazySingleton(as:)`, then `fdev gen` |
| `Missing part 'x.g.dart'` / `_$XFromJson` undefined | generated files not rebuilt after annotation change | `fdev gen` |
| `'X' isn't defined` after renaming a cubit method | stale `.freezed.dart`/`.g.dart` referencing old name | `fdev gen`, then analyze |
| `emit was called after close` | async completed after screen disposed | `SafeCubit.safeEmit` (already), plus `if (isClosed) return;` after awaits |
| `setState() called after dispose` | dialog/sheet callback after pop | `if (!mounted) return;` |
| `Firebase.initializeApp` in widget tests | tests build `App` without Firebase | guard `if (Firebase.apps.isEmpty) return;` |
| `.env` asset not found | `.env.dev`/`.env.prod` not declared under `flutter: assets:` | declare them |
| `GoException: no routes for location` | route not registered / path built wrong | use `XScreen.pathFor(...)` constants, never string literals |
| Push works foreground, not background | missing `@pragma('vm:entry-point')` or channel not created in background isolate | check `fcm_background_handler.dart` |
| Works debug, fails release (Android) | R8 stripping models/plugins | keep rules / `minifyEnabled` config |
| `pod install` mismatch / iOS flavor fails | xcconfig chain / scheme missing | check `FLUTTER_TARGET` per config |
| Keyboard covers CTA | no `viewInsets` handling | scroll view + `MediaQuery.viewInsets.bottom` padding |
| Unbounded height / list not scrolling | `ListView` inside `Column` without `Expanded` | wrap in `Expanded` or use `CustomScrollView` slivers |
| Image blank | wrong resolver for path type (S3 key vs full URL) | route through `ImageRenderer` + `MediaUrlResolver` |
| `RenderFlex overflowed` only on small phones | raw pixel sizes | `.w/.h/.r` + `AppSizes`; test at 320pt width |

## Bug-fix discipline

- **Grep every caller before editing** the function — fix once where all callers route through,
  not per call site (this is the lazy fix AND the root-cause fix).
- A report names a symptom, not a location. Trace the flow end to end first.
- Data bugs: log the raw response at the data source, not the mapped entity.
- State bugs: log every `safeEmit` transition, not the final state only.
- Navigation bugs: log `state.extra`/`pathParameters` in the route builder.
- Never "fix" by widening a type to `dynamic`, catching `Object` silently, or adding `!`.

## Red flags — stop and re-diagnose

- Fixing the second symptom before understanding the first.
- Adding a retry/timeout to hide a race instead of finding the stale request.
- Wrapping in `try/catch` with an empty body to silence a stack trace.
- "Works on my machine" — compare flavor, env file, and device API level.
- Editing generated files (`.g.dart`, `.freezed.dart`, `injection.config.dart`).
