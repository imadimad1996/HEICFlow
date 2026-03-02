import 'package:flutter/material.dart';

ThemeData buildLightTheme(ColorScheme colorScheme) {
  return _buildTheme(colorScheme, Brightness.light);
}

ThemeData buildDarkTheme(ColorScheme colorScheme) {
  return _buildTheme(colorScheme, Brightness.dark);
}

ThemeData _buildTheme(ColorScheme scheme, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  final textTheme = _textTheme(base.textTheme, scheme, isDark);

  return base.copyWith(
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF090C12)
        : const Color(0xFFF4F7FB),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: isDark
          ? scheme.surfaceContainerLow.withValues(alpha: 0.78)
          : scheme.surface.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.32 : 0.2),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark
          ? scheme.surfaceContainerLowest.withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.92),
      elevation: 0,
      height: 72,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      useIndicator: true,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
      thumbIcon: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Icon(Icons.check_rounded, size: 14);
        }
        return const Icon(Icons.close_rounded, size: 14);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh.withValues(
        alpha: isDark ? 0.35 : 0.45,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    ),
  );
}

TextTheme _textTheme(TextTheme base, ColorScheme scheme, bool isDark) {
  final onSurface = scheme.onSurface;
  final onSurfaceVariant = scheme.onSurfaceVariant;

  return base.copyWith(
    headlineLarge: base.headlineLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      color: onSurface,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: onSurface,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: onSurface,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: onSurface,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: onSurface,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: onSurface,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      color: onSurface.withValues(alpha: isDark ? 0.95 : 0.9),
      height: 1.35,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      color: onSurfaceVariant,
      height: 1.35,
    ),
    bodySmall: base.bodySmall?.copyWith(
      color: onSurfaceVariant.withValues(alpha: 0.9),
      height: 1.3,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: onSurface,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: onSurfaceVariant,
    ),
  );
}
