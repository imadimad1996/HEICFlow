import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../models/media_item.dart';
import '../../services/thumbnail_service.dart';
import '../../utils/format_utils.dart';

class MediaState {
  const MediaState({
    required this.items,
    required this.selectedIds,
    required this.selectionMode,
    required this.isImporting,
  });

  final List<MediaItem> items;
  final Set<String> selectedIds;
  final bool selectionMode;
  final bool isImporting;

  List<MediaItem> get selectedItems =>
      items.where((item) => selectedIds.contains(item.id)).toList();

  MediaState copyWith({
    List<MediaItem>? items,
    Set<String>? selectedIds,
    bool? selectionMode,
    bool? isImporting,
  }) {
    return MediaState(
      items: items ?? this.items,
      selectedIds: selectedIds ?? this.selectedIds,
      selectionMode: selectionMode ?? this.selectionMode,
      isImporting: isImporting ?? this.isImporting,
    );
  }

  static const MediaState initial = MediaState(
    items: <MediaItem>[],
    selectedIds: <String>{},
    selectionMode: false,
    isImporting: false,
  );
}

class MediaController extends StateNotifier<MediaState> {
  MediaController(this._thumbnailService, this._logger)
    : super(MediaState.initial);

  final ThumbnailService _thumbnailService;
  final Logger _logger;

  Future<void> importPaths(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }

    state = state.copyWith(isImporting: true);

    final freshItems = <MediaItem>[];
    final now = DateTime.now().microsecondsSinceEpoch;

    for (var index = 0; index < paths.length; index++) {
      final path = paths[index];
      final file = File(path);
      if (!file.existsSync()) {
        continue;
      }

      final stat = file.statSync();
      final ext = extensionFromPath(path);
      final supported = isSupportedInputPath(path);
      final id = '${now}_${index}_$ext';

      final item = MediaItem(
        id: id,
        originalPath: path,
        displayName: p.basename(path),
        ext: ext,
        bytesSize: stat.size,
        width: null,
        height: null,
        createdAt: stat.modified,
        thumbPath: null,
        status: supported ? MediaItemStatus.idle : MediaItemStatus.unsupported,
        errorMessage: supported ? null : 'Unsupported file format',
      );
      freshItems.add(item);
    }

    state = state.copyWith(
      items: <MediaItem>[...state.items, ...freshItems],
      isImporting: false,
    );

    for (final item in freshItems) {
      if (!item.isSupported) {
        continue;
      }
      unawaited(_hydrateMetadata(item));
    }
  }

  Future<void> _hydrateMetadata(MediaItem item) async {
    try {
      final dimensions = await _thumbnailService.probeDimensions(
        item.originalPath,
      );
      final thumb = await _thumbnailService.ensureThumbnail(item);

      _updateItem(
        item.id,
        (current) => current.copyWith(
          width: dimensions?.width,
          height: dimensions?.height,
          thumbPath: thumb,
        ),
      );
    } catch (error, stackTrace) {
      _logger.w(
        'Failed to hydrate media metadata',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void setSelectionMode(bool value) {
    state = state.copyWith(selectionMode: value);
    if (!value) {
      clearSelection();
    }
  }

  void toggleSelection(String id) {
    final next = Set<String>.from(state.selectedIds);
    if (!next.add(id)) {
      next.remove(id);
    }
    state = state.copyWith(selectedIds: next);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: <String>{});
  }

  void selectAllSupported() {
    final ids = state.items
        .where((item) => item.isSupported)
        .map((item) => item.id)
        .toSet();
    state = state.copyWith(selectedIds: ids);
  }

  void updateStatus(String id, MediaItemStatus status, {String? errorMessage}) {
    _updateItem(
      id,
      (current) => current.copyWith(
        status: status,
        errorMessage: errorMessage,
        clearErrorMessage: errorMessage == null,
      ),
    );
  }

  Future<void> removeItem(String id) async {
    final item = state.items.firstWhere(
      (candidate) => candidate.id == id,
      orElse: () => throw StateError('Item $id not found'),
    );
    await _thumbnailService.deleteThumbnail(item.thumbPath);

    final nextItems = state.items.where((entry) => entry.id != id).toList();
    final nextSelected = Set<String>.from(state.selectedIds)..remove(id);
    state = state.copyWith(items: nextItems, selectedIds: nextSelected);
  }

  Future<void> clearAll() async {
    final currentItems = state.items;
    for (final item in currentItems) {
      await _thumbnailService.deleteThumbnail(item.thumbPath);
    }

    state = MediaState.initial;
  }

  List<MediaItem> findItemsByIds(List<String> ids) {
    final lookup = <String, MediaItem>{
      for (final item in state.items) item.id: item,
    };
    final resolved = <MediaItem>[];
    for (final id in ids) {
      final item = lookup[id];
      if (item != null) {
        resolved.add(item);
      }
    }
    return resolved;
  }

  void _updateItem(String id, MediaItem Function(MediaItem current) transform) {
    final next = state.items.map((item) {
      if (item.id != id) {
        return item;
      }
      return transform(item);
    }).toList();

    state = state.copyWith(items: next);
  }

  @visibleForTesting
  void seedForTesting(MediaState seeded) {
    state = seeded;
  }
}

final mediaControllerProvider =
    StateNotifierProvider<MediaController, MediaState>((ref) {
      return MediaController(
        ref.watch(thumbnailServiceProvider),
        ref.watch(loggerProvider),
      );
    });
