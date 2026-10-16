import 'dart:convert';

enum Flavor { dev, prod }

/// Only public client settings. Secrets cannot be protected in a mobile binary.
class AppConfig {
  AppConfig._({
    required this.flavor,
    required this.baseUrl,
    required this.appName,
  });
  static AppConfig? _instance;
  static AppConfig get instance =>
      _instance ?? (throw StateError('Initialize AppConfig first'));
  static bool get isInitialized => _instance != null;
  static void initialize({required Flavor flavor, required String appName}) {
    const selected = String.fromEnvironment('FLAVOR');
    if (selected.isNotEmpty && selected != flavor.name) {
      throw StateError('Dart configuration and native flavor disagree');
    }
    _instance = AppConfig._(
      flavor: flavor,
      baseUrl: const String.fromEnvironment('API_URL'),
      appName: appName,
    );
  }

  final Flavor flavor;
  final String baseUrl;
  final String appName;
  bool get isDev => flavor == Flavor.dev;
  bool get isProd => flavor == Flavor.prod;
  Map<String, bool> get featureFlags {
    const raw = String.fromEnvironment('FEATURE_FLAGS', defaultValue: '{}');
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    return parsed.map((key, value) => MapEntry(key, value == true));
  }
}
