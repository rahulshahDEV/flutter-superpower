# Networking and Error Ownership

The runnable source of truth is the app/feature templates. Reuse an existing application's
clients, failure family and envelope contract; don't create a competing error stack.

## Boundaries

Data source → typed exceptions (including DioException) → repository safeApiCall →
FutureEither<T>/Either<Failure,T> → Cubit fold → UI state and safe feedback.

- Data sources own transport/JSON parsing and return models, never Either or widgets.
- Repository methods wrap their work once and return domain outcomes. Don't wrap every
  inner helper or throw transport exceptions after constructing a Failure.
- Use cases expose business operations; the template UseCase/NoParams contract supplies
  the seam. Keep business invariants out of interceptors and JSON constructors.
- Cubits interpret outcomes; UI owns retry/navigation/snackbar presentation.

## Client configuration and lifecycle

The scaffold DioClient uses public AppConfig, bounded timeouts and one DI registration.
It has no auth/payload logger until required. Use the shared client rather than creating a
new Dio in every feature. Inject replaceable infrastructure through constructors, not hidden
service-locator calls inside business logic. Match DI lifetime to connection/subscription
ownership. Don't register the same client via both a module factory and class annotation.

Define connection/receive/send timeouts, cancellation ownership and retry policy per operation.
A cancelled request should not become a visible server error after its screen has left.
A timeout doesn't prove the server abandoned a write. Retry idempotent reads with bounded
backoff where needed; use backend-supported idempotency for retried mutations. Don't retry
arbitrary POST requests because a connection disappeared.

Connectivity hints are UX information, not proof an API is reachable. Treat each request's
actual result as authoritative. A connectivity banner/check is optional infrastructure,
not a required ConnectivityWrapper class that must exist in every app.

## Authentication when required

Constructor-inject a secure session store and a session invalidation boundary. Keep token
storage/refresh policy outside widgets and repositories that don't own authentication.
Use a separate refresh client so refresh failures cannot recursively trigger refresh.

- Attach auth only to approved API hosts/paths; never leak a token to a presigned/upload URL.
- Exclude login, OTP and refresh endpoints explicitly: their 401 is an operation failure.
- Single-flight refresh: concurrent protected 401s share one refresh, not one per request.
- Retry an eligible request at most once after refresh, retaining method/body/headers and
  cancellation semantics. Streams/multipart bodies may need a recreated request body.
- Don't restore a session after logout: associate refresh with session identity/generation
  and reject completion from the old session. A transient refresh outage need not always
  erase a valid local session; follow the backend/product contract.
- Confirmed invalid/revoked session triggers one session cleanup outcome. Router composition
  observes it; HTTP code does not import screens or call go(). Generic 403 is not logout.
- Preserve safe account-restriction messages and the intended post-login destination.

New auth tokens use Keychain/Keystore-backed storage; plain preferences are for non-secret
settings. An existing insecure session store needs a deliberate migration/cleanup plan.
See security.md and auth-social.md for platform/auth setup.

## Parsing and backend drift

Validate the endpoint's documented envelope before mapping. ApiResponseHandler in the
scaffold handles a map or its map-valued data field; it isn't a universal list/pagination
parser. The feature template explicitly handles a list or data-list. Missing, null, wrong
shape and valid empty data are distinct outcomes. Reject malformed required records rather
than silently dropping them with whereType and reporting partial data as complete.

Prefer generated fromJson for stable schemas. If supporting a documented transition (e.g.
alternate key spelling, flat versus nested user), define a deterministic fallback order,
validate the selected value and test both shapes. Don't turn every field nullable or accept
unknown coercions to conceal backend errors. Keep compatibility parsing in the data layer.

Models extend Equatable entities by default; map separate DTOs when inheritance would weaken
domain invariants. API/storage schema changes require all callers and persisted data to be
considered, not just the currently visible screen.

## Failure mapping and diagnostics

Use one Failure family per app. The baseline ApiExceptionHandler maps network/timeout,
unauthorized, validation, not-found, cache and server outcomes to category-specific safe copy.
Preserve DioException until that boundary; catching it in a source and replacing it with
ServerException destroys offline/401/422 classification. Unexpected failures use safe
fallback constants, never exception.toString, statusMessage, raw HTML or server stack text.

A backend message is displayable only when the API contract guarantees user-safe copy;
otherwise map codes/statuses to app copy. A structured error body is not automatically safe.
Use a typed domain failure for meaningful restrictions; don't scatter status checks in UI.

Keep useful internal diagnostics separate from user feedback. Log allowlisted method/route
template/status/timing/correlation IDs, never tokens, full URLs/query strings, headers or
payloads by default. Dev-only logging is not redaction. Unexpected errors can be reported
with sanitized context and stack traces through the app's existing reporting boundary;
reporting doesn't make an operation recoverable. Non-critical sync needs an observed failure
path and fallback rather than an empty best-effort catch.

## Uploads and UI feedback

Use a dedicated presigned client that bypasses API auth interception for the intended
storage host. Validate local size/type before requesting the upload URL, keep signed URLs
out of logs, and define progress/cancel/retry and post-upload confirmation behavior. Don't
retry an expired URL indefinitely or report completion before the server accepts the result.

No-content errors render inline with retry. Action failures may show AppSnackBar while
retaining usable content/input. Refresh failures preserve loaded items; pagination failures
use footer retry. Avoid duplicate snackbar/inline announcements for the same event.

## Verification

Test failure categories across the actual source/repository boundary, malformed records,
valid empty/success data, safe fallback messages and cancellation. Auth changes also cover
concurrent refresh, retry bounds, auth endpoint exclusion and logout during refresh. Upload
changes exercise the correct client/host and late progress after disposal. Use deterministic
fixtures/fakes for contracts and a controlled integration environment for real backend claims.
