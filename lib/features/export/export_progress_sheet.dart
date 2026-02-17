import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/export_job.dart';
import '../../utils/constants.dart';
import 'export_controller.dart';

class ExportProgressSheet extends ConsumerWidget {
  const ExportProgressSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exportControllerProvider);
    final controller = ref.read(exportControllerProvider.notifier);
    final job = state.activeJob;

    if (job == null) {
      return const SizedBox.shrink();
    }

    final isRunning = job.state == ExportJobState.running;
    final progress = job.progress.clamp(0.0, 1.0);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isRunning ? 'Processing conversion' : 'Export status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              job.currentFilename ?? 'Preparing files...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: isRunning ? progress : 1),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${(progress * 100).round()}% · ${job.remaining ?? 0} remaining',
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isRunning)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.cancelActiveJob,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                ),
              )
            else ...<Widget>[
              Text(exportCompletionMessage(state)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: state.outputPaths.isEmpty
                          ? null
                          : () async {
                              await controller.shareLatestOutputs();
                            },
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Share / Save'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        controller.resetState();
                        onClose();
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
