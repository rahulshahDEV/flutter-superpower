import 'package:flutter/material.dart';

import 'package:battery_analyzer/core/constants/string_constants.dart';
import 'package:battery_analyzer/core/extensions/context_extensions.dart';
import 'package:battery_analyzer/core/theme/app_colors.dart';
import 'package:battery_analyzer/features/home/presentation/pages/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String path = '/';
  static const String routeName = 'splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _openHome();
  }

  Future<void> _openHome() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    context.goReplace(HomeScreen.path);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Text(
          StringConstants.appName,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
