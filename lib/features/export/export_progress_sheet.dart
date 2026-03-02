import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: isRunning ? progress : 1),
            ),
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
                      onPressed: () async {
                        await ref
                            .read(interstitialAdServiceProvider)
                            .showIfEligible(
                              onContinue: () {
                                controller.resetState();
                                onClose();
                              },
                            );
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
