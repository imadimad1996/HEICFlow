import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/providers.dart';

class RatingService {
  RatingService(this._prefs);

  final SharedPreferences _prefs;

  static const String _kExportCountKey = 'rating_export_count';
  static const String _kLastPromptKey = 'rating_last_prompt_timestamp';
  static const int _kMinExportsThreshold = 3;

  int get exportCount => _prefs.getInt(_kExportCountKey) ?? 0;

  Future<void> recordSuccessfulExport(int itemCount) async {
    final newCount = exportCount + itemCount;
    await _prefs.setInt(_kExportCountKey, newCount);
  }

  bool shouldPromptRating() {
    if (exportCount < _kMinExportsThreshold) return false;

    final lastPrompt = _prefs.getInt(_kLastPromptKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;

    return (now - lastPrompt) > thirtyDaysMs;
  }

  Future<void> markPrompted() async {
    await _prefs.setInt(
      _kLastPromptKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> openStorePage() async {
    final Uri storeUri = Uri.parse(
      defaultTargetPlatform == TargetPlatform.iOS
          ? 'https://apps.apple.com/app/id6400000000'
          : 'https://play.google.com/store/apps/details?id=com.heicflow.app',
    );
    if (await canLaunchUrl(storeUri)) {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    }
  }
}

final ratingServiceProvider = Provider<RatingService>((ref) {
  return RatingService(ref.watch(sharedPreferencesProvider));
});
