import 'package:__APP_NAME__/app.dart' as app;
import 'package:__APP_NAME__/core/config/app_config.dart';

Future<void> main() => app.bootstrap(flavor: Flavor.dev, envFile: '.env.dev');
