import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/export_job.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';
import 'settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final cacheSizeAsync = ref.watch(cacheSizeProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Settings',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Tune defaults, storage, and privacy.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.tune_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  SegmentedButton<ThemeMode>(
                    selected: <ThemeMode>{settings.themeMode},
                    segments: const <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('System'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                      ),
                    ],
                    onSelectionChanged: (selection) {
                      controller.setThemeMode(selection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Defaults',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SegmentedButton<ExportTargetFormat>(
                    selected: <ExportTargetFormat>{settings.defaultFormat},
                    segments: ExportTargetFormat.values
                        .map(
                          (value) => ButtonSegment<ExportTargetFormat>(
                            value: value,
                            label: Text(exportFormatLabel(value)),
                          ),
                        )
                        .toList(),
                    onSelectionChanged: (selection) {
                      controller.setDefaultFormat(selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Default JPG quality',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Text('${settings.defaultJpgQuality}'),
                    ],
                  ),
                  Slider(
                    value: settings.defaultJpgQuality.toDouble(),
                    min: AppLimits.minJpgQuality.toDouble(),
                    max: AppLimits.maxJpgQuality.toDouble(),
                    divisions:
                        AppLimits.maxJpgQuality - AppLimits.minJpgQuality,
                    label: '${settings.defaultJpgQuality}',
                    onChanged: (value) =>
                        controller.setDefaultJpgQuality(value.round()),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: settings.keepTemporaryFiles,
                    onChanged: controller.setKeepTemporaryFiles,
                    title: const Text('Keep temporary files'),
                    subtitle: const Text(
                      'Off by default. Helps with debugging, uses more storage.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Storage',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  cacheSizeAsync.when(
                    data: (size) => Text('Cache usage: ${formatBytes(size)}'),
                    loading: () => const Text('Cache usage: calculating...'),
                    error: (error, stackTrace) =>
                        const Text('Cache usage unavailable'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await controller.clearCache();
                        ref.invalidate(cacheSizeProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cache cleared.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: const Text('Clear cache'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy'),
              subtitle: const Text('Learn how local processing works.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/privacy'),
            ),
          ),
        ],
      ),
    );
  }
}
