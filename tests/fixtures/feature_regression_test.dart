import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:demo_app/core/error/api_exception_handler.dart';
import 'package:demo_app/core/error/exceptions.dart';
import 'package:demo_app/core/error/failures.dart';
import 'package:demo_app/core/config/app_config.dart';
import 'package:demo_app/core/network/dio_client.dart';
import 'package:demo_app/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:demo_app/features/orders/domain/entities/order.dart';
import 'package:demo_app/features/orders/presentation/cubit/orders/orders_state.dart';

class _FakeClient extends DioClient {
  Object? payload;
  DioException? failure;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final error = failure;
    if (error != null) throw error;
    return Response<T>(
      data: payload as T,
      requestOptions: RequestOptions(path: path),
    );
  }
}

class _Repository with ApiExceptionHandler {}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'BASE_URL=https://api.example.com');
    AppConfig.initialize(flavor: Flavor.dev, appName: 'Test');
  });

  test('emitted list snapshots input and prevents consumer mutation', () {
    final input = [const Order(id: '1', name: 'First')];
    final state = OrdersSuccess(input);
    input.clear();
    expect(state.items.single.id, '1');
    expect(() => state.items.clear(), throwsUnsupportedError);
  });

  test('malformed records fail instead of disappearing from results', () async {
    final client = _FakeClient()
      ..payload = {
        'data': [
          <String, dynamic>{'id': '1', 'name': 'First'},
          'malformed',
        ],
      };
    final source = OrdersRemoteDataSourceImpl(client);
    await expectLater(source.getOrders(), throwsA(isA<ServerException>()));
  });

  test('valid records survive strict parsing', () async {
    final client = _FakeClient()
      ..payload = {
        'data': [
          <String, dynamic>{'id': '1', 'name': 'First'},
        ],
      };
    final items = await OrdersRemoteDataSourceImpl(client).getOrders();
    expect(items.single.id, '1');
    expect(items.single.name, 'First');
  });

  test(
    'offline remains a network failure across the datasource boundary',
    () async {
      final client = _FakeClient()
        ..failure = DioException(
          requestOptions: RequestOptions(path: '/orders'),
          type: DioExceptionType.connectionError,
        );
      final source = OrdersRemoteDataSourceImpl(client);
      final result = await _Repository().safeApiCall(source.getOrders);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected a network failure'),
      );
    },
  );
}
