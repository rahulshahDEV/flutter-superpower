import 'dart:async';

import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:flutter_test/flutter_test.dart';

import 'package:eval_app/core/error/failures.dart';
import 'package:eval_app/features/orders/domain/entities/order.dart';
import 'package:eval_app/features/orders/domain/repositories/orders_repository.dart';
import 'package:eval_app/features/orders/domain/usecases/get_orders.dart';
import 'package:eval_app/features/orders/presentation/cubit/orders/orders_cubit.dart';
import 'package:eval_app/features/orders/presentation/cubit/orders/orders_state.dart';

final class ControlledRepository implements OrdersRepository {
  final calls = <Completer<Either<Failure, List<Order>>>>[];

  @override
  Future<Either<Failure, List<Order>>> getOrders() {
    final next = Completer<Either<Failure, List<Order>>>();
    calls.add(next);
    return next.future;
  }
}

void main() {
  for (final staleFails in [false, true]) {
    test(
      'latest owns loading and content; stale failure=$staleFails',
      () async {
        final repository = ControlledRepository();
        final cubit = OrdersCubit(GetOrders(repository));
        addTearDown(cubit.close);
        final old = cubit.load();
        final latest = cubit.load();
        repository.calls[0].complete(
          staleFails
              ? const Left(ServerFailure('Old failure'))
              : const Right([Order(id: 'old', name: 'Old')]),
        );
        await old;
        expect(cubit.state, isA<OrdersLoading>());
        repository.calls[1].complete(
          const Right([Order(id: 'new', name: 'New')]),
        );
        await latest;
        expect(cubit.state, isA<OrdersSuccess>());
        expect((cubit.state as OrdersSuccess).items.single.id, 'new');
      },
    );

    test(
      'latest failure survives stale completion; stale failure=$staleFails',
      () async {
        final repository = ControlledRepository();
        final cubit = OrdersCubit(GetOrders(repository));
        addTearDown(cubit.close);
        final old = cubit.load();
        final latest = cubit.load();
        repository.calls[1].complete(
          const Left(ServerFailure('Latest failure')),
        );
        await latest;
        repository.calls[0].complete(
          staleFails
              ? const Left(ServerFailure('Old failure'))
              : const Right([Order(id: 'old', name: 'Old')]),
        );
        await old;
        expect(
          cubit.state,
          const OrdersFailure(ServerFailure('Latest failure')),
        );
      },
    );
  }
}
