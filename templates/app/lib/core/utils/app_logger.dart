import 'dart:developer' as developer;

import 'package:__APP_NAME__/core/config/app_config.dart';

abstract final class AppLogger {
  static bool get _enabled => AppConfig.isInitialized && AppConfig.instance.isDev;

  static void d(String message, {String name = '__APP_TITLE__'}) =>
      _log('🐛', message, name: name);

  static void i(String message, {String name = '__APP_TITLE__'}) =>
      _log('ℹ️', message, name: name);

  static void w(String message, {String name = '__APP_TITLE__'}) =>
      _log('⚠️', message, name: name);

  static void e(
    String message, {
    String name = '__APP_TITLE__',
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log('❌', message, name: name, error: error, stackTrace: stackTrace);

  static void _log(
    String emoji,
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;
    developer.log(
      '$emoji $message',
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
