import 'package:app_one/app.dart' as app;
import 'package:app_one/core/config/app_config.dart';

Future<void> main() => app.bootstrap(flavor: Flavor.prod, envFile: '.env.prod');
