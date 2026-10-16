import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:__APP_NAME__/core/constants/string_constants.dart';
import 'package:__APP_NAME__/core/extensions/size_extensions.dart';
import 'package:__APP_NAME__/core/theme/app_colors.dart';
import 'package:__APP_NAME__/core/theme/app_text_styles.dart';
import 'package:__APP_NAME__/core/widgets/app_snack_bar.dart';
import 'package:__APP_NAME__/core/widgets/empty_state_widget.dart';
import 'package:__APP_NAME__/core/widgets/error_state_widget.dart';
import 'package:__APP_NAME__/core/widgets/loading_widget.dart';
import 'package:__APP_NAME__/di/injection.dart';
import 'package:__APP_NAME__/features/__FEATURE__/presentation/cubit/__FEATURE__/__FEATURE___cubit.dart';
import 'package:__APP_NAME__/features/__FEATURE__/presentation/cubit/__FEATURE__/__FEATURE___state.dart';

class __FEATURE_CLASS__Screen extends StatelessWidget {
  const __FEATURE_CLASS__Screen({super.key});

  static const String path = '/__FEATURE__';
  static const String routeName = '__FEATURE__';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<__FEATURE_CLASS__Cubit>()..load(),
      child: const ___FEATURE_CLASS__View(),
    );
  }
}

class ___FEATURE_CLASS__View extends StatelessWidget {
  const ___FEATURE_CLASS__View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('__FEATURE_CLASS__')),
      body: SafeArea(
        child: BlocConsumer<__FEATURE_CLASS__Cubit, __FEATURE_CLASS__State>(
          listener: (context, state) {
            if (state is __FEATURE_CLASS__Failure) {
              AppSnackBar.showError(context, state.failure.message);
            }
          },
          builder: (context, state) => switch (state) {
            __FEATURE_CLASS__Initial() ||
            __FEATURE_CLASS__Loading() =>
              const LoadingWidget(),
            __FEATURE_CLASS__Failure(:final failure) => ErrorStateWidget(
                message: failure.message,
                onRetry: () => context.read<__FEATURE_CLASS__Cubit>().load(),
              ),
            __FEATURE_CLASS__Success(:final items) when items.isEmpty =>
              const EmptyStateWidget(title: StringConstants.noDataYet),
            __FEATURE_CLASS__Success(:final items) => ListView.separated(
                padding: EdgeInsets.all(AppSizes.md),
                itemCount: items.length,
                separatorBuilder: (_, _) => VerticalSpace(AppSizes.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    padding: EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(item.name, style: AppTextStyles.body),
                  );
                },
              ),
          },
        ),
      ),
    );
  }
}
