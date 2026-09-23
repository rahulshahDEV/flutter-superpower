import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import 'package:__APP_NAME__/core/config/app_config.dart';
import 'package:__APP_NAME__/core/constants/string_constants.dart';
import 'package:__APP_NAME__/features/home/presentation/pages/home_screen.dart';
import 'package:__APP_NAME__/features/splash/presentation/pages/splash_screen.dart';

@singleton
class AppRouter {
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  GoRouter get router => _router;

  late final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: SplashScreen.path,
    debugLogDiagnostics: AppConfig.instance.isDev,
    routes: [
      GoRoute(
        path: SplashScreen.path,
        name: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: HomeScreen.path,
        name: HomeScreen.routeName,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(StringConstants.pageNotFound)),
    ),
  );
}
