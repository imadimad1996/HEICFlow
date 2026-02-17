import 'package:flutter/material.dart';

import '../../models/export_job.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';

class ExportOptionsSheet extends StatefulWidget {
  const ExportOptionsSheet({
    super.key,
    required this.initialFormat,
    required this.initialJpgQuality,
    required this.initialPdfMode,
    required this.selectedCount,
    required this.onConfirm,
  });

  final ExportTargetFormat initialFormat;
  final int initialJpgQuality;
  final PdfMode initialPdfMode;
  final int selectedCount;
  final void Function(ExportTargetFormat format, int quality, PdfMode pdfMode)
  onConfirm;

  @override
  State<ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends State<ExportOptionsSheet> {
  late ExportTargetFormat _format = widget.initialFormat;
  late int _quality = widget.initialJpgQuality;
  late PdfMode _pdfMode = widget.initialPdfMode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Export ${widget.selectedCount} item(s)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Format', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<ExportTargetFormat>(
              selected: <ExportTargetFormat>{_format},
              segments: ExportTargetFormat.values
                  .map(
                    (value) => ButtonSegment<ExportTargetFormat>(
                      value: value,
                      label: Text(exportFormatLabel(value)),
                    ),
                  )
                  .toList(),
              onSelectionChanged: (selected) {
                setState(() {
                  _format = selected.first;
                });
              },
            ),
            if (_format == ExportTargetFormat.jpg) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'JPG quality',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text('$_quality'),
                ],
              ),
              Slider(
                value: _quality.toDouble(),
                min: AppLimits.minJpgQuality.toDouble(),
                max: AppLimits.maxJpgQuality.toDouble(),
                divisions: AppLimits.maxJpgQuality - AppLimits.minJpgQuality,
                label: '$_quality',
                onChanged: (value) {
                  setState(() {
                    _quality = value.round();
                  });
                },
              ),
            ],
            if (_format == ExportTargetFormat.pdf) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text('PDF mode', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<PdfMode>(
                selected: <PdfMode>{_pdfMode},
                segments: const <ButtonSegment<PdfMode>>[
                  ButtonSegment<PdfMode>(
                    value: PdfMode.combined,
                    label: Text('Combined'),
                  ),
                  ButtonSegment<PdfMode>(
                    value: PdfMode.separate,
                    label: Text('Separate'),
                  ),
                ],
                onSelectionChanged: (selection) {
                  setState(() {
                    _pdfMode = selection.first;
                  });
                },
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => widget.onConfirm(_format, _quality, _pdfMode),
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Start export'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
