import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:__APP_NAME__/core/constants/error_constants.dart';
import 'package:__APP_NAME__/core/error/api_exception_handler.dart';
import 'package:__APP_NAME__/core/error/failures.dart';

class _Repository with ApiExceptionHandler {}

void main() {
  final repository = _Repository();

  Future<Failure> failureFor(Object error) async {
    final result = await repository.safeApiCall<void>(() async => throw error);
    return result.fold((failure) => failure, (_) => fail('Expected a failure'));
  }

  DioException responseError(int statusCode, {Object? body}) {
    final request = RequestOptions(path: '/items');
    return DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response<Object?>(
        requestOptions: request,
        statusCode: statusCode,
        data: body,
      ),
    );
  }

  test('unexpected exceptions never expose implementation details', () async {
    final failure = await failureFor(
      StateError('private implementation detail'),
    );
    expect(failure, const ServerFailure());
    expect(failure.message, ErrorConstants.serverError);
  });

  test(
    'connection failures keep the network category and safe message',
    () async {
      final failure = await failureFor(
        DioException(
          requestOptions: RequestOptions(path: '/items'),
          type: DioExceptionType.connectionError,
          message: 'private connection detail',
        ),
      );
      expect(failure, const NetworkFailure());
    },
  );

  test('401 remains unauthorized', () async {
    expect(await failureFor(responseError(401)), const UnauthorizedFailure());
  });

  test('422 retains the user-facing validation message', () async {
    final failure = await failureFor(
      responseError(422, body: {'message': 'Enter a valid quantity.'}),
    );
    expect(failure, const ValidationFailure('Enter a valid quantity.'));
  });

  test('404 remains not found', () async {
    expect(await failureFor(responseError(404)), const NotFoundFailure());
  });

  test('timeout uses safe network copy without Dio diagnostics', () async {
    expect(
      await failureFor(
        DioException(
          requestOptions: RequestOptions(path: '/items'),
          type: DioExceptionType.receiveTimeout,
          message: 'private timeout diagnostic',
        ),
      ),
      const NetworkFailure(),
    );
  });

  test('non-JSON server response never appears in the failure', () async {
    final failure = await failureFor(
      responseError(500, body: '<html>private server diagnostic</html>'),
    );
    expect(failure, const ServerFailure());
  });
}
