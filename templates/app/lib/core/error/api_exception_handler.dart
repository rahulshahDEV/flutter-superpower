import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:__APP_NAME__/core/error/either_extensions.dart';
import 'package:__APP_NAME__/core/error/exceptions.dart';
import 'package:__APP_NAME__/core/error/failures.dart';

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
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _handleDioException(DioException error) {
    final message = _messageFrom(error);
    return switch (error.response?.statusCode) {
      400 || 422 => ValidationFailure(message),
      401 => UnauthorizedFailure(message),
      404 => NotFoundFailure(message),
      _ => switch (error.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.connectionError =>
            NetworkFailure(message),
          _ => ServerFailure(message),
        },
    };
  }

  String _messageFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      final nested = data['data'];
      if (nested is Map<String, dynamic>) {
        final nestedMessage = nested['message'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage;
        }
      }
    }
    if (error.type == DioExceptionType.connectionError) {
      return const NetworkFailure().message;
    }
    return const ServerFailure().message;
  }
}
