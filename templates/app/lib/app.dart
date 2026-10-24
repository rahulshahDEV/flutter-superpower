import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:__APP_NAME__/core/config/app_config.dart';
import 'package:__APP_NAME__/core/config/app_platform.dart';
import 'package:__APP_NAME__/core/constants/string_constants.dart';
import 'package:__APP_NAME__/core/extensions/size_extensions.dart';
import 'package:__APP_NAME__/core/router/app_router.dart';
import 'package:__APP_NAME__/core/theme/app_theme.dart';
import 'package:__APP_NAME__/di/injection.dart';

Future<void> bootstrap({
  required Flavor flavor,
  required String envFile,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: envFile);
    AppConfig.initialize(flavor: flavor, appName: '__APP_TITLE__');
    await AppPlatform.configure();
    await configureDependencies();
    runApp(const App());
  } on Object catch (error, stackTrace) {
    // Keep diagnostics free of config values and tokens, including before DI exists.
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError(
          'Application startup failed (${error.runtimeType})',
        ),
        stack: stackTrace,
      ),
    );
    runApp(const StartupFailureApp());
  }
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
        routerConfig: getIt<AppRouter>().router,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemUiOverlayStyle,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(child: Text(StringConstants.startupFailed)),
        ),
      ),
    );
  }
}
