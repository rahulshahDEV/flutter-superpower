# Networking & Error Handling

## Layers

```
UI (BlocListener shows failure.message)
  ↑
Cubit .fold(failure, success)
  ↑
Repository  → safeApiCall / errorHandler  → FutureEither<T> = Either<Failure, T>
  ↑
Data source → throws ServerException / NetworkException / UnauthorizedException ...
  ↑
DioClient (interceptors: auth header, token refresh, logging)
```

- Data sources **throw** typed exceptions. They never return `Either`.
- Repositories **never throw**; they wrap with `safeApiCall` and map model→entity.
- Cubits fold into state variants. Screens only read state.

## DioClient

```dart
// core/network/dio_client.dart
@lazySingleton
class DioClient {
  DioClient(this._storage) {
    _dio = Dio(_baseOptions());
    _refreshDio = Dio(_baseOptions());
    _dio.interceptors.addAll([
      QueuedInterceptorsWrapper(
        onRequest: _addAuthHeader,
        onError: _handleAuthError,
      ),
      if (AppConfig.instance.isDev)
        PrettyDioLogger(requestBody: true, responseBody: true, error: true, compact: true),
    ]);
  }

  late final Dio _dio;
  late final Dio _refreshDio;
  Future<void>? _activeRefreshRequest; // single-flight guard

  BaseOptions _baseOptions() => BaseOptions(
        baseUrl: AppConfig.instance.baseUrl,
        connectTimeout: AppConstants.connectionTimeout, // 30s
        receiveTimeout: AppConstants.receiveTimeout,
        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get<T>(path, queryParameters: queryParameters);
  // post / put / patch / delete wrappers likewise
}
```

Interceptor duties:
- **Request**: inject `Authorization: Bearer <accessToken>` from `LocalStorageService` unless already present.
- **401** on non-auth paths → single-flight `POST /auth/refresh` with `x-refresh-token`, persist new tokens, retry original once (`extra['auth_retry'] = true`).
- **403 account inactive / refresh failure** → single-flight force logout: clear session service, `getIt<AppRouter>().router.go(SignInScreen.path)`.
- Connectivity errors → trigger `ConnectivityWrapper.triggerCheck()`.

Never construct a bare `Dio()` in a feature. Uploads use `PresignedUploadClient`
(raw client bypassing auth interceptors for S3/CDN `PUT`/`POST` with progress callbacks).

## Envelope parsing

Backends wrap payloads (`{data, meta}`). Data sources parse via a handler that turns any
shape/type error into a `ServerException` with a human message:

```dart
final response = await _dioClient.get<Map<String, dynamic>>(
  ApiConstants.orders,
  queryParameters: {'page': page, 'limit': AppConstants.pageSize},
);

final data = ApiResponseHandler.handle(
  response.data,
  parser: (json) => OrderListModel.fromJson(json),
  missingMessage: ErrorConstants.missingOrdersResponse,
  invalidMessage: ErrorConstants.invalidResponseData,
);
```

Prefer generated `fromJson` when the backend is reliable; use defensive manual
`_readString` helpers (trim + `FormatException` on missing) for hand-parsed endpoints.

## Failures & exceptions

```dart
// core/error/exceptions.dart
class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode, this.errorCode});
  final String message;
  final int? statusCode;
  final String? errorCode;
  @override
  String toString() => 'ServerException($statusCode): $message';
}
// + CacheException, NetworkException, UnauthorizedException, ValidationException

// core/error/failures.dart
abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
final class ServerFailure extends Failure { const ServerFailure(super.message); }
final class NetworkFailure extends Failure { const NetworkFailure([super.message = ErrorConstants.noInternetConnection]); }
final class UnauthorizedFailure extends Failure { ... }
final class ValidationFailure extends Failure { ... }
final class NotFoundFailure extends Failure { ... }
```

Special-cased failures (account suspended, underage) carry extra payload for dialogs/redirects.

## safeApiCall

```dart
// core/error/api_exception_handler.dart
mixin ApiExceptionHandler {
  FutureEither<T> safeApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return Right(await apiCall());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on DioException catch (e) {
      return Left(_handleDioException(e)); // 400/422 validation, 401 unauthorized,
                                           // 403 forbidden, 404 not found, else server
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

`_handleDioException` extracts the backend `message` (from `{message}` or `{data:{message}}`)
then falls back to an `ApiErrorMessages` code→string map, then to the status message.

Meltdown variant funnels everything through `ErrorHandler.errorHandler(future)` which also
calls `Sentry.captureException` for unknown errors and force-logs-out on `UnauthenticatedException`.

## Use case contract

```dart
// core/usecases/usecase.dart
abstract class UseCase<Type, Params> {
  FutureEither<Type> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => const [];
}
```

One class per file in `domain/usecases/`, `@lazySingleton`, one-line body delegating to the repo.

## Showing errors

- UI: `AppSnackBar.showError(context, failure.message)` (zoomies) /
  `CustomSnackBar.showError(context, message: ...)` (foundyou) / `showErrorInfo(context, msg)` (meltdown).
- Never show raw exception text; failures already carry user-safe messages.
- Retry affordances: `ErrorStateWidget(onRetry: () => cubit.load())`.
- Logging: `AppLogger.d/i/w/e(message, name: 'ClassName', error: e, stackTrace: st)` —
  dev-only, ANSI-colored, wraps `dart:developer log`. Never `print()`.
- Best-effort non-critical work (syncs on resume, token registration) wraps in
  `try { ... } on Object { /* best-effort */ }` so it can never crash startup.
