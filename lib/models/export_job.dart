import 'dart:async';

import 'package:flutter/foundation.dart';

enum ExportTargetFormat { jpg, png, pdf }

enum PdfMode { combined, separate }

enum ExportJobState { idle, running, completed, canceled, error }

class CancelToken {
  bool _isCanceled = false;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  bool get isCanceled => _isCanceled;
  Stream<void> get onCancel => _controller.stream;

  void cancel() {
    if (_isCanceled) {
      return;
    }
    _isCanceled = true;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

@immutable
class ExportJob {
  const ExportJob({
    required this.jobId,
    required this.targetFormat,
    required this.quality,
    required this.pdfMode,
    required this.selectedIds,
    required this.state,
    required this.progress,
    required this.cancelToken,
    required this.currentFilename,
    required this.remaining,
    required this.errorMessage,
  });

  final String jobId;
  final ExportTargetFormat targetFormat;
  final int? quality;
  final PdfMode? pdfMode;
  final List<String> selectedIds;
  final ExportJobState state;
  final double progress;
  final CancelToken cancelToken;
  final String? currentFilename;
  final int? remaining;
  final String? errorMessage;

  ExportJob copyWith({
    String? jobId,
    ExportTargetFormat? targetFormat,
    int? quality,
    PdfMode? pdfMode,
    List<String>? selectedIds,
    ExportJobState? state,
    double? progress,
    CancelToken? cancelToken,
    String? currentFilename,
    int? remaining,
    String? errorMessage,
    bool clearCurrentFilename = false,
    bool clearError = false,
  }) {
    return ExportJob(
      jobId: jobId ?? this.jobId,
      targetFormat: targetFormat ?? this.targetFormat,
      quality: quality ?? this.quality,
      pdfMode: pdfMode ?? this.pdfMode,
      selectedIds: selectedIds ?? this.selectedIds,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      cancelToken: cancelToken ?? this.cancelToken,
      currentFilename: clearCurrentFilename
          ? null
          : (currentFilename ?? this.currentFilename),
      remaining: remaining ?? this.remaining,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
