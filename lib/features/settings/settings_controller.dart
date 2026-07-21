import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../models/export_job.dart';
import '../../utils/constants.dart';
import '../../utils/file_utils.dart';

@immutable
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.defaultFormat,
    required this.defaultJpgQuality,
    required this.keepTemporaryFiles,
    required this.hasSeenOnboarding,
  });

  final ThemeMode themeMode;
  final ExportTargetFormat defaultFormat;
  final int defaultJpgQuality;
  final bool keepTemporaryFiles;
  final bool hasSeenOnboarding;

  AppSettings copyWith({
    ThemeMode? themeMode,
    ExportTargetFormat? defaultFormat,
    int? defaultJpgQuality,
    bool? keepTemporaryFiles,
    bool? hasSeenOnboarding,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      defaultJpgQuality: defaultJpgQuality ?? this.defaultJpgQuality,
      keepTemporaryFiles: keepTemporaryFiles ?? this.keepTemporaryFiles,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._prefs)
    : super(
        AppSettings(
          themeMode: _readThemeMode(_prefs),
          defaultFormat: _readDefaultFormat(_prefs),
          defaultJpgQuality: _readJpgQuality(_prefs),
          keepTemporaryFiles: _prefs.getBool(_kKeepTempKey) ?? false,
          hasSeenOnboarding: _prefs.getBool(_kHasSeenOnboardingKey) ?? false,
        ),
      );

  final SharedPreferences _prefs;

  static const String _kThemeModeKey = 'settings_theme_mode';
  static const String _kDefaultFormatKey = 'settings_default_format';
  static const String _kJpgQualityKey = 'settings_jpg_quality';
  static const String _kKeepTempKey = 'settings_keep_temp';
  static const String _kHasSeenOnboardingKey = 'settings_has_seen_onboarding';

  void completeOnboarding() {
    state = state.copyWith(hasSeenOnboarding: true);
    _prefs.setBool(_kHasSeenOnboardingKey, true);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setString(_kThemeModeKey, mode.name);
  }

  void setDefaultFormat(ExportTargetFormat format) {
    state = state.copyWith(defaultFormat: format);
    _prefs.setString(_kDefaultFormatKey, format.name);
  }

  void setDefaultJpgQuality(int quality) {
    final clamped = quality.clamp(
      AppLimits.minJpgQuality,
      AppLimits.maxJpgQuality,
    );
    state = state.copyWith(defaultJpgQuality: clamped);
    _prefs.setInt(_kJpgQualityKey, clamped);
  }

  void setKeepTemporaryFiles(bool value) {
    state = state.copyWith(keepTemporaryFiles: value);
    _prefs.setBool(_kKeepTempKey, value);
  }

  Future<void> clearCache() async {
    await clearAppCache();
  }

  static ThemeMode _readThemeMode(SharedPreferences prefs) {
    final value = prefs.getString(_kThemeModeKey) ?? ThemeMode.system.name;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  static ExportTargetFormat _readDefaultFormat(SharedPreferences prefs) {
    final value =
        prefs.getString(_kDefaultFormatKey) ?? ExportTargetFormat.jpg.name;
    return ExportTargetFormat.values.firstWhere(
      (format) => format.name == value,
      orElse: () => ExportTargetFormat.jpg,
    );
  }

  static int _readJpgQuality(SharedPreferences prefs) {
    return prefs.getInt(_kJpgQualityKey) ?? AppLimits.defaultJpgQuality;
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
      return SettingsController(ref.watch(sharedPreferencesProvider));
    });

final cacheSizeProvider = FutureProvider<int>((ref) async {
  return cacheDirectorySizeBytes();
});
