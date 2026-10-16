"""Opt-in generated adapters; never register cloud resources implicitly."""
from pathlib import Path
from model import FactoryError, atomic_write, read_yaml, write_yaml

def configure(app: Path, data: dict):
    spec=read_yaml(app/'pubspec.yaml')
    deps=spec['dependencies']
    lines=["import 'package:"+data['app']['slug']+"/core/config/app_config.dart';"]
    body=[]
    if data['monetization']['admob']:
        deps['factory_ads']={'path':'../../packages/ads'}
        lines += ["import 'dart:io';", "import 'package:factory_ads/factory_ads.dart';"]
        body += ["  adsService = AdsService(enabled: true, production: flavor == Flavor.prod, productionUnits: AdUnits(",
          "    banner: Platform.isAndroid ? const String.fromEnvironment('ADMOB_ANDROID_BANNER') : const String.fromEnvironment('ADMOB_IOS_BANNER'),",
          "    interstitial: Platform.isAndroid ? const String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL') : const String.fromEnvironment('ADMOB_IOS_INTERSTITIAL'),",
          "    rewarded: Platform.isAndroid ? const String.fromEnvironment('ADMOB_ANDROID_REWARDED') : const String.fromEnvironment('ADMOB_IOS_REWARDED'),",
          "  ));", "  await adsService?.initialize();"]
    else:deps.pop('factory_ads',None)
    if data['firebase']['enabled']:
        deps['firebase_core']='^4.0.0'
        lines += ["import 'package:firebase_core/firebase_core.dart';", "import 'package:flutter/foundation.dart';", "import 'package:factory_analytics/factory_analytics.dart';"]
        body.insert(0,'  await Firebase.initializeApp();')
        if data['firebase']['analytics']:
            deps['firebase_analytics']='^12.0.0'
            lines.append("import 'package:firebase_analytics/firebase_analytics.dart';")
            body.insert(1,'  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(flavor == Flavor.prod);')
        if data['firebase']['crashlytics']:
            deps['firebase_crashlytics']='^5.0.0'
            lines.append("import 'package:firebase_crashlytics/firebase_crashlytics.dart';")
            body += ['  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(flavor == Flavor.prod);',
             '  FlutterError.onError = (details) { FlutterError.presentError(details); FirebaseCrashlytics.instance.recordFlutterFatalError(details); };',
             '  PlatformDispatcher.instance.onError = (error, stack) { FirebaseCrashlytics.instance.recordError(error, stack, fatal: true); return false; };']
        if not data['firebase']['crashlytics']:lines.remove("import 'package:flutter/foundation.dart';")
        # Analytics service remains explicitly injected by the app, avoiding global telemetry.
        lines.remove("import 'package:factory_analytics/factory_analytics.dart';")
    else:
        for dep in ('firebase_core','firebase_analytics','firebase_crashlytics'):deps.pop(dep,None)
    entry=app/'lib/integrations.dart'
    marker='// Factory-managed opt-in integration entrypoint.'
    if entry.exists() and marker not in entry.read_text():raise FactoryError('Refusing to overwrite custom integrations.dart')
    globals_='\nAdsService? adsService;\n' if data['monetization']['admob'] else ''
    # Sorted directives keep generated adapters lint clean.
    content='\n'.join(sorted(set(lines)))+'\n\n'+marker+'\n'+globals_+'\nFuture<void> configureIntegrations(Flavor flavor) async {\n'+'\n'.join(body)+'\n}\n'
    atomic_write(entry,content)
    write_yaml(app/'pubspec.yaml',spec)
