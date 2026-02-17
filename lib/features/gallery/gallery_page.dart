import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/export/export_controller.dart';
import '../../features/export/export_options_sheet.dart';
import '../../features/export/export_sheet_helpers.dart';
import '../../features/media/media_controller.dart';
import '../../features/settings/settings_controller.dart';
import '../../models/export_job.dart';
import '../../models/media_item.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/media_card.dart';

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  String? _focusedId;

  Future<void> _openExportSheet(Set<String> selectedIds) async {
    final settings = ref.read(settingsControllerProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ExportOptionsSheet(
          initialFormat: settings.defaultFormat,
          initialJpgQuality: settings.defaultJpgQuality,
          initialPdfMode: PdfMode.combined,
          selectedCount: selectedIds.length,
          onConfirm: (format, quality, pdfMode) {
            Navigator.of(sheetContext).pop();
            unawaited(
              ref
                  .read(exportControllerProvider.notifier)
                  .startExport(
                    selectedIds: selectedIds.toList(),
                    targetFormat: format,
                    quality: quality,
                    pdfMode: pdfMode,
                  ),
            );
            unawaited(showExportProgressSheet(context));
          },
        );
      },
    );
  }

  int _columnsForWidth(double width) {
    if (width < 700) {
      return 2;
    }
    if (width < 1000) {
      return 4;
    }
    if (width < 1300) {
      return 5;
    }
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaControllerProvider);
    final mediaController = ref.read(mediaControllerProvider.notifier);
    final exportState = ref.watch(exportControllerProvider);

    final items = mediaState.items
        .where((item) => item.isSupported)
        .toList(growable: false);
    final selectedIds = mediaState.selectedIds;

    final focusedItem = items.firstWhere(
      (item) => item.id == _focusedId,
      orElse: () => items.isNotEmpty
          ? items.first
          : const MediaItem(
              id: '',
              originalPath: '',
              displayName: '',
              ext: '',
              bytesSize: 0,
              width: null,
              height: null,
              createdAt: null,
              thumbPath: null,
              status: MediaItemStatus.idle,
              errorMessage: null,
            ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Gallery',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: items.isEmpty
                      ? null
                      : () {
                          final next = !mediaState.selectionMode;
                          mediaController.setSelectionMode(next);
                        },
                  icon: Icon(
                    mediaState.selectionMode
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  tooltip: mediaState.selectionMode
                      ? 'Exit selection'
                      : 'Selection mode',
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filledTonal(
                  onPressed: items.isEmpty
                      ? null
                      : mediaController.selectAllSupported,
                  icon: const Icon(Icons.select_all),
                  tooltip: 'Select all',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: Icons.image_not_supported_outlined,
                      title: 'No images yet',
                      message:
                          'Import HEIC/JPG/PNG files to build your gallery.',
                      action: FilledButton(
                        onPressed: () => context.go('/import'),
                        child: const Text('Go to import'),
                      ),
                    );
                  }

                  final useDetailPane = constraints.maxWidth >= 1000;
                  final grid = GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _columnsForWidth(constraints.maxWidth),
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = selectedIds.contains(item.id);
                      return MediaCard(
                        item: item,
                        selected: selected,
                        selectionMode: mediaState.selectionMode,
                        onTap: () {
                          setState(() {
                            _focusedId = item.id;
                          });

                          if (mediaState.selectionMode) {
                            mediaController.toggleSelection(item.id);
                          } else {
                            context.push('/viewer/${item.id}');
                          }
                        },
                        onLongPress: () {
                          setState(() {
                            _focusedId = item.id;
                          });
                          mediaController.setSelectionMode(true);
                          mediaController.toggleSelection(item.id);
                        },
                      );
                    },
                  );

                  if (!useDetailPane) {
                    return grid;
                  }

                  return Row(
                    children: <Widget>[
                      Expanded(flex: 3, child: grid),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _GalleryDetailPane(
                          item: focusedItem.id.isEmpty ? null : focusedItem,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: selectedIds.isEmpty || exportState.isRunning
                    ? null
                    : () => _openExportSheet(selectedIds),
                icon: const Icon(Icons.auto_fix_high),
                label: Text(
                  selectedIds.isEmpty
                      ? 'Select images to convert'
                      : 'Convert ${selectedIds.length} selected',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryDetailPane extends StatelessWidget {
  const _GalleryDetailPane({required this.item});

  final MediaItem? item;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Select an image to see details.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final media = item!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              media.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetadataRow(label: 'Type', value: media.ext.toUpperCase()),
            _MetadataRow(label: 'Size', value: formatBytes(media.bytesSize)),
            _MetadataRow(
              label: 'Dimensions',
              value: media.width == null || media.height == null
                  ? 'Unknown'
                  : '${media.width} × ${media.height}',
            ),
            _MetadataRow(
              label: 'Date',
              value: media.createdAt == null
                  ? 'Unknown'
                  : formatDateTime(media.createdAt!),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tip: long press to enter multi-select mode.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: <Widget>[
          SizedBox(width: 96, child: Text(label)),
          Expanded(
            child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
