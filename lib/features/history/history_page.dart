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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'History',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
                          child: ListTile(
                            title: Text(title),
                            subtitle: Text(formatDateTime(session.timestamp)),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) async {
                                if (action == 'share') {
                                  await _reshare(context, ref, session);
                                } else if (action == 'open') {
                                  await _openLocation(context, session);
                                } else if (action == 'delete') {
                                  await ref
                                      .read(historyControllerProvider.notifier)
                                      .deleteSession(session.id);
                                }
                              },
                              itemBuilder: (context) =>
                                  const <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'share',
                                      child: Text('Re-share'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'open',
                                      child: Text('Open location'),
                                    ),
                                    PopupMenuDivider(),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('Delete entry'),
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
