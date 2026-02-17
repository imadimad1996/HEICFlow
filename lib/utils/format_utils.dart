import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../models/export_job.dart';
import '../models/media_item.dart';

String normalizeExtension(String value) {
  return value.toLowerCase().replaceAll('.', '').trim();
}

String extensionFromPath(String path) {
  return normalizeExtension(p.extension(path));
}

bool isSupportedInputPath(String path) {
  final ext = extensionFromPath(path);
  return ext == 'heic' ||
      ext == 'heif' ||
      ext == 'jpg' ||
      ext == 'jpeg' ||
      ext == 'png';
}

String formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }

  const units = ['KB', 'MB', 'GB', 'TB'];
  var unitIndex = -1;
  var value = bytes.toDouble();

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final decimals = value < 10 ? 1 : 0;
  return '${value.toStringAsFixed(decimals)} ${units[math.max(0, unitIndex)]}';
}

String formatDateTime(DateTime value) {
  return DateFormat('MMM d, yyyy · h:mm a').format(value.toLocal());
}

String mediaStatusLabel(MediaItemStatus status) {
  switch (status) {
    case MediaItemStatus.idle:
      return 'Ready';
    case MediaItemStatus.queued:
      return 'Queued';
    case MediaItemStatus.processing:
      return 'Processing';
    case MediaItemStatus.done:
      return 'Done';
    case MediaItemStatus.error:
      return 'Error';
    case MediaItemStatus.canceled:
      return 'Canceled';
    case MediaItemStatus.unsupported:
      return 'Unsupported';
  }
}

String exportFormatLabel(ExportTargetFormat format) {
  switch (format) {
    case ExportTargetFormat.jpg:
      return 'JPG';
    case ExportTargetFormat.png:
      return 'PNG';
    case ExportTargetFormat.pdf:
      return 'PDF';
  }
}

String exportFormatExtension(ExportTargetFormat format) {
  switch (format) {
    case ExportTargetFormat.jpg:
      return 'jpg';
    case ExportTargetFormat.png:
      return 'png';
    case ExportTargetFormat.pdf:
      return 'pdf';
  }
}

String pdfModeLabel(PdfMode mode) {
  switch (mode) {
    case PdfMode.combined:
      return 'Single combined PDF';
    case PdfMode.separate:
      return 'One PDF per image';
  }
}
