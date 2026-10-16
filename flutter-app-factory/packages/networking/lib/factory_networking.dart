import 'package:dio/dio.dart';

/// Credentials are injected by the application, never retained by shared config.
class FactoryTransport {
  FactoryTransport({required String baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
  final Dio dio;
}
