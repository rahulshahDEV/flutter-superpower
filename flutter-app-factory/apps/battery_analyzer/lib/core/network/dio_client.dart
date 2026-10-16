import 'package:dio/dio.dart';
import 'package:factory_networking/factory_networking.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:battery_analyzer/core/config/app_config.dart';
import 'package:battery_analyzer/core/constants/app_constants.dart';
import 'package:battery_analyzer/core/storage/local_storage_service.dart';
import 'package:battery_analyzer/core/utils/app_logger.dart';

class DioClient {
  DioClient(this._storage) {
    _dio = FactoryTransport(baseUrl: AppConfig.instance.baseUrl).dio;
    _dio.options = _baseOptions();
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _addAuthHeader));
    if (AppConfig.instance.isDev) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          error: true,
          compact: true,
          maxWidth: 120,
        ),
      );
    }
  }

  final LocalStorageService _storage;
  late final Dio _dio;

  BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: AppConfig.instance.baseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  void _addAuthHeader(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = _storage.getString(StorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    AppLogger.d('${options.method} ${options.path}', name: 'DioClient');
    handler.next(options);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) => _dio.post<T>(path, data: data, queryParameters: queryParameters);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      _dio.delete<T>(path, data: data);
}
