import 'package:flutter/material.dart';

import 'package:__APP_NAME__/core/constants/string_constants.dart';
import 'package:__APP_NAME__/core/extensions/size_extensions.dart';
import 'package:__APP_NAME__/core/theme/app_colors.dart';
import 'package:__APP_NAME__/core/theme/app_text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String path = '/home';
  static const String routeName = 'home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(StringConstants.appName)),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VerticalSpace(AppSizes.lg),
              Text('Welcome', style: AppTextStyles.h1),
              VerticalSpace(AppSizes.sm),
              Text(
                'This app was generated with the flutter-superpower house style. '
                'Add a feature with: scripts/new_feature.sh <name>',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
