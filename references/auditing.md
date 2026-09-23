# Auditing an Existing Flutter Project

The audit evaluates a project against the flutter-superpower architecture **without
changing it**. Findings are reported with evidence; fixes are a separate, approved task.
The existing architecture is never the finding — deviations from it are.

## Run

```bash
scripts/audit.sh /path/to/app             # static checks + format + flutter analyze
scripts/audit.sh /path/to/app --tests     # also runs flutter test
scripts/audit.sh /path/to/app --static    # no toolchain: greps + file sizes only
```

The script is read-only. It prints a mechanical report (✅/⚠/❌ with counts). Then do the
agent review below — the script cannot judge architecture or state modeling.

## Agent review — dimensions and checks

### 1. Architecture & boundaries
- `core/` importing `features/`; widgets calling data sources or Dio directly.
- Layer inversions (domain importing Flutter/plugins; presentation doing data work).
- Features missing layers they clearly need, or layers with no purpose.
- Files with multiple unrelated responsibilities (large ≠ broken; responsibility is the test).

### 2. State management
- Mixed state solutions (two of Cubit/Riverpod/Provider/GetX).
- `emit` after close, missing stale-request guards, business logic in widgets.
- Missing `initial/loading/error/empty` branches; unhandled failure states.
- App-root providers for screen-local state (or vice versa).

### 3. Data & networking
- Bypassed repository layer; raw `Dio`/`http` in presentation.
- Unhandled error branches; raw exceptions reaching the UI; silent `catch`.
- Unsafe casts, `!` on API fields, missing null/absent-field handling.
- Auth token handling: refresh single-flight, logout on 401, secrets not logged.

### 4. UI & design system
- Hardcoded colors, text styles, spacing, and user-facing strings.
- Duplicated widgets that the design system already provides.
- Oversized `build()` methods; deeply nested anonymous trees.
- Missing `const`, unbounded lists, missing `ListView.builder`.

### 5. Testing
- No tests for non-trivial cubits/parsers/validators; tests asserting nothing.
- Missing error/empty-state tests; tests depending on real network/time.
- Test paths not mirroring `lib/`.

### 6. Performance
- Rebuild storms (`BlocBuilder` wrapping whole screens without `buildWhen`/`select`).
- Expensive work in `build`; images decoded at full size; unbounded lists.
- Missing pagination where the API paginates; repeated formatter/controller creation.

### 7. Security & privacy
- Hardcoded keys/secrets; tokens in logs; debug logging in release paths.
- Secrets in SharedPreferences instead of secure storage.
- Unsafe WebViews/deep links; excessive permissions; debug config in release builds.

### 8. Accessibility & localization
- Missing `Semantics`/labels on icon-only controls; tap targets < 48dp.
- Layouts that break with large text scaling.
- Hardcoded strings when the project localizes; date/currency not using the locale.

### 9. Release readiness
- Version/build number, env endpoints per flavor, signing, icons/splash, permissions,
  FCM/deep-link config, ProGuard/R8, obfuscation, analytics/crash config per environment.

## Report format

```
FLUTTER SUPERPOWER AUDIT — <app>
Profile: feature-first · Cubit · GoRouter · Dio+Either · json_serializable · flutter_test

Architecture    ✅ layers clean        ⚠ 2 oversized presentation files
State           ✅ single solution     ⚠ missing stale-request guard in OrdersCubit
Data            ❌ raw Dio in ProfileScreen (lib/features/profile/.../profile_screen.dart:88)
UI              ⚠ 14 hardcoded colors · 6 inline strings
Testing         ⚠ 9 features, 3 tested (orders, auth, chat)
Performance     ✅ builders used      ⚠ 2 unbounded lists
Security        ✅ no secrets logged  ❌ debugPrint of token (lib/core/network/dio_client.dart:41)
Accessibility   ⚠ icon-only buttons missing labels (5)
Localization    ✅ consistent (StringConstants)
Release         ⚠ release signing uses debug keystore
```

Rules for the report:
- Every finding carries `file:line` evidence and a one-line fix.
- Rank by severity (❌ breaks correctness/security; ⚠ quality; ✅ pass), then by blast radius.
- Never propose replacing the architecture. Propose the smallest fix inside it.
- Do not fix during the audit unless the developer asks; offer the fixes as a follow-up list
  (each independently shippable, same verify gate).
