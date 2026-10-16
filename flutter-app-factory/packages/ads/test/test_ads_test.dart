import 'package:factory_ads/factory_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class FakeConsentInformation implements ConsentInformation {
  int updates = 0;
  bool failUpdate = false;
  bool delayUpdate = false;
  OnConsentInfoUpdateSuccessListener? completeUpdate;

  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) {
    updates++;
    if (failUpdate) {
      failureListener(FormError(errorCode: 1, message: 'Consent unavailable'));
    } else if (delayUpdate) {
      completeUpdate = successListener;
    } else {
      successListener();
    }
  }

  @override
  Future<bool> canRequestAds() async => false;

  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async =>
      PrivacyOptionsRequirementStatus.notRequired;

  @override
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.required;

  @override
  Future<bool> isConsentFormAvailable() async => false;

  @override
  Future<void> reset() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const productionUnits = AdUnits(
    banner: 'ca-app-pub-1234567890123456/1234567890',
    interstitial: 'ca-app-pub-1234567890123456/1234567891',
    rewarded: 'ca-app-pub-1234567890123456/1234567892',
  );
  late ConsentInformation originalConsent;
  late FakeConsentInformation consent;
  const ump = MethodChannel('plugins.flutter.io/google_mobile_ads/ump');
  var formRequests = 0;

  setUp(() {
    originalConsent = ConsentInformation.instance;
    consent = FakeConsentInformation();
    ConsentInformation.instance = consent;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    formRequests = 0;
    // Stub Dart form transport only. No native SDK or ad network runs.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ump, (call) async {
          expect(
            call.method,
            'UserMessagingPlatform#loadAndShowConsentFormIfRequired',
          );
          formRequests++;
          return null;
        });
  });

  tearDown(() {
    ConsentInformation.instance = originalConsent;
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ump, null);
  });

  AdsService service({bool enabled = true, bool automatedTesting = false}) =>
      AdsService(
        enabled: enabled,
        production: true,
        productionUnits: productionUnits,
        automatedTesting: automatedTesting,
      );

  test('automated testing always selects sample ads even for prod', () {
    expect(
      AdsService.useTestAds(production: true, automatedTesting: true),
      isTrue,
    );
    expect(AdUnits.test(android: true).rewarded, contains('3940256099942544'));
    expect(
      AdUnits.test(android: false).banner,
      isNot(AdUnits.test(android: true).banner),
    );
    final ads = service(automatedTesting: true);
    expect(ads.units.banner, AdUnits.test(android: true).banner);
    expect(ads.units.interstitial, AdUnits.test(android: true).interstitial);
    expect(ads.units.rewarded, AdUnits.test(android: true).rewarded);
    ads.dispose();
  });

  test('debug production and development always select test ads', () {
    expect(AdsService.useTestAds(production: true), isTrue);
    expect(AdsService.useTestAds(production: false), isTrue);
  });

  test(
    'disabled ads never request consent, load, show, or grant rewards',
    () async {
      final ads = service(enabled: false);
      var rewards = 0;
      expect(await ads.initialize(), isFalse);
      expect(await ads.loadInterstitial(), isFalse);
      expect(await ads.loadRewarded(), isFalse);
      expect(await ads.showInterstitial(atNaturalBreak: true), isFalse);
      expect(
        await ads.showRewarded(userOptedIn: true, onReward: (_) => rewards++),
        isFalse,
      );
      expect(await ads.showPrivacyOptions(), isFalse);
      expect(ads.canRequestAds, isFalse);
      expect(consent.updates, 0);
      expect(formRequests, 0);
      expect(rewards, 0);
      ads.dispose();
    },
  );

  test(
    'concurrent initialization deduplicates consent and fails closed',
    () async {
      final ads = service();
      final first = ads.initialize();
      final second = ads.initialize();
      expect(identical(first, second), isTrue);
      expect(await first, isFalse);
      expect(await second, isFalse);
      expect(consent.updates, 1);
      expect(formRequests, 1);
      expect(ads.canRequestAds, isFalse);
      expect(await ads.loadInterstitial(), isFalse);
      expect(await ads.loadRewarded(), isFalse);
      ads.dispose();
    },
  );

  test(
    'consent update failure blocks SDK and reports an actionable error',
    () async {
      consent.failUpdate = true;
      final ads = service();
      expect(await ads.initialize(), isFalse);
      expect(ads.lastError, contains('initialization failed'));
      expect(formRequests, 0);
      expect(ads.canRequestAds, isFalse);
      ads.dispose();
    },
  );

  test(
    'disposing during consent stops initialization before form or SDK',
    () async {
      consent.delayUpdate = true;
      final ads = service();
      final initializing = ads.initialize();
      ads.dispose();
      consent.completeUpdate?.call();
      expect(await initializing, isFalse);
      expect(formRequests, 0);
      expect(ads.canRequestAds, isFalse);
    },
  );

  test('unsupported platforms do not request native ads', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final ads = service();
    expect(await ads.initialize(), isFalse);
    expect(consent.updates, 0);
    ads.dispose();
  });

  testWidgets('disabled banner occupies no slot and requests no ad', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = null;
    final ads = service(enabled: false);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FactoryBanner(service: ads),
      ),
    );
    expect(find.byType(AdWidget), findsNothing);
    expect(find.byType(SafeArea), findsNothing);
    expect(consent.updates, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    ads.dispose();
  });
}
