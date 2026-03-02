import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../models/export_session.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';
import '../../widgets/empty_state.dart';
import 'history_controller.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  Future<void> _reshare(
    BuildContext context,
    WidgetRef ref,
    ExportSession session,
  ) async {
    try {
      await ref
          .read(exportServiceProvider)
          .shareOutputs(
            outputPaths: session.outputPaths,
            zipPath: session.zipPath,
          );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $error')));
    }
  }

  Future<void> _openLocation(
    BuildContext context,
    ExportSession session,
  ) async {
    final path =
        session.zipPath ??
        (session.outputPaths.isNotEmpty ? session.outputPaths.first : null);
    if (path == null || !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Output file not found on device.')),
      );
      return;
    }

    final uri = Uri.file(path);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening location is not supported on this device.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(historyControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Column(
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
                            'History',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${sessions.length} recent export sessions',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.history_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: sessions.isEmpty
                  ? const EmptyState(
                      icon: Icons.history_toggle_off,
                      title: 'No exports yet',
                      message: 'Your last 20 export sessions will appear here.',
                    )
                  : ListView.separated(
                      itemCount: sessions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final title =
                            '${exportFormatLabel(session.format)} · ${session.count} file(s)';

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        formatDateTime(session.timestamp),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Wrap(
                                        spacing: AppSpacing.xs,
                                        runSpacing: AppSpacing.xs,
                                        children: <Widget>[
                                          ActionChip(
                                            avatar: const Icon(
                                              Icons.ios_share,
                                              size: 16,
                                            ),
                                            label: const Text('Re-share'),
                                            onPressed: () async =>
                                                _reshare(context, ref, session),
                                          ),
                                          ActionChip(
                                            avatar: const Icon(
                                              Icons.folder_open_rounded,
                                              size: 16,
                                            ),
                                            label: const Text('Open'),
                                            onPressed: () async =>
                                                _openLocation(context, session),
                                          ),
                                          ActionChip(
                                            avatar: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16,
                                            ),
                                            label: const Text('Delete'),
                                            onPressed: () async {
                                              await ref
                                                  .read(
                                                    historyControllerProvider
                                                        .notifier,
                                                  )
                                                  .deleteSession(session.id);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
