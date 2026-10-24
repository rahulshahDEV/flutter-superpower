import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:__APP_NAME__/core/theme/app_colors.dart';
import 'package:__APP_NAME__/core/theme/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static const systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.primaryDark,
        surface: AppColors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        outline: AppColors.border,
      ),
      textTheme:
          TextTheme(
            headlineLarge: AppTextStyles.h1,
            headlineMedium: AppTextStyles.h2,
            headlineSmall: AppTextStyles.h3,
            bodyLarge: AppTextStyles.bodyLarge,
            bodyMedium: AppTextStyles.body,
            bodySmall: AppTextStyles.bodySmall,
            labelLarge: AppTextStyles.label,
            labelSmall: AppTextStyles.caption,
          ).apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: systemUiOverlayStyle,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
