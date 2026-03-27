import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/constants.dart';

enum InlineNativeAdSize { small, medium }

class InlineNativeAd extends StatefulWidget {
  const InlineNativeAd({
    super.key,
    this.size = InlineNativeAdSize.small,
  });

  final InlineNativeAdSize size;

  @override
  State<InlineNativeAd> createState() => _InlineNativeAdState();
}

class _InlineNativeAdState extends State<InlineNativeAd> {
  static const String _productionAdUnitId =
      'ca-app-pub-2847412250241292/5885385759';
  static const String _androidTestAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _iosTestAdUnitId =
      'ca-app-pub-3940256099942544/3986624511';

  NativeAd? _nativeAd;
  bool _loadStarted = false;
  bool _isLoaded = false;
  bool _loadFailed = false;

  bool get _supportsMobileAds {
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

  double get _adHeight {
    switch (widget.size) {
      case InlineNativeAdSize.small:
        return 110;
      case InlineNativeAdSize.medium:
        return 340;
    }
  }

  TemplateType get _templateType {
    switch (widget.size) {
      case InlineNativeAdSize.small:
        return TemplateType.small;
      case InlineNativeAdSize.medium:
        return TemplateType.medium;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loadStarted || !_supportsMobileAds) {
      return;
    }

    _loadStarted = true;
    _loadAd();
  }

  void _loadAd() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final ad = NativeAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _isLoaded = true;
            _loadFailed = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) {
            return;
          }

          setState(() {
            _nativeAd = null;
            _isLoaded = false;
            _loadFailed = true;
          });
          debugPrint('Native ad failed to load: $error');
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: _templateType,
        mainBackgroundColor: theme.cardColor,
        cornerRadius: 18,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: scheme.onSurface,
          size: 16,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: scheme.onSurfaceVariant,
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: scheme.onSurfaceVariant,
          size: 12,
        ),
      ),
    );

    _nativeAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsMobileAds || _loadFailed) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Sponsored',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth.isFinite
                    ? constraints.maxWidth.clamp(0.0, 400.0)
                    : 400.0;

                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: width,
                    height: _adHeight,
                    child: _isLoaded && _nativeAd != null
                        ? AdWidget(ad: _nativeAd!)
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.45,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
