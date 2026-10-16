import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:app_one/core/config/app_config.dart';
import 'package:app_one/core/extensions/size_extensions.dart';
import 'package:app_one/core/router/app_router.dart';
import 'package:app_one/core/theme/app_theme.dart';
import 'package:app_one/di/injection.dart';
import 'package:app_one/integrations.dart';

Future<void> bootstrap({
  required Flavor flavor,
  required String envFile,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize(flavor: flavor, appName: 'Example App');

  await configureDependencies();
  await configureIntegrations(flavor);

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppSizes.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, _) => MaterialApp.router(
        title: AppConfig.instance.appName,
        debugShowCheckedModeBanner: AppConfig.instance.isDev,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: getIt<AppRouter>().router,
      ),
    );
  }
}
