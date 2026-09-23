# Security Engineering

Scope: mobile app security inside the house architecture. Never invent a security layer that
competes with it — harden the existing one.

## Secrets

- `.env.dev` / `.env.prod` are gitignored; `.env.sample` documents keys with fake values.
- Keys in CI come from repository secrets, written at build time — never committed.
- `android/key.properties`, keystores, `google-services.json`, `GoogleService-Info.plist`,
  `GoogleService-Info`/APNs keys: gitignored, never printed.
- Firebase client API keys in `firebase_options.dart` are public by design (not secrets);
  real secrets are service accounts, server keys, and payment keys.

## Logging (the most common leak)

- `AppLogger` is dev-only by design — never log tokens, passwords, OTPs, payment data, or
  full request/response bodies containing auth headers, even in dev.
- The Dio pretty logger prints request headers (including `Authorization`). In dev-only builds
  that is tolerated, but redact before it can reach a release build: either gate the logger on
  `AppConfig.isDev` (already the pattern) or add a redaction interceptor.
- Crash reporting (Sentry/Crashlytics): configure scrubbing; never attach raw network payloads.

```dart
// Redaction pattern for any request logger
const _redacted = {'authorization', 'cookie', 'x-refresh-token'};
final headers = Map.of(options.headers)
  ..updateAll(_redacted, (v) => '***');
```

## Storage

- Tokens: `flutter_secure_storage` (Keychain/Keystore) when the project uses it; SharedPreferences
  only where the project already does and the threat model accepts it.
- Never store passwords, card numbers, or raw crypto private keys in SharedPreferences.
- Clear all auth artifacts on logout through the single session-cleanup path.

## Transport & API

- HTTPS only; no `http://` endpoints in `lib/` (audit flags them).
- Validate/sanitize anything user-supplied before it reaches a URL, file path, or query.
- Auth: single-flight token refresh, logout on 401/refresh failure, no retry storms.
- Never trust `state.extra` or deep-link parameters — parse defensively (`fromExtra` + fallback).

## WebViews & deep links

- Whitelist navigable hosts; block `file://`, `javascript:`, and arbitrary redirects.
- No JS bridge exposed unless required; validate every message received from JS.
- Deep links: whitelist route prefixes, validate parameters, never auto-execute actions.

## Permissions

- Least privilege: remove manifest/Info.plist permissions the app does not use.
- Ask in context with a reason; handle permanently-denied with a settings path.
- Keep the permission matrix current — see `maps-location-health.md`.

## Release hardening

- No debug banner, no debug logging, no test keys in release.
- ProGuard/R8 enabled with keep rules for models/plugins; obfuscation for symbols if configured.
- Flavor config verified: dev builds must never point at production APIs or Firebase projects.

## Checklist per change

```
[ ] No secret, token, or password in code, logs, or committed files
[ ] New endpoint is https and validated
[ ] New storage is appropriate for the data's sensitivity
[ ] New permission is required and justified
[ ] Release path unaffected (logging gated, config correct)
```

Mechanical pass: `scripts/audit.sh <app>` → Security section. It cannot judge threat models —
that's the review pass.
