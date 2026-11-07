// Parent-held checks: copy into each completed case-43 app after the implementation run.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stack_eval/features/orders/domain/orders_repository.dart';
import 'package:stack_eval/features/orders/presentation/pages/orders_route.dart';

final class Request {
  Request(this.accountId);
  final String accountId;
  final result = Completer<OrdersResult>();
}

final class FakeOrdersRepository implements OrdersRepository {
  final requests = <Request>[];

  @override
  Future<OrdersResult> fetch(String accountId) {
    final request = Request(accountId);
    requests.add(request);
    return request.result.future;
  }
}

Widget surface(FakeOrdersRepository repository, {String account = 'a'}) =>
    MaterialApp(
      home: Scaffold(
        body: OrdersRoute(
          key: const ValueKey('stable-route'),
          repository: repository,
          accountId: account,
        ),
      ),
    );

Future<void> flush(WidgetTester tester) => tester.pumpAndSettle();
OrdersSuccess success(String id) => OrdersSuccess([Order(id)]);

void main() {
  testWidgets('one fetch per mount; empty is successful content', (
    tester,
  ) async {
    final repository = FakeOrdersRepository();
    await tester.pumpWidget(surface(repository));
    await tester.pump();
    expect(find.text('Loading'), findsOneWidget);
    expect(repository.requests, hasLength(1));
    await tester.pumpWidget(surface(repository));
    await tester.pump();
    expect(repository.requests, hasLength(1));
    repository.requests.single.result.complete(OrdersSuccess([]));
    await flush(tester);
    expect(find.text('No orders'), findsOneWidget);
    expect(find.text('Loading'), findsNothing);
  });

  testWidgets('failure retries through the borrowed repository', (
    tester,
  ) async {
    final repository = FakeOrdersRepository();
    await tester.pumpWidget(surface(repository));
    await tester.pump();
    repository.requests[0].result.complete(const OrdersFailure('Offline'));
    await flush(tester);
    expect(find.text('Offline'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.requests, hasLength(2));
    repository.requests[1].result.complete(success('recovered'));
    await flush(tester);
    expect(find.text('recovered'), findsOneWidget);
    expect(find.text('Offline'), findsNothing);
  });

  testWidgets('failed refresh preserves useful content', (tester) async {
    final repository = FakeOrdersRepository();
    await tester.pumpWidget(surface(repository));
    await tester.pump();
    repository.requests[0].result.complete(success('kept'));
    await flush(tester);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('kept'), findsOneWidget);
    repository.requests[1].result.complete(
      const OrdersFailure('Refresh failed'),
    );
    await flush(tester);
    expect(find.text('kept'), findsOneWidget);
    expect(find.text('Refresh failed'), findsOneWidget);
  });

  testWidgets('newer result survives stale success and failure', (
    tester,
  ) async {
    final repository = FakeOrdersRepository();
    await tester.pumpWidget(surface(repository));
    await tester.pump();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    repository.requests[1].result.complete(success('new'));
    await flush(tester);
    repository.requests[0].result.complete(success('old'));
    await flush(tester);
    expect(find.text('new'), findsOneWidget);
    expect(find.text('old'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.requests, hasLength(4));
    repository.requests[3].result.complete(success('newest'));
    await flush(tester);
    repository.requests[2].result.complete(
      const OrdersFailure('Stale failure'),
    );
    await flush(tester);
    expect(find.text('newest'), findsOneWidget);
    expect(find.text('Stale failure'), findsNothing);
  });

  testWidgets('same-key account change resets and rejects prior completion', (
    tester,
  ) async {
    final repository = FakeOrdersRepository();
    await tester.pumpWidget(surface(repository));
    await tester.pump();
    await tester.pumpWidget(surface(repository, account: 'b'));
    await tester.pump();
    expect(repository.requests.map((r) => r.accountId), ['a', 'b']);
    repository.requests[1].result.complete(success('b-data'));
    await flush(tester);
    repository.requests[0].result.complete(success('a-data'));
    await flush(tester);
    expect(find.text('b-data'), findsOneWidget);
    expect(find.text('a-data'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-key repository replacement has a fresh owner', (
    tester,
  ) async {
    final old = FakeOrdersRepository();
    final replacement = FakeOrdersRepository();
    await tester.pumpWidget(surface(old));
    await tester.pump();
    await tester.pumpWidget(surface(replacement));
    await tester.pump();
    expect(replacement.requests, hasLength(1));
    replacement.requests.single.result.complete(success('replacement'));
    await flush(tester);
    old.requests.single.result.complete(success('old-repository'));
    await flush(tester);
    expect(find.text('replacement'), findsOneWidget);
    expect(find.text('old-repository'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving during load and reopening starts fresh', (tester) async {
    final repository = FakeOrdersRepository();
    await tester.pumpWidget(surface(repository));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    repository.requests[0].result.complete(success('disposed'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(surface(repository));
    await tester.pump();
    expect(repository.requests, hasLength(2));
    repository.requests[1].result.complete(success('reopened'));
    await flush(tester);
    expect(find.text('reopened'), findsOneWidget);
    expect(find.text('disposed'), findsNothing);
  });

  testWidgets('simultaneous routes keep their account data independent', (
    tester,
  ) async {
    final repository = FakeOrdersRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: OrdersRoute(
                  key: const ValueKey('first'),
                  repository: repository,
                  accountId: 'a',
                ),
              ),
              Expanded(
                child: OrdersRoute(
                  key: const ValueKey('second'),
                  repository: repository,
                  accountId: 'b',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(repository.requests.map((r) => r.accountId), ['a', 'b']);
    repository.requests[0].result.complete(success('a-only'));
    repository.requests[1].result.complete(success('b-only'));
    await flush(tester);
    for (final pair in [('first', 'a-only'), ('second', 'b-only')]) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey(pair.$1)),
          matching: find.text(pair.$2),
        ),
        findsOneWidget,
      );
    }
  });
}
