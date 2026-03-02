import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

import 'full_screen_ad_guard.dart';

class AppOpenAdService {
  AppOpenAdService(this._logger, this._guard);

  // Production App Open unit for HEICFlow.
  static const String _productionAdUnitId =
      'ca-app-pub-2847412250241292/8255373151';

  // Official Google test App Open IDs for non-release builds.
  static const String _androidTestAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _iosTestAdUnitId =
      'ca-app-pub-3940256099942544/5575463023';

  static const Duration _adExpiration = Duration(hours: 4);
  static const Duration _showCooldown = Duration(minutes: 3);
  static const Duration _backgroundThreshold = Duration(seconds: 12);
  static const Duration _crossFormatCooldown = Duration(seconds: 30);

  final Logger _logger;
  final FullScreenAdGuard _guard;

  AppOpenAd? _appOpenAd;
  DateTime? _adLoadedAt;
  DateTime? _lastShownAt;
  DateTime? _lastBackgroundAt;
  StreamSubscription<AppState>? _appStateSubscription;

  bool _initialized = false;
  bool _initializing = false;
  bool _loading = false;
  bool _showing = false;
  bool _started = false;
  int _foregroundEvents = 0;

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

  Future<void> start() async {
    if (!_isSupportedPlatform || _started) {
      return;
    }
    _started = true;

    await initializeAndPreload();

    try {
      AppStateEventNotifier.startListening();
      _appStateSubscription = AppStateEventNotifier.appStateStream.listen(
        _onAppStateChanged,
        onError: (Object error, StackTrace stackTrace) {
          _logger.w('App state stream error: $error');
          _logger.d(stackTrace.toString());
        },
      );
    } catch (error, stackTrace) {
      _logger.w('Failed to start app state listener: $error');
      _logger.d(stackTrace.toString());
    }
  }

  Future<void> initializeAndPreload() async {
    if (!_isSupportedPlatform) {
      return;
    }

    if (_initialized) {
      _loadAppOpenAd();
      return;
    }
    if (_initializing) {
      return;
    }

    _initializing = true;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadAppOpenAd();
    } catch (error, stackTrace) {
      _logger.w('AdMob initialization failed (App Open): $error');
      _logger.d(stackTrace.toString());
    } finally {
      _initializing = false;
    }
  }

  void _onAppStateChanged(AppState appState) {
    if (appState == AppState.background) {
      _lastBackgroundAt = DateTime.now();
      return;
    }

    if (appState != AppState.foreground) {
      return;
    }

    _foregroundEvents += 1;

    final lastBackgroundAt = _lastBackgroundAt;
    final backgroundDuration = lastBackgroundAt == null
        ? Duration.zero
        : DateTime.now().difference(lastBackgroundAt);

    final meetsBackgroundThreshold = backgroundDuration >= _backgroundThreshold;

    // Skip first few foreground events to avoid immediate ad pressure on launch.
    if (_foregroundEvents <= 2 || !meetsBackgroundThreshold) {
      _loadAppOpenAd();
      return;
    }

    unawaited(showIfAvailable());
  }

  Future<void> showIfAvailable() async {
    if (!_isSupportedPlatform) {
      return;
    }

    await initializeAndPreload();

    if (_showing) {
      return;
    }

    final now = DateTime.now();
    final lastShownAt = _lastShownAt;
    if (lastShownAt != null && now.difference(lastShownAt) < _showCooldown) {
      _loadAppOpenAd();
      return;
    }

    if (_guard.isShowing || _guard.recentlyDismissed(_crossFormatCooldown)) {
      _loadAppOpenAd();
      return;
    }

    final ad = _appOpenAd;
    if (ad == null) {
      _loadAppOpenAd();
      return;
    }
    if (!_isAdFresh) {
      ad.dispose();
      _appOpenAd = null;
      _adLoadedAt = null;
      _loadAppOpenAd();
      return;
    }

    if (!_guard.tryAcquire()) {
      _loadAppOpenAd();
      return;
    }

    _showing = true;
    _appOpenAd = null;
    _adLoadedAt = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastShownAt = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showing = false;
        _guard.release();
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _logger.w('App Open ad failed to show: $error');
        ad.dispose();
        _showing = false;
        _guard.release();
        _loadAppOpenAd();
      },
    );

    try {
      ad.show();
    } catch (error, stackTrace) {
      _logger.w('App Open ad show exception: $error');
      _logger.d(stackTrace.toString());
      _showing = false;
      _guard.release();
      ad.dispose();
      _loadAppOpenAd();
    }
  }

  bool get _isAdFresh {
    final adLoadedAt = _adLoadedAt;
    if (adLoadedAt == null) {
      return false;
    }
    return DateTime.now().difference(adLoadedAt) < _adExpiration;
  }

  void _loadAppOpenAd() {
    if (!_isSupportedPlatform || !_initialized || _loading || _showing) {
      return;
    }
    if (_appOpenAd != null && _isAdFresh) {
      return;
    }
    if (_appOpenAd != null && !_isAdFresh) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _adLoadedAt = null;
    }

    _loading = true;
    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _appOpenAd = ad;
          _adLoadedAt = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          _appOpenAd = null;
          _adLoadedAt = null;
          _logger.w('App Open ad failed to load: $error');
        },
      ),
    );
  }

  void dispose() {
    _appStateSubscription?.cancel();
    _appStateSubscription = null;
    if (_isSupportedPlatform) {
      AppStateEventNotifier.stopListening();
    }
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _adLoadedAt = null;
    _started = false;
  }
}
