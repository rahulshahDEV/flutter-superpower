import 'package:dio/dio.dart';

import 'package:__APP_NAME__/core/config/app_config.dart';
import 'package:__APP_NAME__/core/constants/app_constants.dart';

class DioClient {
  DioClient() : _dio = Dio(_baseOptions());

  final Dio _dio;

  static BaseOptions _baseOptions() {
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
