import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:heicflow/app/app.dart';
import 'package:heicflow/app/providers.dart';

void main() {
  testWidgets('app boots to import flow', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const HEICFlowApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HEICFlow'), findsWidgets);
    expect(find.text('Import'), findsWidgets);
  });
}
