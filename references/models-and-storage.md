# Models, JSON, Storage

## Entities (domain)

Plain `Equatable`, all-final, `const` ctor, computed getters, `props`:

```dart
class Order extends Equatable {
  const Order({required this.id, required this.total, this.status});

  final String id;
  final double total;
  final OrderStatus? status;

  bool get isPaid => status == OrderStatus.paid;
  String get displayTotal => 'Rs. ${total.toStringAsFixed(0)}';

  @override
  List<Object?> get props => [id, total, status];
}
```

No `freezed` for entities/DTOs (reserved for cubit states). No plugins in domain.

## Wire models (data)

Models **extend** entities and add JSON + `copyWith`:

```dart
part 'order_model.g.dart';

@JsonSerializable()
class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.total,
    super.status,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => _$OrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  OrderModel copyWith({double? total, OrderStatus? status}) =>
      OrderModel(id: id, total: total ?? this.total, status: status ?? this.status);
}
```

Conventions:
- `@JsonSerializable(explicitToJson: true)` when nested; `@JsonKey(name: 'phoneNumber')` for renames; `@JsonKey(defaultValue: '')` for required-with-default.
- Enums: `@JsonEnum(valueField: 'apiValue')` or `@JsonKey(fromJson: _xFromJson, toJson: _xToJson)`.
- Request payloads: omit nulls with Dart 3 patterns, not manual maps:

```dart
Map<String, dynamic> toJson() => <String, dynamic>{
      if (email case final value?) 'email': value,
      if (phone case final value?) 'phone': value,
      'password': password,
    };
```

- Edge/hand-parsed endpoints: defensive helpers that trim and throw `FormatException`:

```dart
String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('Missing or invalid field: $key');
}
```

- Mappers live next to models (`toEntity()`, `toCurrentUserProfile()`); never in widgets.
- Heavy parsing (>~10ms) moves to a pure top-level function run via `compute()`.
- Generated `.g.dart`/`.freezed.dart`: gitignored, regenerated with
  `dart run build_runner build --delete-conflicting-outputs`. Never edit by hand.

## Storage

**SharedPreferences behind a service — never call `SharedPreferences` in features.**

```dart
// core/storage/local_storage_service.dart
@lazySingleton
class LocalStorageService {
  LocalStorageService(this._prefs);
  final SharedPreferences _prefs;

  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  bool? getBool(String key) => _prefs.getBool(key);
  // int/double/StringList/containsKey/remove/clear/keys
}

class StorageKeys {
  StorageKeys._();
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String currentUser = 'current_user';
  static const String fcmToken = 'fcm_token';
  static const String themeMode = 'theme_mode';
  static const String hasCompletedOnboarding = 'has_completed_onboarding';
}
```

Variant: a `CacheHelper` (async prefs writes) mirrors every write into an in-memory
`Cache.instance` singleton for synchronous reads in widgets. Adopt only if sync reads are
genuinely needed.

Rules:
- All keys in `StorageKeys` (or `_privateKey` constants inside the helper).
- Session persistence lives in a feature service (`AuthSessionStore`): tokens + `jsonEncode(user)` under `current_user`; decode with try/catch + safe default.
- Secrets (crypto keys, device identity) → `flutter_secure_storage`, never SharedPreferences.
- Logout clears storage through one `UserSessionCleanupService`/`logout()` path.
- Repositories/services own storage access; domain never touches it.
