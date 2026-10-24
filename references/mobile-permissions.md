# Permission UX and Lifecycle

Load whenever a feature accesses protected device/user data. Capability-specific details:
permission-capabilities.md; GPS/location: location-services.md. Follow the existing app's
architecture and installed plugin; permission_handler is an option, not an automatic dependency.
Guidance checked against primary documentation on 2026-10-24; recheck target OS/plugin rules.

## Plan the capability, not a generic Allow button

For each user action identify the minimum data/access needed, permission-free alternative,
platform versions, native declarations, granted scope, denial fallback and recovery action.
Prefer a system picker or an OS-owned interaction when it satisfies the job without broad
access. Request only that capability, at the relevant user action. Don't ask for all possible
permissions at startup, or block unrelated features after an optional permission is denied.

Explain purpose in plain language and preserve the user's draft/selection while requesting.
Use the system prompt directly when context is sufficient; add a concise, dismissible
rationale when needed. Avoid a compulsory custom "Allow" dialog before every OS dialog.
Request related permissions together only when the platform and this action call for it;
otherwise sequence them. A package's permission group isn't a promise about OS prompt grouping.

## Normalize outcomes without losing platform meaning

| Observed outcome | UI/action |
|---|---|
| Not yet determined / requestable | Request once from the active user action |
| Granted, sufficient scope | Continue the intended operation once |
| Denied but requestable | Inline explanation, alternative/cancel; retry on a later explicit action |
| Permanently denied / no further prompt possible | Explain, offer Open app settings; don't call request repeatedly |
| Restricted by OS/parent/management policy | Explain limitation; settings may not resolve it |
| Limited, provisional or approximate | Use granted scope when adequate; explain a specific upgrade only if needed |
| Service/hardware disabled or unavailable | Separate capability recovery; permission request won't enable hardware |
| User cancelled system flow | Preserve state and return control; cancellation is not an implementation error |

Plugin enums differ by permission/platform/version; don't assume every status exists for every
capability. `shouldShowRequestRationale == false` alone cannot distinguish first request from
blocked denial. Use documented current status/result, and request history only as UX context,
not as authority. Don't persist a boolean that substitutes for checking OS permission again.

## Check installed permission_handler semantics

Inspect both permission_handler and the resolved federated platform package in pubspec.lock.
Current upstream guidance for permission_handler_android 14.1.0+ says a passive status read
returns denied for denied runtime permissions; permanentlyDenied is distinguished by the
request result. Don't assume a status.isPermanentlyDenied precheck still detects every blocked
case after an upgrade. On an explicit user retry, request once and branch on the returned
status; the OS can resolve blocked requests without displaying another dialog. Do not request
on passive resume merely to classify status, or trust a cached blocked result forever after
Settings may have reset access. Preserve unknown/requestable denial until the next action.
Older plugin versions may differ; test the installed mapping on supported Android versions.
[Upstream Android status migration guide](https://github.com/Baseflow/flutter-permission-handler/blob/main/ANDROID_PERMANENTLY_DENIED_FIX_GUIDE.md).

## One owner for prompts and recovery

Platform adapters in data/core infrastructure read status, request, and open supported
settings. Feature Cubits expose typed capability outcomes; UI presents copy/dialogs and
initiates settings actions. Keep BuildContext out of services/Cubits and plugin types out of
domain contracts. Register the service only when used, via the existing DI conventions.

Use one request owner across consumers. Repeated taps for the same capability share the
active request; different permission prompts are serialized, not launched concurrently.
Disable the initiating action while awaiting it. An action ID prevents stale/late completion
from executing a newer action or navigating after disposal. Don't resume a cancelled purchase,
upload or check-in merely because its permission was later granted.

Separate passive checks from interactive ensure/request. A build(), stream subscriber or
resume refresh may check status, but must not implicitly prompt/open settings. Starting the
system prompt can itself cause inactive/resumed lifecycle transitions; keep its operation
pending so those events cannot start another prompt or duplicate the protected operation.

An arbitrary Future.timeout does not dismiss the native dialog. Don't release the prompt
lock and start a second dialog while the first is still visible. If a plugin hangs, expose
an actionable waiting/failure state, preserve ownership, and diagnose native logs/registration;
a timer alone cannot safely repair a broken OS request.

## Settings round trip

Open settings only after the user chooses a labeled action. Check whether the settings call
was supported/launched and provide a fallback if not. Its return value means the page opened,
not that permission changed. Offer app settings versus service-specific settings deliberately.

Record the pending capability/action and observe a genuine return to resumed. Re-read
permission AND service/feature availability once; coalesce duplicate lifecycle events and
active work. When nothing changed, keep the inline recovery state without reopening settings
or requesting permission. Resume only if the original screen/action is still relevant and
the operation is safe to continue; otherwise update availability and await another tap.

Permissions can change in Settings, expire, be auto-reset, or be one-time/session grants.
Check before protected use and handle revocation from the API too. Cold relaunch must recover
without relying on an in-memory settings marker. Dispose observers/subscriptions and pending
UI callbacks with their owner. Avoid one lifecycle observer in every tile/screen.

## Smooth presentation

Keep existing content visible where usable. A denial card explains the affected feature,
provides the correct action and an alternative (manual address, picker, browse without it).
Use localized/constants copy: Enable location services differs from Open app settings.
Offer cancel/later where the capability is optional. Don't keep a full-screen spinner behind
a permanent-denial state or show duplicate snackbar/dialog/inline errors for one outcome.
Make buttons/focus/semantics accessible, and restore the user's context after native UI closes.

## Platform setup and verification

Inspect merged Android manifests and the actual iOS target's usage descriptions, entitlements,
plugin build configuration and deployment targets. Add only what this feature needs. Missing
native declarations can crash or suppress prompts; an existing Dart request isn't proof of
correct setup. Check CocoaPods/SwiftPM permission_handler configuration for the installed
version rather than pasting every permission macro or usage key into every project.

Test grant, deny, blocked, restricted/limited where supported, cancel, unchanged Settings,
Settings grant/revoke, rapid repeated taps, prompt-induced resume, navigation away, cold
relaunch and unavailable hardware. Fakes prove coordinator decisions; native prompts require
an affected device/OS pass. Don't uninstall/reset real app data to simulate denial casually.
Report exact platform/version/target/plugin and remaining gaps. Never log sensitive capability
data (coordinates, contacts, health records, photo paths) as permission diagnostics.

Sources: [Android permission workflow](https://developer.android.com/training/permissions/requesting),
[permission_handler setup and statuses](https://pub.dev/packages/permission_handler).
