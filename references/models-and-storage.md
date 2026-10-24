# Models, JSON and Storage Boundaries

## Entities and wire models

Domain entities use Equatable with final fields and complete props; they have no Flutter,
plugin or transport dependencies. Define enum/value shapes beside the example when teaching
one. Match the actual domain: money/units/time use value-objects.md, not display-formatted
strings or arbitrary double arithmetic in entities.

Wire models use json_serializable and extend the entity by default, as shown in the runnable
feature templates. When inheritance would weaken domain invariants, keep a separate DTO and
map into a validated entity at the data boundary. Existing app conventions take priority;
Freezed models already adopted by a project aren't an unsolicited migration target.

Keep JSON parsing and toEntity mapping in data/models, never widgets. Generated files are
rebuilt with fdev gen (fallback: dart run build_runner build --delete-conflicting-outputs),
gitignored in the house scaffold and never hand-edited. Don't duplicate their generated logic
in presentation. Use explicitToJson for nested objects and deliberate JsonKey naming/defaults.
A default is appropriate only if omission really means that value; it must not conceal missing
required identity, authorization, monetary or eligibility data.

For documented backend drift, define fallback order in one parser and test accepted forms.
Reject malformed required records; unknown enum values need a deliberate fallback or failure.
Do not silently map unknown paid/authorized states to a permissive default. Keep timestamp,
nullability, numeric units and timezone rules explicit. Heavy parsing goes off the UI isolate
only after measuring a relevant cost and keeping parsing inputs/results transferable.

## Nullable updates must distinguish omission from clearing

Do not write copyWith(field: value ?? this.field) for a nullable field that callers must be
able to clear. Use the project's established generated copyWith/sentinel/update type, or an
explicit clear action. Don't add copyWith at all when unused. This small pure-Dart example
makes the semantics explicit without dynamic or an unsafe sentinel cast:

```dart
enum DeliveryStatus { pending, complete }

final class DeliveryUpdate {
  const DeliveryUpdate.keep() : changesStatus = false, status = null;
  const DeliveryUpdate.set(this.status) : changesStatus = true;

  final bool changesStatus;
  final DeliveryStatus? status;
}

final class Delivery {
  const Delivery({required this.id, this.status});

  final String id;
  final DeliveryStatus? status;

  Delivery apply(DeliveryUpdate update) => Delivery(
    id: id,
    status: update.changesStatus ? update.status : status,
  );
}
```

The example illustrates only nullable update behavior; production entities follow the app's
Equatable/value-object conventions. Test keep, set and clear explicitly when those operations
exist. Don't introduce this helper type into a feature that doesn't need nullable updates.

## Persistence selection and ownership

Choose the store by data semantics, not convenience:

| Data | Store/boundary |
|---|---|
| Theme/onboarding/non-sensitive small preferences | SharedPreferences behind LocalStorageService |
| Access/refresh tokens, private keys and other secrets | Dedicated secure session/key store backed by Keychain/Keystore |
| Structured/queryable/transactional data | Existing database/repository with schema/migration ownership |
| Large blobs/files/cache | Owned file/cache service with retention and cleanup policy |

The unauthenticated scaffold intentionally exposes no token keys in its preference service.
Do not reintroduce access/refresh token preferences when adding auth. A session store owns
secrets and their lifecycle; the user profile/cache is a separate sensitivity decision.
Use a safe minimal profile representation and avoid duplicating secrets in JSON caches.

All keys belong in a constants class or the owning store's private constants. Keep writes
observable: handle failed persistence/decoding and choose a usable fallback. Don't claim a
write succeeded when the underlying store failed. Repositories/services own storage access;
UI reads domain state and domain code never knows SharedPreferences or secure-storage APIs.

If an existing project caches writes in memory, keep one source of truth and define failure,
startup, isolate and invalidation behavior. Don't add another global cache to rescue a race.
New preference APIs, cache semantics and plugin minimums depend on the installed version;
inspect it before migrating. A setting from yesterday isn't current permission/session status.

Logout/session invalidation uses one cleanup path and prevents pending requests/refresh from
restoring old state. Preserve unrelated user preferences unless policy requires removal.
Avoid clearing the entire store to implement logout or recover one malformed key. Migrate
legacy insecure token storage deliberately and remove the old copies only with a tested
transition. Device backups, Keychain persistence and user/account changes need explicit policy.

## Verification

Test schema contracts, missing/invalid fields, enum drift, nullable clearing, persistence
failure, corrupt cache, migrations and logout isolation according to the change. Fakes verify
repository behavior; real plugin/device checks establish secure-store lifecycle. Never log
stored secrets or complete user records. Backup/restore integrity: data-export-and-restore.md.
