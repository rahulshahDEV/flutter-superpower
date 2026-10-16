import 'package:battery_analyzer/app.dart' as app;
import 'package:battery_analyzer/core/config/app_config.dart';

Future<void> main() => app.bootstrap(flavor: Flavor.dev, envFile: '.env.dev');
