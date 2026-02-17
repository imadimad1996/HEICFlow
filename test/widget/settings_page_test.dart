import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:heicflow/app/providers.dart';
import 'package:heicflow/features/settings/settings_controller.dart';
import 'package:heicflow/features/settings/settings_page.dart';

void main() {
  testWidgets('settings page toggles theme and keep temp files', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsPage)),
    );
    expect(
      container.read(settingsControllerProvider).themeMode,
      ThemeMode.dark,
    );

    await tester.tap(find.text('Keep temporary files'));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsControllerProvider).keepTemporaryFiles,
      isTrue,
    );
  });
}
