import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/gallery/gallery_page.dart';
import '../features/gallery/viewer_page.dart';
import '../features/history/history_page.dart';
import '../features/import/import_page.dart';
import '../features/settings/privacy_page.dart';
import '../features/settings/settings_page.dart';
import 'app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/import',
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.uri.toString(), child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/import',
            name: 'import',
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: ImportPage()),
          ),
          GoRoute(
            path: '/gallery',
            name: 'gallery',
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: GalleryPage()),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: HistoryPage()),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: SettingsPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/viewer/:id',
        name: 'viewer',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ViewerPage(initialId: id);
        },
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyPage(),
      ),
    ],
  );
});
