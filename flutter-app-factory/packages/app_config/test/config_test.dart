import 'package:factory_app_config/factory_app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps app identity and flavor independent', () {
    AppConfig.initialize(flavor: Flavor.dev, appName: 'Example');
    expect(AppConfig.instance.isDev, true);
    expect(AppConfig.instance.appName, 'Example');
    expect(AppConfig.instance.featureFlags, isEmpty);
  });
}
