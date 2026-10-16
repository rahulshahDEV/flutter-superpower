import 'exceptions.dart';

class ApiResponseHandler {
  ApiResponseHandler._();

  static T handle<T>(
    Object? body, {
    required T Function(Map<String, dynamic> json) parser,
    required String missingMessage,
    required String invalidMessage,
  }) {
    if (body == null) throw ServerException(missingMessage);
    if (body is! Map<String, dynamic>) throw ServerException(invalidMessage);
    final Object? data = body.containsKey('data') ? body['data'] : body;
    if (data == null) throw ServerException(missingMessage);
    if (data is! Map<String, dynamic>) throw ServerException(invalidMessage);
    try {
      return parser(data);
    } catch (_) {
      throw ServerException(invalidMessage);
    }
  }
}
