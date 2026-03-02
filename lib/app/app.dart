import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import '../features/settings/settings_controller.dart';
import '../utils/constants.dart';
import 'router.dart';
import 'theme.dart';

class HEICFlowApp extends ConsumerStatefulWidget {
  const HEICFlowApp({super.key});

  @override
  ConsumerState<HEICFlowApp> createState() => _HEICFlowAppState();
}

class _HEICFlowAppState extends ConsumerState<HEICFlowApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(ref.read(appOpenAdServiceProvider).start());
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(appRouterProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme =
            lightDynamic ??
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF005F73),
              brightness: Brightness.light,
            );

        final darkScheme =
            darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF9B2226),
              brightness: Brightness.dark,
            );

        return MaterialApp.router(
          title: AppBrand.name,
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(lightScheme),
          darkTheme: buildDarkTheme(darkScheme),
          themeMode: settings.themeMode,
          routerConfig: router,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const <Locale>[Locale('en')],
        );
      },
    );
  }
}
