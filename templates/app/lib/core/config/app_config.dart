import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Flavor { dev, prod }

class AppConfig {
  AppConfig._({required this.flavor, required this.baseUrl, required this.appName});

  static AppConfig? _instance;

  static AppConfig get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError('AppConfig.initialize() must run before use');
    }
    return instance;
  }

  static bool get isInitialized => _instance != null;

  static void initialize({required Flavor flavor, required String appName}) {
    _instance = AppConfig._(
      flavor: flavor,
      baseUrl: dotenv.env['BASE_URL'] ?? '',
      appName: appName,
    );
  }

  final Flavor flavor;
  final String baseUrl;
  final String appName;

  bool get isDev => flavor == Flavor.dev;
  bool get isProd => flavor == Flavor.prod;
}
