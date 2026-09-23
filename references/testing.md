# Testing (house style)

`flutter_test` only. **No mocktail, no mockito.** Hand-written fakes, plain `expect`,
paths mirror `lib/`.

## What gets a test

| Always | Sometimes | Never |
|---|---|---|
| Cubit state transitions (loading → success/failure) | Parser edge cases | Getters/`displayX` one-liners |
| Defensive `fromJson` / validators | Critical widget flow (login form, checkout) | Pure layout |
| Error mapping (`safeApiCall` branches) | Pagination logic | Generated code |

Rule: one runnable check per non-trivial logic path. Trivial code gets none.

## Fakes

```dart
class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository({this.result});

  FutureEither<List<Order>>? result;

  @override
  FutureEither<List<Order>> getOrders({required int page}) async =>
      result ?? Right([const Order(id: '1', total: 100)]);

  @override
  FutureEither<Order> getOrder(String id) => throw UnimplementedError();
}
```

Top-level factory helpers for entities keep tests short:

```dart
Order buildOrder({String id = '1', double total = 100}) =>
    Order(id: id, total: total);
```

## Cubit test

```dart
void main() {
  group('OrdersCubit', () {
    test('emits loading then success', () async {
      final cubit = OrdersCubit(FakeOrdersRepository());
      addTearDown(cubit.close);

      expect(cubit.state, isA<OrdersInitial>());
      final future = cubit.load();
      expect(cubit.state, isA<OrdersLoading>());
      await future;

      expect(cubit.state, isA<OrdersSuccess>());
      expect((cubit.state as OrdersSuccess).orders, hasLength(1));
    });

    test('emits failure when repository fails', () async {
      final cubit = OrdersCubit(FakeOrdersRepository(result: Left(ServerFailure('boom'))));
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state, isA<OrdersFailure>());
    });
  });
}
```

## Model / parser test

```dart
test('OrderModel.fromJson reads snake_case and throws on missing id', () {
  final model = OrderModel.fromJson({'id': 'a1', 'total_amount': 50});
  expect(model.total, 50);

  expect(() => OrderModel.fromJson({'total_amount': 50}), throwsFormatException);
});
```

## Widget test

```dart
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows empty state when no orders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => OrdersCubit(FakeOrdersRepository(result: Right(const []))),
          child: const OrdersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyStateWidget), findsOneWidget);
  });
}
```

Notes:
- `SharedPreferences.setMockInitialValues({})` before anything touching storage.
- Guard Firebase-dependent widgets with `if (Firebase.apps.isEmpty)` in app code (already house style).
- Prefer asserting on state/visible widgets over internal calls.
- Golden tests: only for a stable design-system widget, and only if the team asks.

## Layout

```
test/
├── core/
│   ├── error/api_exception_handler_test.dart
│   └── utils/input_validators_test.dart
└── features/orders/
    ├── data/models/order_model_test.dart
    └── presentation/cubit/orders_cubit_test.dart
```

## Commands

```bash
flutter test                          # all
flutter test test/features/orders     # one folder
flutter test --coverage               # coverage/lcov.info
flutter analyze                       # before tests, always
```

## Anti-patterns

| Smell | Fix |
|---|---|
| `mockito`/`mocktail` dependency | hand-written fake (above) |
| Testing private methods via `@visibleForTesting` sprawl | test through the public cubit/repo API |
| `await Future.delayed` in tests | `await cubit.load()` or `pumpAndSettle` |
| One giant test file per app | mirror `lib/` paths |
| Asserting exact widget tree | assert the state + user-visible outcome |
| No `addTearDown(cubit.close)` | leaks open cubits across tests |
