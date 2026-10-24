# Routing and Navigation Ownership

Use one GoRouter/AppRouter per app. The existing core/router directory is an application
composition boundary allowed to import screens; other core services remain feature-independent.
Existing apps using app/router keep that layout. Follow the runnable AppRouter template.

## Route structure

Screens own static path and routeName constants; call sites reference those values.
Split large route sets into focused builders in the composition directory. Keep business
rules, HTTP operations and mutable feature state out of route declarations.

The minimal scaffold starts at home with no timed splash. Add a startup coordinator only
when session/onboarding restoration must determine the first destination. Represent pending
startup explicitly, preserve intended deep links, and never flash protected content while
session state is unresolved. A splash renders branding/state; it does not navigate on a timer.

## Argument contract

| Input | Location | Behavior |
|---|---|---|
| Stable resource ID | Encoded path segment | Cold-linkable; flow fetches authoritative data by ID |
| Shareable filter/sort/search | Query parameters | Parse, validate and supply defaults |
| Optional already-loaded preview | Typed state.extra route-data | Acceleration only; absent after reload must still work |
| Transient workflow payload | Typed state.extra with fromExtra | Explicit unavailable/recovery route if absent |

Use Uri.encodeComponent for a dynamic segment rather than interpolating arbitrary IDs.
For query state, build a Uri with queryParameters instead of manual string concatenation.
Don't double-decode route parameters or embed credentials in URLs. Reject malformed or
unsupported inputs at the router boundary. Parse once, pass validated input to the provider,
and let its Cubit fetch. Do not cast extra with `as` and hope it is present.

An invalid link renders a deliberate not-found/unavailable state or redirects to a canonical
safe URL. Don't display an unrelated home screen under the invalid resource URL. Unknown
resources and malformed IDs can need different recovery/copy. Use localized/constants copy.

## Typed transient data example

This isolated example shows the shape of a preview and its parser. Use the app's existing
domain entity where appropriate; a preview isn't a substitute for authorization or ID lookup.

```dart
typedef ItemPreview = ({String id, String title});

final class DetailRouteData {
  const DetailRouteData({required this.preview, this.fromSearch = false});

  final ItemPreview preview;
  final bool fromSearch;

  static DetailRouteData? fromExtra(Object? extra) {
    if (extra is! DetailRouteData || extra.preview.id.trim().isEmpty) return null;
    return extra;
  }
}
```

The path ID remains authoritative. Ignore a preview whose ID doesn't match it. If a transient
edit flow genuinely requires extras, handle missing extras without a crash; never silently
save stale preview data over newer server data.

## Provider lifetime and navigation

Choose screen-owned OR wrapper-owned BlocProvider creation per `state-and-di.md`; never
nest both for the same Cubit. A route wrapper receives parsed arguments, initializes one
factory Cubit, and builds a provider-free view. UI triggers navigation from callbacks/listeners;
Cubits and clients expose outcomes/session state without importing a router or screen.

Navigation helpers belong in core/extensions/context_extensions.dart:

```dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension ContextNavigation on BuildContext {
  void goTo(String path, {Object? extra}) => go(path, extra: extra);
  void goReplace(String path, {Object? extra}) => replace(path, extra: extra);
  Future<T?> pushRoute<T>(String path, {Object? extra}) => push<T>(path, extra: extra);
  void popRoute<T extends Object?>([T? result]) => pop(result);
}
```

Use context.goTo/pushRoute/popRoute/goReplace instead of raw navigation calls. Dialogs and
sheets may use showDialog/showModalBottomSheet. Cross-feature navigation helpers can live in
presentation/utils/<flow>_navigation.dart; avoid importing another feature's widgets everywhere.

## Guards and authentication

Guards observe one authoritative session state and refresh routing when it changes. Keep
redirects deterministic and bounded; don't issue network requests on every redirect or mutate
a selected tab from redirects. Whitelist auth paths and preserve the intended destination
through sign-in without allowing arbitrary external redirect URLs. Compare route boundaries,
not naive startsWith checks that accidentally protect unrelated prefixes.

Handle pending session, signed out, signed in and domain restrictions deliberately. Token
presence alone does not prove a valid session. HTTP/session infrastructure invalidates the
session; routing responds at the composition boundary. Avoid competing navigation from the
client, Cubit, and UI listener for the same auth failure.

## Tabs, deep links and notification taps

For independent tab histories, use StatefulShellRoute.indexedStack with separate navigator
keys; retain branch selection/stack and define reselect behavior. A simple local IndexedStack
is adequate when independent route stacks aren't required, but its tab routes must have
coherent URLs/back behavior. Test system back, browser history where supported, and root
versus branch navigator placement for full-screen overlays.

Validate notification payloads, queue cold-start destinations until session/router readiness,
and consume each intended navigation once. Ignore unknown payloads safely. Native URL/app-link
registration and Dart route parsing must agree. Never execute a destructive action just by
opening an untrusted link.

## Verification

Test direct navigation, cold deep link, missing extras/reload, malformed IDs, unknown resource,
sign-in redirect/return, repeated session changes, and back/tab restoration according to the
change. Check native app links/notifications on affected devices; a router unit test cannot
prove OS registration. Record which paths and environments were actually exercised.
