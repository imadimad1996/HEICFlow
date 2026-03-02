import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

import 'full_screen_ad_guard.dart';

class InterstitialAdService {
  InterstitialAdService(this._logger, this._guard);

  // Production interstitial provided for HEICFlow.
  static const String _productionAdUnitId =
      'ca-app-pub-2847412250241292/1244755010';

  // Official Google test interstitial IDs for non-release builds.
  static const String _androidTestAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosTestAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  static const Duration _showCooldown = Duration(minutes: 2);
  static const Duration _crossFormatCooldown = Duration(seconds: 30);

  final Logger _logger;
  final FullScreenAdGuard _guard;

  InterstitialAd? _interstitialAd;
  bool _initialized = false;
  bool _initializing = false;
  bool _loading = false;
  bool _showing = false;
  bool _eligibleToShow = false;
  DateTime? _lastShownAt;

  bool get _isSupportedPlatform {
    if (kIsWeb || bool.fromEnvironment('FLUTTER_TEST')) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String get _adUnitId {
    if (kReleaseMode) {
      return _productionAdUnitId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestAdUnitId
        : _androidTestAdUnitId;
  }

  Future<void> initializeAndPreload() async {
    if (!_isSupportedPlatform) {
      return;
    }

    if (_initialized) {
      _loadInterstitial();
      return;
    }
    if (_initializing) {
      return;
    }

    _initializing = true;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
    } catch (error, stackTrace) {
      _logger.w('AdMob initialization failed: $error');
      _logger.d(stackTrace.toString());
    } finally {
      _initializing = false;
    }
  }

  void markCompletedExportEligible() {
    _eligibleToShow = true;
  }

  Future<void> showIfEligible({required VoidCallback onContinue}) async {
    if (!_isSupportedPlatform) {
      onContinue();
      return;
    }

    await initializeAndPreload();

    if (!_eligibleToShow) {
      onContinue();
      return;
    }

    final now = DateTime.now();
    if (_lastShownAt != null && now.difference(_lastShownAt!) < _showCooldown) {
      _eligibleToShow = false;
      _loadInterstitial();
      onContinue();
      return;
    }

    final ad = _interstitialAd;
    if (ad == null || _showing) {
      _eligibleToShow = false;
      _loadInterstitial();
      onContinue();
      return;
    }
    if (_guard.isShowing || _guard.recentlyDismissed(_crossFormatCooldown)) {
      _eligibleToShow = false;
      _loadInterstitial();
      onContinue();
      return;
    }
    if (!_guard.tryAcquire()) {
      _eligibleToShow = false;
      _loadInterstitial();
      onContinue();
      return;
    }

    _eligibleToShow = false;
    _showing = true;
    var continued = false;
    void continueOnce() {
      if (continued) {
        return;
      }
      continued = true;
      onContinue();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastShownAt = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _showing = false;
        _guard.release();
        _loadInterstitial();
        continueOnce();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _logger.w('Interstitial failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        _showing = false;
        _guard.release();
        _loadInterstitial();
        continueOnce();
      },
    );

    try {
      ad.show();
    } catch (error, stackTrace) {
      _logger.w('Interstitial show exception: $error');
      _logger.d(stackTrace.toString());
      _showing = false;
      _guard.release();
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _loadInterstitial();
      continueOnce();
    }
  }

  void _loadInterstitial() {
    if (!_isSupportedPlatform || !_initialized || _loading) {
      return;
    }
    if (_interstitialAd != null) {
      return;
    }

    _loading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          _interstitialAd = null;
          _logger.w('Interstitial failed to load: $error');
        },
      ),
    );
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
