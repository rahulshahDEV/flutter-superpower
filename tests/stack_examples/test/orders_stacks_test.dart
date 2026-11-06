import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:state_stack_examples/features/orders/domain/orders_repository.dart';
import 'package:state_stack_examples/features/orders/presentation/controllers/orders_controller.dart';
import 'package:state_stack_examples/features/orders/presentation/orders_state.dart';
import 'package:state_stack_examples/features/orders/presentation/pages/orders_routes.dart';

final class PendingRead {
  PendingRead(this.accountId);
  final String accountId;
  final result = Completer<OrdersResult>();
}

final class ControlledOrdersRepository implements OrdersRepository {
  final reads = <PendingRead>[];

  @override
  Future<OrdersResult> fetch(String accountId) {
    final read = PendingRead(accountId);
    reads.add(read);
    return read.result.future;
  }
}

typedef RouteBuilder =
    Widget Function(
      OrdersRepository repository,
      String accountId,
      String identity,
    );

final stacks = <String, RouteBuilder>{
  'Riverpod': (repository, accountId, identity) => RiverpodOrdersRoute(
    key: ValueKey(identity),
    repository: repository,
    accountId: accountId,
  ),
  'Provider': (repository, accountId, identity) => ProviderOrdersRoute(
    key: ValueKey(identity),
    repository: repository,
    accountId: accountId,
  ),
  'GetX': (repository, accountId, identity) => GetOrdersRoute(
    key: ValueKey(identity),
    repository: repository,
    accountId: accountId,
    tag: identity,
  ),
  'Bloc': (repository, accountId, identity) => BlocOrdersRoute(
    key: ValueKey(identity),
    repository: repository,
    accountId: accountId,
  ),
};

Widget app(Widget route) => MaterialApp(home: Scaffold(body: route));
OrdersSuccess orders(String id) => OrdersSuccess([Order(id)]);

Future<void> flush(WidgetTester tester) async {
  // Loading is static text, so only bounded button/notification frames can remain.
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 1),
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() {
    Get.reset();
    Get.testMode = false;
  });

  test('state snapshots isolate caller mutations', () {
    final input = [const Order('one')];
    final state = OrdersState(status: OrdersStatus.loaded, items: input);
    input.clear();
    expect(state.items.single.id, 'one');
    expect(() => state.items.clear(), throwsUnsupportedError);
  });

  for (final entry in stacks.entries) {
    final route = entry.value;
    group(entry.key, () {
      testWidgets('initial loading then empty success, one fetch per mount', (
        tester,
      ) async {
        final repository = ControlledOrdersRepository();
        await tester.pumpWidget(app(route(repository, 'account-a', 'first')));
        await flush(tester);
        expect(find.text('Loading'), findsOneWidget);
        expect(repository.reads, hasLength(1));
        expect(repository.reads.single.accountId, 'account-a');
        repository.reads.single.result.complete(OrdersSuccess([]));
        await flush(tester);
        expect(find.text('Loading'), findsNothing);
        expect(find.text('No orders'), findsOneWidget);
        await flush(tester);
        expect(repository.reads, hasLength(1));
      });

      testWidgets('failure then user retry renders content', (tester) async {
        final repository = ControlledOrdersRepository();
        await tester.pumpWidget(app(route(repository, 'account-a', 'first')));
        await flush(tester);
        repository.reads[0].result.complete(const OrdersFailure('Offline'));
        await flush(tester);
        expect(find.text('Offline'), findsOneWidget);
        expect(find.text('No orders'), findsNothing);
        await tester.tap(find.text('Retry'));
        await flush(tester);
        repository.reads[1].result.complete(orders('order-1'));
        await flush(tester);
        expect(find.text('order-1'), findsOneWidget);
        expect(find.text('Offline'), findsNothing);
      });

      testWidgets('refresh failure retains usable content', (tester) async {
        final repository = ControlledOrdersRepository();
        await tester.pumpWidget(app(route(repository, 'account-a', 'first')));
        await flush(tester);
        repository.reads[0].result.complete(orders('kept-order'));
        await flush(tester);
        await tester.tap(find.text('Retry'));
        await flush(tester);
        expect(find.text('kept-order'), findsOneWidget);
        expect(find.text('Loading'), findsOneWidget);
        repository.reads[1].result.complete(
          const OrdersFailure('Refresh failed'),
        );
        await flush(tester);
        expect(find.text('kept-order'), findsOneWidget);
        expect(find.text('Refresh failed'), findsOneWidget);
        expect(find.text('Loading'), findsNothing);
      });

      testWidgets('latest read wins over stale success and stale failure', (
        tester,
      ) async {
        final repository = ControlledOrdersRepository();
        await tester.pumpWidget(app(route(repository, 'account-a', 'first')));
        await flush(tester);
        await tester.tap(find.text('Retry'));
        await flush(tester);
        repository.reads[1].result.complete(orders('new-order'));
        await flush(tester);
        repository.reads[0].result.complete(orders('stale-order'));
        await flush(tester);
        expect(find.text('new-order'), findsOneWidget);
        expect(find.text('stale-order'), findsNothing);
        await tester.tap(find.text('Retry'));
        await flush(tester);
        await tester.tap(find.text('Retry'));
        await flush(tester);
        repository.reads[3].result.complete(orders('newest-order'));
        await flush(tester);
        repository.reads[2].result.complete(
          const OrdersFailure('Stale failure'),
        );
        await flush(tester);
        expect(find.text('newest-order'), findsOneWidget);
        expect(find.text('Stale failure'), findsNothing);
      });

      testWidgets('exit during load, reopen and reject disposed completion', (
        tester,
      ) async {
        final repository = ControlledOrdersRepository();
        await tester.pumpWidget(app(route(repository, 'account-a', 'first')));
        await flush(tester);
        await tester.pumpWidget(app(const SizedBox()));
        await flush(tester);
        if (entry.key == 'GetX') {
          expect(Get.isRegistered<OrdersController>(tag: 'first'), isFalse);
        }
        repository.reads[0].result.complete(orders('disposed-order'));
        await flush(tester);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(app(route(repository, 'account-a', 'second')));
        await flush(tester);
        expect(repository.reads, hasLength(2));
        expect(find.text('disposed-order'), findsNothing);
        repository.reads[1].result.complete(orders('reopened-order'));
        await flush(tester);
        expect(find.text('reopened-order'), findsOneWidget);
      });

      testWidgets('two simultaneous routes isolate account state', (
        tester,
      ) async {
        final repository = ControlledOrdersRepository();
        await tester.pumpWidget(
          app(
            Column(
              children: [
                route(repository, 'account-a', 'first'),
                route(repository, 'account-b', 'second'),
              ],
            ),
          ),
        );
        await flush(tester);
        expect(repository.reads.map((read) => read.accountId), [
          'account-a',
          'account-b',
        ]);
        repository.reads[0].result.complete(orders('a-order'));
        repository.reads[1].result.complete(orders('b-order'));
        await flush(tester);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('first')),
            matching: find.text('a-order'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('first')),
            matching: find.text('b-order'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('second')),
            matching: find.text('b-order'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('same route key switches account without stale data', (
        tester,
      ) async {
        final repository = ControlledOrdersRepository();
        await tester.pumpWidget(app(route(repository, 'account-a', 'stable')));
        await flush(tester);
        await tester.pumpWidget(app(route(repository, 'account-b', 'stable')));
        await flush(tester);
        expect(repository.reads, hasLength(2));
        repository.reads[1].result.complete(orders('b-order'));
        await flush(tester);
        repository.reads[0].result.complete(orders('a-order'));
        await flush(tester);
        expect(find.text('b-order'), findsOneWidget);
        expect(find.text('a-order'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('same route key replaces repository without stale data', (
        tester,
      ) async {
        final oldRepository = ControlledOrdersRepository();
        final newRepository = ControlledOrdersRepository();
        await tester.pumpWidget(
          app(route(oldRepository, 'account-a', 'stable')),
        );
        await flush(tester);
        await tester.pumpWidget(
          app(route(newRepository, 'account-a', 'stable')),
        );
        await flush(tester);
        expect(newRepository.reads, hasLength(1));
        newRepository.reads[0].result.complete(orders('new-source-order'));
        await flush(tester);
        oldRepository.reads[0].result.complete(orders('old-source-order'));
        await flush(tester);
        expect(find.text('new-source-order'), findsOneWidget);
        expect(find.text('old-source-order'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'account switch recreates ownership and ignores old account',
        (tester) async {
          final repository = ControlledOrdersRepository();
          await tester.pumpWidget(
            app(route(repository, 'account-a', 'account-a')),
          );
          await flush(tester);
          await tester.pumpWidget(
            app(route(repository, 'account-b', 'account-b')),
          );
          await flush(tester);
          repository.reads[1].result.complete(orders('b-order'));
          await flush(tester);
          repository.reads[0].result.complete(orders('a-order'));
          await flush(tester);
          expect(find.text('b-order'), findsOneWidget);
          expect(find.text('a-order'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    });
  }
}
