import 'dart:io';
import 'package:battery_analyzer/core/config/app_config.dart';
import 'package:factory_ads/factory_ads.dart';

// Factory-managed opt-in integration entrypoint.

AdsService? adsService;

Future<void> configureIntegrations(Flavor flavor) async {
  adsService = AdsService(
    enabled: true,
    production: flavor == Flavor.prod,
    productionUnits: AdUnits(
      banner: Platform.isAndroid
          ? const String.fromEnvironment('ADMOB_ANDROID_BANNER')
          : const String.fromEnvironment('ADMOB_IOS_BANNER'),
      interstitial: Platform.isAndroid
          ? const String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL')
          : const String.fromEnvironment('ADMOB_IOS_INTERSTITIAL'),
      rewarded: Platform.isAndroid
          ? const String.fromEnvironment('ADMOB_ANDROID_REWARDED')
          : const String.fromEnvironment('ADMOB_IOS_REWARDED'),
    ),
  );
  await adsService?.initialize();
}
