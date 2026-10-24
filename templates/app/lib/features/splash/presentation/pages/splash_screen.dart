import 'package:flutter/material.dart';

import 'package:__APP_NAME__/core/constants/string_constants.dart';
import 'package:__APP_NAME__/core/theme/app_colors.dart';
import 'package:__APP_NAME__/core/theme/app_text_styles.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const String path = '/';
  static const String routeName = 'splash';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Text(
            StringConstants.appName,
            style: AppTextStyles.h2.copyWith(color: AppColors.white),
          ),
        ),
      ),
    );
  }
}
