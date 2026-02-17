import 'dart:io';

import 'package:archive/archive.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../models/export_job.dart';
import '../models/media_item.dart';
import '../utils/file_utils.dart';
import '../utils/format_utils.dart';
import '../utils/isolate_utils.dart';
import 'conversion_service.dart';
import 'pdf_service.dart';

class ExportProgressUpdate {
  const ExportProgressUpdate({
    required this.currentFilename,
    required this.processed,
    required this.total,
  });

  final String currentFilename;
  final int processed;
  final int total;

  int get remaining => (total - processed).clamp(0, total);
  double get percent => total == 0 ? 0 : processed / total;
}

class ExportResult {
  const ExportResult({
    required this.outputPaths,
    this.zipPath,
    this.errorMessage,
    this.canceled = false,
  });

  final List<String> outputPaths;
  final String? zipPath;
  final String? errorMessage;
  final bool canceled;
}

typedef ItemStatusCallback =
    void Function(
      String itemId,
      MediaItemStatus status, {
      String? errorMessage,
    });

typedef ProgressCallback = void Function(ExportProgressUpdate update);

class ExportService {
  ExportService(this._conversionService, this._pdfService, this._logger);

  final ConversionService _conversionService;
  final PdfService _pdfService;
  final Logger _logger;

  Future<ExportResult> processJob({
    required ExportJob job,
    required List<MediaItem> items,
    required int jpgQuality,
    required PdfMode pdfMode,
    required bool keepTemporaryFiles,
    required ItemStatusCallback onItemStatus,
    required ProgressCallback onProgress,
  }) async {
    final outputDir = await ensureOutputDirectory();
    final tempDir = await ensureTempDirectory();
    final temporaryArtifacts = <String>[];
    final outputFiles = <String>[];
    final now = DateTime.now();

    var processed = 0;

    for (final item in items) {
      if (item.isSupported) {
        onItemStatus(item.id, MediaItemStatus.queued);
      }
    }

    try {
      if (job.targetFormat == ExportTargetFormat.pdf &&
          pdfMode == PdfMode.combined) {
        final preparedPaths = <String>[];
        final preparedItemIds = <String>[];

        for (var index = 0; index < items.length; index++) {
          final item = items[index];
          if (!item.isSupported) {
            processed++;
            onProgress(
              ExportProgressUpdate(
                currentFilename: item.displayName,
                processed: processed,
                total: items.length,
              ),
            );
            continue;
          }

          if (job.cancelToken.isCanceled) {
            _markRemainingCanceled(items, index, onItemStatus);
            return ExportResult(outputPaths: outputFiles, canceled: true);
          }

          onItemStatus(item.id, MediaItemStatus.processing);
          try {
            final prepared = await _conversionService.prepareForPdf(
              sourcePath: item.originalPath,
              workingDirectory: tempDir.path,
            );
            preparedPaths.add(prepared.path);
            preparedItemIds.add(item.id);
            if (prepared.isTemporary) {
              temporaryArtifacts.add(prepared.path);
            }
          } catch (error, stackTrace) {
            _logger.w(
              'PDF preparation failed',
              error: error,
              stackTrace: stackTrace,
            );
            onItemStatus(
              item.id,
              MediaItemStatus.error,
              errorMessage: 'Could not prepare image for PDF.',
            );
          }

          processed++;
          onProgress(
            ExportProgressUpdate(
              currentFilename: item.displayName,
              processed: processed,
              total: items.length,
            ),
          );
        }

        if (job.cancelToken.isCanceled) {
          return ExportResult(outputPaths: outputFiles, canceled: true);
        }

        if (preparedPaths.isEmpty) {
          return const ExportResult(
            outputPaths: <String>[],
            errorMessage: 'No valid images were available for PDF export.',
          );
        }

        final fileName = generateOutputFileName(
          originalName: 'heicflow_batch',
          timestamp: now,
          extension: 'pdf',
        );
        final outputPath = uniquePathInDirectory(outputDir, fileName);

        await _pdfService.createCombinedPdf(
          imagePaths: preparedPaths,
          outputPath: outputPath,
        );

        outputFiles.add(outputPath);
        for (final id in preparedItemIds) {
          onItemStatus(id, MediaItemStatus.done);
        }
      } else if (job.targetFormat == ExportTargetFormat.pdf &&
          pdfMode == PdfMode.separate) {
        for (var index = 0; index < items.length; index++) {
          final item = items[index];
          if (!item.isSupported) {
            processed++;
            onProgress(
              ExportProgressUpdate(
                currentFilename: item.displayName,
                processed: processed,
                total: items.length,
              ),
            );
            continue;
          }

          if (job.cancelToken.isCanceled) {
            _markRemainingCanceled(items, index, onItemStatus);
            return ExportResult(outputPaths: outputFiles, canceled: true);
          }

          onItemStatus(item.id, MediaItemStatus.processing);
          try {
            final prepared = await _conversionService.prepareForPdf(
              sourcePath: item.originalPath,
              workingDirectory: tempDir.path,
            );
            if (prepared.isTemporary) {
              temporaryArtifacts.add(prepared.path);
            }

            final outputName = generateOutputFileName(
              originalName: item.displayName,
              timestamp: now,
              extension: 'pdf',
              suffixIndex: index,
            );
            final outputPath = uniquePathInDirectory(outputDir, outputName);
            await _pdfService.createSinglePdf(
              imagePath: prepared.path,
              outputPath: outputPath,
            );
            outputFiles.add(outputPath);
            onItemStatus(item.id, MediaItemStatus.done);
          } catch (error, stackTrace) {
            _logger.w(
              'Per-image PDF generation failed',
              error: error,
              stackTrace: stackTrace,
            );
            onItemStatus(
              item.id,
              MediaItemStatus.error,
              errorMessage: 'Could not generate PDF for this file.',
            );
          }

          processed++;
          onProgress(
            ExportProgressUpdate(
              currentFilename: item.displayName,
              processed: processed,
              total: items.length,
            ),
          );
        }
      } else {
        for (var index = 0; index < items.length; index++) {
          final item = items[index];
          if (!item.isSupported) {
            processed++;
            onProgress(
              ExportProgressUpdate(
                currentFilename: item.displayName,
                processed: processed,
                total: items.length,
              ),
            );
            continue;
          }

          if (job.cancelToken.isCanceled) {
            _markRemainingCanceled(items, index, onItemStatus);
            return ExportResult(outputPaths: outputFiles, canceled: true);
          }

          onItemStatus(item.id, MediaItemStatus.processing);
          try {
            final ext = exportFormatExtension(job.targetFormat);
            final outputName = generateOutputFileName(
              originalName: item.displayName,
              timestamp: now,
              extension: ext,
              suffixIndex: index,
            );
            final outputPath = uniquePathInDirectory(outputDir, outputName);
            final converted = await _conversionService.convertToImage(
              sourcePath: item.originalPath,
              outputPath: outputPath,
              targetFormat: job.targetFormat,
              quality: jpgQuality,
            );
            outputFiles.add(converted);
            onItemStatus(item.id, MediaItemStatus.done);
          } catch (error, stackTrace) {
            _logger.w(
              'Image export failed',
              error: error,
              stackTrace: stackTrace,
            );
            onItemStatus(
              item.id,
              MediaItemStatus.error,
              errorMessage: 'Could not export this file.',
            );
          }

          processed++;
          onProgress(
            ExportProgressUpdate(
              currentFilename: item.displayName,
              processed: processed,
              total: items.length,
            ),
          );
        }
      }

      String? zipPath;
      if (outputFiles.length > 1) {
        final zipName = generateOutputFileName(
          originalName: 'heicflow_bundle',
          timestamp: now,
          extension: 'zip',
        );
        final outputZipPath = uniquePathInDirectory(outputDir, zipName);
        zipPath = await createZipBundle(
          inputPaths: outputFiles,
          outputPath: outputZipPath,
        );
      }

      return ExportResult(outputPaths: outputFiles, zipPath: zipPath);
    } catch (error, stackTrace) {
      _logger.e('Export job failed', error: error, stackTrace: stackTrace);
      return ExportResult(
        outputPaths: outputFiles,
        errorMessage: 'Export failed: ${error.toString()}',
      );
    } finally {
      if (!keepTemporaryFiles) {
        for (final artifact in temporaryArtifacts) {
          await safeDeleteFile(artifact);
        }
      }
    }
  }

  Future<void> shareOutputs({
    required List<String> outputPaths,
    String? zipPath,
  }) async {
    if (outputPaths.isEmpty) {
      return;
    }

    final files = outputPaths.map(XFile.new).toList();

    if (files.length == 1) {
      await SharePlus.instance.share(
        ShareParams(files: files, text: 'Converted with HEICFlow'),
      );
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(files: files, text: 'Converted with HEICFlow'),
      );
    } catch (_) {
      if (zipPath != null && File(zipPath).existsSync()) {
        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[XFile(zipPath)],
            text: 'HEICFlow export bundle',
          ),
        );
      }
    }
  }

  Future<String> createZipBundle({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    await runInBackground(() {
      _createZipSync(inputPaths: inputPaths, outputPath: outputPath);
    });

    return outputPath;
  }
}

void _createZipSync({
  required List<String> inputPaths,
  required String outputPath,
}) {
  final archive = Archive();

  for (final path in inputPaths) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    final fileStream = InputFileStream(path);
    final archiveFile = ArchiveFile.stream(p.basename(path), fileStream);
    archive.add(archiveFile);
  }

  final encoded = ZipEncoder().encodeBytes(
    archive,
    level: DeflateLevel.bestSpeed,
  );

  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(encoded, flush: true);
}

void _markRemainingCanceled(
  List<MediaItem> items,
  int fromIndex,
  ItemStatusCallback onItemStatus,
) {
  for (var i = fromIndex; i < items.length; i++) {
    final item = items[i];
    if (item.isSupported) {
      onItemStatus(item.id, MediaItemStatus.canceled);
    }
  }
}
