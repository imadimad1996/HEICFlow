import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/constants.dart';
import '../widgets/inline_native_ad.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const List<String> _paths = <String>[
    '/import',
    '/gallery',
    '/history',
    '/settings',
  ];

  static const List<NavigationDestination> _destinations =
      <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.file_open_outlined),
          selectedIcon: Icon(Icons.file_open_rounded),
          label: 'Import',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Gallery',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history_rounded),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune_rounded),
          label: 'Settings',
        ),
      ];

  int _indexFromLocation() {
    for (var i = 0; i < _paths.length; i++) {
      if (location.startsWith(_paths[i])) {
        return i;
      }
    }
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    context.go(_paths[index]);
  }

  bool get _showInlineAd => !location.startsWith('/settings');

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _indexFromLocation();
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= kTabletBreakpoint;

    return Scaffold(
      extendBody: true,
      body: _AuroraBackground(
        child: useRail
            ? _RailLayout(
                selectedIndex: selectedIndex,
                showInlineAd: _showInlineAd,
                child: child,
                onDestinationSelected: (index) =>
                    _onDestinationSelected(context, index),
              )
            : Column(
                children: <Widget>[
                  Expanded(child: child),
                  if (_showInlineAd)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.xs,
                      ),
                      child: InlineNativeAd(),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: useRail
          ? null
          : _BottomDock(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
            ),
    );
  }
}

class _RailLayout extends StatelessWidget {
  const _RailLayout({
    required this.selectedIndex,
    required this.showInlineAd,
    required this.child,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final bool showInlineAd;
  final Widget child;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              width: 120,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: <Widget>[
                  const Icon(Icons.auto_awesome_rounded),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppBrand.name,
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: NavigationRail(
                      selectedIndex: selectedIndex,
                      groupAlignment: -0.8,
                      minWidth: 86,
                      onDestinationSelected: onDestinationSelected,
                      labelType: NavigationRailLabelType.all,
                      destinations: AppShell._destinations
                          .map(
                            (destination) => NavigationRailDestination(
                              icon: destination.icon,
                              selectedIcon: destination.selectedIcon,
                              label: Text(destination.label),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: ColoredBox(
                  color: scheme.surface.withValues(alpha: 0.35),
                  child: Column(
                    children: <Widget>[
                      Expanded(child: child),
                      if (showInlineAd)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.md,
                          ),
                          child: InlineNativeAd(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: AppShell._destinations,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          ),
        ),
      ),
    );
  }
}

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                scheme.primaryContainer.withValues(alpha: 0.18),
                scheme.tertiaryContainer.withValues(alpha: 0.1),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: _GlowCircle(
            diameter: 280,
            color: scheme.primary.withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -120,
          child: _GlowCircle(
            diameter: 320,
            color: scheme.tertiary.withValues(alpha: 0.14),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
