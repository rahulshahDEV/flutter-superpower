# Social Auth — Google & Apple (end to end)

Full feature, not a button: native SDK → backend token exchange → session persistence →
route. Use the project's existing auth architecture; if it has none, build it in the
house layers.

## Flow

```
UI (SocialButton)
  ↓  cubit.signInWithGoogle()
Cubit (loading → success | failure)
  ↓  use case
Repository  →  AuthRemoteDataSource  →  backend exchange (idToken)
  ↓  FutureEither<AuthSession>
Session store (tokens + user JSON)
  ↓
Router (onboarded ? home : profile setup)  +  device/FCM registration
```

## Packages

- `google_sign_in` ^7 (v7 API: `GoogleSignIn.instance`)
- `sign_in_with_apple` ^7
- No Firebase Auth unless the project already uses it — the backend exchanges the provider
  token for the app's own session.

## Google Sign-In — platform setup

**Android**
1. Create an OAuth client (type Android) in Google Cloud Console with the app's package name
   and SHA-1/SHA-256. Get SHAs with `fdev sha` (or `keytool -list`).
2. Add **both** debug and release keystore SHAs — release SHA mismatch is the #1
   `ApiException: 10 DEVELOPER_ERROR` cause.
3. If Firebase is used: `google-services.json` per flavor (gitignored), Google Sign-In
   enabled in the Firebase project.

**iOS**
1. OAuth client (type iOS) → note the iOS client ID and the **reversed client ID**.
2. `Info.plist` → `CFBundleURLTypes` with the reversed client ID as a URL scheme.
3. `serverClientId` = the iOS client ID when exchanging on a backend.

**Code**

```dart
// once, at startup or first use
await GoogleSignIn.instance.initialize(serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID']);

// on tap
try {
  final account = await GoogleSignIn.instance.authenticate();
  final idToken = account.authentication.idToken; // may be null if serverClientId unset
  if (idToken == null) throw const UnauthorizedException('Missing Google idToken');
  return _exchange(idToken); // POST /auth/google
} on GoogleSignInException catch (e) {
  if (e.code == GoogleSignInExceptionCode.canceled) return const Left(AuthCanceledFailure());
  return const Left(UnauthorizedFailure());
}
```

## Apple Sign-In — platform setup

1. Apple Developer → Identifiers → App ID → enable **Sign in with Apple**.
2. Xcode → target → Signing & Capabilities → add the capability (entitlement committed).
3. For Android/web flows: create a **Service ID** + key, set the redirect URI, and configure
   the same values in `sign_in_with_apple` (`WebAuthenticationOptions`).
4. iOS shows name/email **only on first authorization** — persist them immediately; later
   logins return only `userIdentifier`.

```dart
try {
  final credential = await SignInWithApple.getAppleIDCredential(
    scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
  );
  final identityToken = credential.identityToken;
  if (identityToken == null) throw const UnauthorizedException('Missing Apple identityToken');
  return _exchange(identityToken, authorizationCode: credential.authorizationCode,
      fullName: credential.givenName); // POST /auth/apple
} on SignInWithAppleAuthorizationException catch (e) {
  if (e.code == AuthorizationErrorCode.canceled) return const Left(AuthCanceledFailure());
  return const Left(UnauthorizedFailure());
}
```

**App Store rule (Guideline 4.8):** if the app offers any third-party sign-in (Google,
Facebook), it must also offer Sign in with Apple. Design the button per HIG (black/white,
Apple logo, equal prominence).

## Backend exchange & session

- `POST /auth/google` / `POST /auth/apple` with the provider token (+ authorization code for
  Apple). Response: access + refresh tokens + user.
- Persist through the existing session store (tokens + `jsonEncode(user)`); never log tokens.
- After success: register device/FCM token, load profile, then route
  (`onboarded ? home : onboarding`).
- Logout clears through the single session-cleanup path; Apple note: Apple does not provide a
  logout — revoke locally and call the backend's revoke if implemented.

## Failure mapping (never surface raw errors)

| Case | Failure | UI |
|---|---|---|
| User cancels | `AuthCanceledFailure` | silent (no snackbar) |
| Provider error / missing token | `UnauthorizedFailure` | "Sign-in failed, try again" |
| Network/timeout | `NetworkFailure` | retry snackbar |
| Backend 401/invalid token | `UnauthorizedFailure` | "Session expired" |
| Account suspended / underage | dedicated Failure | dialog + redirect |

## Testing

- Fake repository → cubit tests: success, failure, cancel (silent), loading state.
- Widget test: button disables while loading, no double invoke.
- Native sheet cannot be unit-tested: cover with one manual/integration pass on a device.
- `SharedPreferences.setMockInitialValues({})` for session-store tests.

## Common failures

| Symptom | Cause |
|---|---|
| `ApiException: 10` (Google) | SHA-1/256 mismatch — add the release keystore SHA |
| Dialog never appears | `initialize()` not called, or wrong client ID |
| `idToken == null` | `serverClientId` missing/mismatched platform client |
| Apple `invalid_client` | Service ID / key / redirect URI mismatch |
| Works debug, fails release | release SHA missing, or debug-only config |
| Email missing on Apple login | first-login-only data not persisted |
| Store rejection 4.8 | third-party login offered without Apple Sign-In |
