import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:__APP_NAME__/core/config/app_config.dart';
import 'package:__APP_NAME__/core/extensions/size_extensions.dart';
import 'package:__APP_NAME__/core/router/app_router.dart';
import 'package:__APP_NAME__/core/theme/app_theme.dart';
import 'package:__APP_NAME__/di/injection.dart';
import 'package:__APP_NAME__/integrations.dart';

Future<void> bootstrap({
  required Flavor flavor,
  required String envFile,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize(flavor: flavor, appName: '__APP_TITLE__');

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
