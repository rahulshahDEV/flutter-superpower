# App Lifecycle, Restoration and Durable Work

Load when a requirement survives route disposal, backgrounding or process recreation.
`async-safety.md` covers in-process async ownership; `platform-channels.md` covers native
bridges. These lifetimes are different: retaining a controller cannot make work durable.

## Classify state by recovery need

| State | Owner and recovery |
|---|---|
| Focus, animation, transient overlay | Widget; recreate intentionally |
| Tab/scroll/temporary form UI | Widget/router restoration where supported |
| User-created draft or pending write | Account-scoped durable repository; persist during editing |
| Session | Secure session store + startup coordinator; revalidate per auth contract |
| External job/upload | Durable job identity/status; reconcile with backend on restart |

Define what the product promises after backgrounding, OS process death, force-stop, logout
and app update separately. Restoration is not durable backup or authority for authorization.
Don't store credentials or large sensitive payloads in restoration data.

## Restore UI deliberately

For SDK restoration, provide a root restoration scope, stable unique restoration IDs and
restorable properties. A StatefulWidget using RestorationMixin registers properties in
restoreState and disposes them with its State. Re-registration can happen during the same
State lifetime; don't assume restoreState is a one-time init callback. Restore routing only
through mechanisms supported by the installed router and navigator setup.

Keep resource IDs/filters in restorable route data and reload authoritative records. Parse
missing/outdated restoration data defensively. Restore a draft through its repository ID,
not by serializing an entire state manager or BuildContext. Account changes invalidate
restoration scopes/draft access so the next user cannot inherit previous private UI.

For meaningful drafts, persist incremental changes with bounded debounce and an explicit
saved/saving/failure status. Flush at safe interaction points when needed, but don't rely on
dispose or a final lifecycle callback: the OS may terminate the process without running it.
A local save failure must not be presented as safely recovered later.

## Foreground and background transitions

Use one app-level lifecycle observer/listener for shared concerns; remove it with its owner.
Do not assume every state transition/callback will be observed. On resume, refresh only stale
or capability-dependent state: permission status, session policy, external job status and
expiring data. Coalesce repeated resume signals; don't start one refresh per visible widget.
Keep unsaved input while refreshing and ignore completions from an obsolete session.
Pause resources only when required by their capability/product contract. Navigation away,
inactive overlays, background execution and process termination are not interchangeable.

## Work that must survive process death

Choose an OS-supported scheduler or backend job from the actual deadline/capability.
A Timer, isolate, Cubit or notifier alone cannot guarantee execution after termination.
Inspect target SDK, entitlements, plugin registration and platform restrictions; Android
scheduled work and iOS background opportunities have different guarantees.

Persist an account-scoped job ID, inputs/version, status/checkpoint and retry policy before
reporting durable acceptance. Register a unique logical job where supported; coordinate it
with foreground work. Workers need their own supported initialization/DI context and must
not navigate, prompt permissions or use a screen's objects. Work must be interruption-safe
and duplicate-safe; use `offline-data.md` for leases, acknowledgements and reconciliation.

Define cancellation, logout, app update and stale job-input behavior. Record failed jobs and
last successful progress; avoid a retry loop with no deadline or observable outcome. Do not
promise exact periodic timing or force-stopped execution unless the platform contract does.

## Verification recipe

- Widget restoration test: edit/select/scroll, restart-and-restore via the installed test API,
  then check values and independent route instances. This is not an OS process-death test.
- Repository test: save draft, reconstruct repository/owner, recover it; inject save failure.
- Lifecycle test: repeated resume signals cause one eligible refresh; input survives failure.
- Device test: background then terminate using a platform-appropriate process-death procedure,
  relaunch and check persisted draft, route recovery and authoritative session guards.
- Worker test: interrupt after remote acceptance, rerun and verify one business effect; test
  duplicate scheduling, constraint changes, logout and account switch.

Record exact termination procedure and distinguish normal restart, Android Activity recreation,
OS process death and force-stop. Simulator tests don't establish hardware scheduling/battery
behavior. Claim only the lifecycle and platform paths actually exercised.

Sources: [Flutter restoration API](https://api.flutter.dev/flutter/widgets/RestorationMixin-mixin.html),
[Flutter app lifecycle](https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html),
[Android background work selection](https://developer.android.com/develop/background-work/background-tasks),
[Apple background tasks](https://developer.apple.com/documentation/backgroundtasks).
