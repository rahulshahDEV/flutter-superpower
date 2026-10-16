import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Public AdMob unit identifiers. Private service credentials never belong here.
class AdUnits {
  const AdUnits({
    required this.banner,
    required this.interstitial,
    required this.rewarded,
  });

  final String banner;
  final String interstitial;
  final String rewarded;

  static AdUnits test({required bool android}) => android
      ? const AdUnits(
          banner: 'ca-app-pub-3940256099942544/6300978111',
          interstitial: 'ca-app-pub-3940256099942544/1033173712',
          rewarded: 'ca-app-pub-3940256099942544/5224354917',
        )
      : const AdUnits(
          banner: 'ca-app-pub-3940256099942544/2934735716',
          interstitial: 'ca-app-pub-3940256099942544/4411468910',
          rewarded: 'ca-app-pub-3940256099942544/1712485313',
        );
}

/// Own one instance per app session. Initialize after native AdMob setup.
///
/// Initialization collects UMP consent but never loads or displays an ad.
/// Callers own placement policy, frequency limits and a visible privacy entry.
class AdsService extends ChangeNotifier {
  AdsService({
    required this.enabled,
    required bool production,
    required AdUnits productionUnits,
    bool automatedTesting = false,
  }) : units =
           useTestAds(
             production: production,
             automatedTesting: automatedTesting,
           )
           ? AdUnits.test(
               android: defaultTargetPlatform == TargetPlatform.android,
             )
           : productionUnits;

  final bool enabled;
  final AdUnits units;
  static const _automatedTest = bool.fromEnvironment('AUTOMATED_TEST');
  static const _loadTimeout = Duration(seconds: 15);
  static Future<InitializationStatus>? _sdkInitialization;
  Future<bool>? _initializing;
  Future<bool>? _interstitialLoading;
  Future<bool>? _rewardedLoading;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  final Set<Completer<bool>> _pendingLoads = {};
  bool _consentAllowed = false;
  bool _initialized = false;
  bool _disposed = false;
  bool _showing = false;
  bool _privacyUpdating = false;
  int _generation = 0;
  String? lastError;
  bool privacyOptionsRequired = false;

  static bool useTestAds({
    required bool production,
    bool automatedTesting = false,
  }) => !production || kDebugMode || automatedTesting || _automatedTest;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get canRequestAds =>
      enabled && _supported && !_disposed && _initialized && _consentAllowed;

  Future<bool> initialize() {
    if (!enabled || !_supported || _disposed) return Future.value(false);
    if (_initialized) return Future.value(canRequestAds);
    return _initializing ??= _initialize().whenComplete(
      () => _initializing = null,
    );
  }

  Future<bool> _initialize() async {
    try {
      final updated = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => updated.complete(),
        (error) => updated.completeError(error),
      );
      await updated.future.timeout(_loadTimeout);
      if (_disposed) return false;
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) lastError = error.message;
      });
      if (_disposed) return false;
      _consentAllowed = await ConsentInformation.instance.canRequestAds();
      privacyOptionsRequired =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (!_consentAllowed || _disposed) return false;
      _sdkInitialization ??= MobileAds.instance.initialize().catchError((
        Object error,
        StackTrace stack,
      ) {
        _sdkInitialization = null;
        Error.throwWithStackTrace(error, stack);
      });
      await _sdkInitialization;
      if (_disposed) return false;
      _initialized = true;
      notifyListeners();
      return canRequestAds;
    } catch (error) {
      lastError = 'Ads initialization failed: $error';
      _consentAllowed = false;
      // Fail closed. A subsequent explicit initialize call can retry consent.
      return false;
    }
  }

  /// Connect this to the visible settings privacy entry when UMP requires it.
  Future<bool> showPrivacyOptions() async {
    if (!enabled ||
        !_supported ||
        _disposed ||
        _privacyUpdating ||
        !privacyOptionsRequired) {
      return false;
    }
    _privacyUpdating = true;
    _consentAllowed = false;
    _invalidateAds();
    notifyListeners();
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) lastError = error.message;
      });
      if (_disposed) return false;
      _consentAllowed = await ConsentInformation.instance.canRequestAds();
      privacyOptionsRequired =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (!_disposed) notifyListeners();
      return canRequestAds;
    } catch (error) {
      lastError = 'Privacy options failed: $error';
      return false;
    } finally {
      _privacyUpdating = false;
    }
  }

  Future<bool> _load<T extends Ad>({
    required Future<void> Function(
      void Function(T) loaded,
      void Function(LoadAdError) failed,
    )
    request,
    required void Function(T) keep,
  }) async {
    if (!canRequestAds) return false;
    final generation = _generation;
    final completed = Completer<bool>();
    _pendingLoads.add(completed);
    final timer = Timer(_loadTimeout, () {
      lastError = 'Ad load timed out';
      if (!completed.isCompleted) completed.complete(false);
    });
    try {
      unawaited(
        request(
          (ad) {
            if (completed.isCompleted ||
                !canRequestAds ||
                generation != _generation) {
              unawaited(ad.dispose());
              if (!completed.isCompleted) completed.complete(false);
              return;
            }
            keep(ad);
            completed.complete(true);
          },
          (error) {
            lastError = 'Ad load failed: ${error.code}';
            if (!completed.isCompleted) completed.complete(false);
          },
        ).catchError((Object error) {
          lastError = 'Ad request failed: $error';
          if (!completed.isCompleted) completed.complete(false);
        }),
      );
      return await completed.future;
    } finally {
      timer.cancel();
      _pendingLoads.remove(completed);
    }
  }

  /// One bounded request; callers choose if and when to retry a failure.
  Future<bool> loadInterstitial() {
    if (!canRequestAds) return Future.value(false);
    if (_interstitial != null) return Future.value(true);
    final generation = _generation;
    return _interstitialLoading ??=
        _load<InterstitialAd>(
          request: (loaded, failed) => InterstitialAd.load(
            adUnitId: units.interstitial,
            request: const AdRequest(),
            adLoadCallback: InterstitialAdLoadCallback(
              onAdLoaded: loaded,
              onAdFailedToLoad: failed,
            ),
          ),
          keep: (ad) => _interstitial = ad,
        ).whenComplete(() {
          if (generation == _generation) _interstitialLoading = null;
        });
  }

  Future<bool> loadRewarded() {
    if (!canRequestAds) return Future.value(false);
    if (_rewarded != null) return Future.value(true);
    final generation = _generation;
    return _rewardedLoading ??=
        _load<RewardedAd>(
          request: (loaded, failed) => RewardedAd.load(
            adUnitId: units.rewarded,
            request: const AdRequest(),
            rewardedAdLoadCallback: RewardedAdLoadCallback(
              onAdLoaded: loaded,
              onAdFailedToLoad: failed,
            ),
          ),
          keep: (ad) => _rewarded = ad,
        ).whenComplete(() {
          if (generation == _generation) _rewardedLoading = null;
        });
  }

  /// Never call at startup, app exit, or while a user is performing an action.
  Future<bool> showInterstitial({required bool atNaturalBreak}) async {
    final ad = _interstitial;
    if (!atNaturalBreak || !canRequestAds || _showing || ad == null) {
      return false;
    }
    _interstitial = null;
    _showing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => _finish(ad),
      onAdFailedToShowFullScreenContent: (ad, error) {
        lastError = 'Interstitial could not be displayed: ${error.code}';
        _finish(ad);
      },
    );
    try {
      await ad.show();
      return true;
    } catch (error) {
      lastError = 'Interstitial display failed: $error';
      _finish(ad);
      return false;
    }
  }

  /// Reward only in the SDK earned-reward callback, after explicit user opt-in.
  Future<bool> showRewarded({
    required bool userOptedIn,
    required void Function(RewardItem reward) onReward,
  }) async {
    final ad = _rewarded;
    if (!userOptedIn || !canRequestAds || _showing || ad == null) return false;
    _rewarded = null;
    _showing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => _finish(ad),
      onAdFailedToShowFullScreenContent: (ad, error) {
        lastError = 'Rewarded ad could not be displayed: ${error.code}';
        _finish(ad);
      },
    );
    try {
      await ad.show(onUserEarnedReward: (ad, reward) => onReward(reward));
      return true;
    } catch (error) {
      lastError = 'Rewarded ad display failed: $error';
      _finish(ad);
      return false;
    }
  }

  void _finish(Ad ad) {
    _showing = false;
    unawaited(ad.dispose());
  }

  void _invalidateAds() {
    _generation++;
    final interstitial = _interstitial;
    final rewarded = _rewarded;
    _interstitial = null;
    _rewarded = null;
    _interstitialLoading = null;
    _rewardedLoading = null;
    if (interstitial != null) unawaited(interstitial.dispose());
    if (rewarded != null) unawaited(rewarded.dispose());
    for (final pending in _pendingLoads.toList()) {
      if (!pending.isCompleted) pending.complete(false);
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _consentAllowed = false;
    _invalidateAds();
    // Mounted banner slots must release their native view immediately.
    notifyListeners();
    super.dispose();
  }
}

/// Place in a dedicated bottom slot, separated from buttons and app content.
/// Hides until consent permits ads. Never overlays controls or scroll content.
class FactoryBanner extends StatefulWidget {
  const FactoryBanner({required this.service, super.key});

  final AdsService service;

  @override
  State<FactoryBanner> createState() => _FactoryBannerState();
}

class _FactoryBannerState extends State<FactoryBanner> {
  static const _separation = 16.0;
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_consentChanged);
    _sync();
  }

  @override
  void didUpdateWidget(FactoryBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      oldWidget.service.removeListener(_consentChanged);
      widget.service.addListener(_consentChanged);
      _clear();
      _sync();
    }
  }

  void _consentChanged() {
    _clear();
    _sync();
    if (mounted) setState(() {});
  }

  void _clear() {
    final ad = _ad;
    _ad = null;
    _loaded = false;
    if (ad != null) unawaited(ad.dispose());
  }

  void _sync() {
    if (!widget.service.canRequestAds) return;
    final ad = BannerAd(
      adUnitId: widget.service.units.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || _ad != ad || !widget.service.canRequestAds) {
            unawaited(ad.dispose());
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          if (_ad == ad) {
            _clear();
            if (mounted) setState(() {});
          } else {
            unawaited(ad.dispose());
          }
        },
      ),
    );
    _ad = ad;
    unawaited(
      ad.load().catchError((Object error) {
        if (_ad == ad) {
          _clear();
          if (mounted) setState(() {});
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!widget.service.canRequestAds || ad == null) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < ad.size.width) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          top: false,
          minimum: const EdgeInsets.only(top: _separation),
          child: Center(
            heightFactor: 1,
            child: SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: _loaded ? AdWidget(ad: ad) : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.service.removeListener(_consentChanged);
    _clear();
    super.dispose();
  }
}
