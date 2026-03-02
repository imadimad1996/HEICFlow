import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../features/export/export_controller.dart';
import '../../features/export/export_options_sheet.dart';
import '../../features/export/export_sheet_helpers.dart';
import '../../features/media/media_controller.dart';
import '../../features/settings/settings_controller.dart';
import '../../models/export_job.dart';
import '../../models/media_item.dart';
import '../../utils/constants.dart';
import '../../utils/file_utils.dart';
import '../../utils/format_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pulse_placeholder.dart';

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  Future<void> _pickFiles() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Web file conversion is not supported in this build. Use Android or iOS.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final beforeCount = ref.read(mediaControllerProvider).items.length;

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: false,
        withReadStream: true,
      );

      if (result == null) {
        return;
      }

      final paths = await _resolvePickedPaths(result);
      if (!mounted) {
        return;
      }

      if (paths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No readable files were selected. Try picking from Files and retry.',
            ),
          ),
        );
        return;
      }

      await ref.read(mediaControllerProvider.notifier).importPaths(paths);
      if (!mounted) {
        return;
      }

      final afterCount = ref.read(mediaControllerProvider).items.length;
      if (afterCount == beforeCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No files were added to the queue. The selected files may be inaccessible.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File import failed: $error')));
    }
  }

  Future<List<String>> _resolvePickedPaths(FilePickerResult result) async {
    final resolved = <String>[];
    final tempDir = await ensureTempDirectory();

    for (var index = 0; index < result.files.length; index++) {
      try {
        final picked = result.files[index];
        final path = picked.path;

        if (path != null && path.isNotEmpty) {
          resolved.add(path);
          continue;
        }

        final stream = picked.readStream;
        if (stream != null) {
          final tempPath = _tempImportPath(tempDir.path, picked.name, index);
          final file = File(tempPath);
          await file.create(recursive: true);
          final sink = file.openWrite();
          try {
            await sink.addStream(stream);
          } finally {
            await sink.close();
          }

          if (file.existsSync()) {
            resolved.add(tempPath);
            continue;
          }
        }

        final bytes = picked.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          final tempPath = _tempImportPath(tempDir.path, picked.name, index);
          final file = File(tempPath);
          await file.writeAsBytes(bytes, flush: true);
          if (file.existsSync()) {
            resolved.add(tempPath);
          }
        }
      } catch (_) {
        // Skip files that cannot be materialized to a local path.
      }
    }

    return resolved;
  }

  String _tempImportPath(String dirPath, String originalName, int index) {
    final baseNameRaw = p.basenameWithoutExtension(originalName);
    final safeBase = sanitizeFileName(baseNameRaw).replaceAll(
      RegExp(r'^_+|_+$'),
      '',
    );
    final ext = extensionFromPath(originalName);

    final fallbackBase = safeBase.isEmpty ? 'imported' : safeBase;
    final fallbackExt = ext.isEmpty ? 'bin' : ext;
    final fileName =
        '${fallbackBase}_${DateTime.now().microsecondsSinceEpoch}_$index.$fallbackExt';

    return uniquePathInDirectory(Directory(dirPath), fileName);
  }

  Future<void> _showExportOptions() async {
    final media = ref.read(mediaControllerProvider);
    if (media.selectedIds.isEmpty) {
      return;
    }

    final settings = ref.read(settingsControllerProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ExportOptionsSheet(
          initialFormat: settings.defaultFormat,
          initialJpgQuality: settings.defaultJpgQuality,
          initialPdfMode: PdfMode.combined,
          selectedCount: media.selectedIds.length,
          onConfirm: (format, quality, pdfMode) {
            Navigator.of(sheetContext).pop();
            unawaited(
              ref
                  .read(exportControllerProvider.notifier)
                  .startExport(
                    selectedIds: media.selectedIds.toList(),
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

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaControllerProvider);
    final exportState = ref.watch(exportControllerProvider);
    final mediaController = ref.read(mediaControllerProvider.notifier);

    final hasSelection = mediaState.selectedIds.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Theme.of(context).colorScheme.surfaceContainerLowest,
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppBrand.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          AppBrand.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: mediaState.isImporting ? null : _pickFiles,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Import'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: mediaState.items.isEmpty
                          ? null
                          : mediaController.selectAllSupported,
                      icon: const Icon(Icons.select_all),
                      label: const Text('Select all'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: mediaState.items.isEmpty
                          ? null
                          : () async {
                              await mediaController.clearAll();
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear queue'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: mediaState.items.isEmpty
                      ? EmptyState(
                          icon: Icons.photo_library_outlined,
                          title: 'Drop HEICs here',
                          message:
                              'Pick files from iPhone Photos or Files. Everything stays local on your device.',
                          action: FilledButton(
                            onPressed: _pickFiles,
                            child: const Text('Pick files'),
                          ),
                        )
                      : ListView.separated(
                          itemCount: mediaState.items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) {
                            final item = mediaState.items[index];
                            final selected = mediaState.selectedIds.contains(
                              item.id,
                            );
                            return _ImportQueueTile(
                              item: item,
                              selected: selected,
                              onTap: item.isSupported
                                  ? () {
                                      mediaController.toggleSelection(item.id);
                                    }
                                  : null,
                              onDelete: () async {
                                await mediaController.removeItem(item.id);
                              },
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: hasSelection && !exportState.isRunning
                      ? _showExportOptions
                      : null,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(
                    hasSelection
                        ? 'Convert ${mediaState.selectedIds.length} selected'
                        : 'Select files to convert',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportQueueTile extends StatelessWidget {
  const _ImportQueueTile({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final MediaItem item;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imagePath =
        item.thumbPath ??
        ((item.ext == 'jpg' || item.ext == 'jpeg' || item.ext == 'png')
            ? item.originalPath
            : null);

    return Card(
      child: ListTile(
        onTap: onTap,
        minTileHeight: 64,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox.square(
            dimension: 52,
            child: imagePath == null
                ? const PulsePlaceholder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  )
                : Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    cacheWidth: 120,
                    errorBuilder: (context, error, stackTrace) =>
                        const PulsePlaceholder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                  ),
          ),
        ),
        title: Text(
          item.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${formatBytes(item.bytesSize)} · ${mediaStatusLabel(item.status)}${item.errorMessage == null ? '' : ' · ${item.errorMessage}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (item.isSupported)
              Checkbox(value: selected, onChanged: (checked) => onTap?.call()),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close),
              tooltip: 'Remove file',
            ),
          ],
        ),
      ),
    );
  }
}
