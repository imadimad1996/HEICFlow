import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../app/providers.dart';
import '../../models/export_job.dart';
import '../../models/export_session.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';
import '../history/history_controller.dart';
import '../media/media_controller.dart';
import '../settings/settings_controller.dart';

class ExportQueueState {
  const ExportQueueState({
    required this.activeJob,
    required this.outputPaths,
    required this.zipPath,
    required this.errorMessage,
  });

  final ExportJob? activeJob;
  final List<String> outputPaths;
  final String? zipPath;
  final String? errorMessage;

  bool get isRunning => activeJob?.state == ExportJobState.running;
  bool get isCompleted => activeJob?.state == ExportJobState.completed;
  bool get isCanceled => activeJob?.state == ExportJobState.canceled;
  bool get hasError => activeJob?.state == ExportJobState.error;

  ExportQueueState copyWith({
    ExportJob? activeJob,
    List<String>? outputPaths,
    String? zipPath,
    String? errorMessage,
    bool clearZipPath = false,
    bool clearErrorMessage = false,
  }) {
    return ExportQueueState(
      activeJob: activeJob ?? this.activeJob,
      outputPaths: outputPaths ?? this.outputPaths,
      zipPath: clearZipPath ? null : (zipPath ?? this.zipPath),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  static const ExportQueueState initial = ExportQueueState(
    activeJob: null,
    outputPaths: <String>[],
    zipPath: null,
    errorMessage: null,
  );
}

class ExportController extends StateNotifier<ExportQueueState> {
  ExportController(this._ref) : super(ExportQueueState.initial);

  final Ref _ref;

  Future<void> startExport({
    required List<String> selectedIds,
    required ExportTargetFormat targetFormat,
    int? quality,
    PdfMode pdfMode = PdfMode.combined,
  }) async {
    if (state.isRunning) {
      return;
    }

    final mediaNotifier = _ref.read(mediaControllerProvider.notifier);
    final selectedItems = mediaNotifier
        .findItemsByIds(selectedIds)
        .where((item) => item.isSupported)
        .toList(growable: false);

    if (selectedItems.isEmpty) {
      return;
    }

    unawaited(_ref.read(interstitialAdServiceProvider).initializeAndPreload());

    final settings = _ref.read(settingsControllerProvider);
    final exportService = _ref.read(exportServiceProvider);
    final now = DateTime.now();

    final cancelToken = CancelToken();
    final job = ExportJob(
      jobId: 'job_${now.microsecondsSinceEpoch}',
      targetFormat: targetFormat,
      quality: quality ?? settings.defaultJpgQuality,
      pdfMode: targetFormat == ExportTargetFormat.pdf ? pdfMode : null,
      selectedIds: selectedItems.map((item) => item.id).toList(),
      state: ExportJobState.running,
      progress: 0,
      cancelToken: cancelToken,
      currentFilename: null,
      remaining: selectedItems.length,
      errorMessage: null,
    );

    state = ExportQueueState(
      activeJob: job,
      outputPaths: const <String>[],
      zipPath: null,
      errorMessage: null,
    );

    final result = await exportService.processJob(
      job: job,
      items: selectedItems,
      jpgQuality: (quality ?? settings.defaultJpgQuality).clamp(
        AppLimits.minJpgQuality,
        AppLimits.maxJpgQuality,
      ),
      pdfMode: pdfMode,
      keepTemporaryFiles: settings.keepTemporaryFiles,
      onItemStatus: (itemId, status, {errorMessage}) {
        mediaNotifier.updateStatus(itemId, status, errorMessage: errorMessage);
      },
      onProgress: (update) {
        final current = state.activeJob;
        if (current == null) {
          return;
        }

        state = state.copyWith(
          activeJob: current.copyWith(
            progress: update.percent,
            currentFilename: update.currentFilename,
            remaining: update.remaining,
          ),
        );
      },
    );

    if (cancelToken.isCanceled || result.canceled) {
      final current = state.activeJob;
      if (current != null) {
        state = state.copyWith(
          activeJob: current.copyWith(
            state: ExportJobState.canceled,
            progress: current.progress,
          ),
          outputPaths: result.outputPaths,
          zipPath: result.zipPath,
          clearErrorMessage: true,
        );
      }
      return;
    }

    if (result.errorMessage != null) {
      final current = state.activeJob;
      if (current != null) {
        state = state.copyWith(
          activeJob: current.copyWith(
            state: ExportJobState.error,
            errorMessage: result.errorMessage,
          ),
          outputPaths: result.outputPaths,
          zipPath: result.zipPath,
          errorMessage: result.errorMessage,
        );
      }
      return;
    }

    final current = state.activeJob;
    if (current != null) {
      state = state.copyWith(
        activeJob: current.copyWith(
          state: ExportJobState.completed,
          progress: 1,
          remaining: 0,
          clearError: true,
        ),
        outputPaths: result.outputPaths,
        zipPath: result.zipPath,
        clearErrorMessage: true,
      );
    }

    if (result.outputPaths.isNotEmpty) {
      _ref.read(interstitialAdServiceProvider).markCompletedExportEligible();

      final session = ExportSession(
        id: 'session_${now.microsecondsSinceEpoch}',
        timestamp: now,
        format: targetFormat,
        count: result.outputPaths.length,
        outputPaths: result.outputPaths,
        zipPath: result.zipPath,
      );

      await _ref.read(historyControllerProvider.notifier).addSession(session);
    }
  }

  void cancelActiveJob() {
    final activeJob = state.activeJob;
    if (activeJob == null || activeJob.state != ExportJobState.running) {
      return;
    }
    activeJob.cancelToken.cancel();
    state = state.copyWith(
      activeJob: activeJob.copyWith(state: ExportJobState.canceled),
    );
  }

  Future<void> shareLatestOutputs() async {
    if (state.outputPaths.isEmpty) {
      return;
    }
    await _ref
        .read(exportServiceProvider)
        .shareOutputs(outputPaths: state.outputPaths, zipPath: state.zipPath);
  }

  void resetState() {
    final job = state.activeJob;
    if (job != null) {
      job.cancelToken.dispose();
    }
    state = ExportQueueState.initial;
  }

  @visibleForTesting
  void seedForTesting(ExportQueueState seeded) {
    state = seeded;
  }
}

final exportControllerProvider =
    StateNotifierProvider<ExportController, ExportQueueState>((ref) {
      return ExportController(ref);
    });

final exportSelectionCountProvider = Provider<int>((ref) {
  return ref.watch(
    mediaControllerProvider.select((value) => value.selectedIds.length),
  );
});

String exportCompletionMessage(ExportQueueState state) {
  final job = state.activeJob;
  if (job == null) {
    return '';
  }

  if (state.hasError) {
    return state.errorMessage ?? 'Export failed.';
  }
  if (state.isCanceled) {
    return 'Export canceled.';
  }
  if (state.isCompleted) {
    final format = exportFormatLabel(job.targetFormat);
    return '${state.outputPaths.length} $format file(s) ready.';
  }
  return 'Export in progress...';
}
