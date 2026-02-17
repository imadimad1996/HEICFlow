import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'constants.dart';

Future<Directory> _baseCacheDirectory() async {
  final cache = await getTemporaryDirectory();
  final root = Directory(p.join(cache.path, AppDirectories.root));
  if (!root.existsSync()) {
    root.createSync(recursive: true);
  }
  return root;
}

Future<Directory> ensureThumbDirectory() async {
  final root = await _baseCacheDirectory();
  final dir = Directory(p.join(root.path, AppDirectories.thumbs));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

Future<Directory> ensureOutputDirectory() async {
  final root = await _baseCacheDirectory();
  final dir = Directory(p.join(root.path, AppDirectories.output));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

Future<Directory> ensureTempDirectory() async {
  final root = await _baseCacheDirectory();
  final dir = Directory(p.join(root.path, AppDirectories.temp));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

Future<int> cacheDirectorySizeBytes() async {
  final root = await _baseCacheDirectory();
  if (!root.existsSync()) {
    return 0;
  }
  return directorySizeBytes(root);
}

int directorySizeBytes(Directory dir) {
  if (!dir.existsSync()) {
    return 0;
  }

  var total = 0;
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is File) {
      total += entity.lengthSync();
    }
  }
  return total;
}

Future<void> clearAppCache() async {
  final root = await _baseCacheDirectory();
  if (!root.existsSync()) {
    return;
  }

  for (final entity in root.listSync()) {
    if (entity is File) {
      entity.deleteSync();
    } else if (entity is Directory) {
      entity.deleteSync(recursive: true);
    }
  }
}

String sanitizeFileName(String input) {
  return input
      .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
}

String generateOutputFileName({
  required String originalName,
  required DateTime timestamp,
  required String extension,
  int suffixIndex = 0,
}) {
  final rawBase = p.basenameWithoutExtension(originalName);
  final base = sanitizeFileName(rawBase).replaceAll(RegExp(r'^_+|_+$'), '');
  final safeBase = base.isEmpty ? 'image' : base;
  final safeExt = extension.toLowerCase().replaceAll('.', '');
  final stamp = DateFormat('yyyyMMdd_HHmmss').format(timestamp.toUtc());
  final suffix = suffixIndex > 0 ? '_$suffixIndex' : '';
  return '${safeBase}_converted_$stamp$suffix.$safeExt';
}

String uniquePathInDirectory(Directory dir, String desiredName) {
  final baseName = p.basenameWithoutExtension(desiredName);
  final ext = p.extension(desiredName);

  var index = 0;
  while (true) {
    final candidateName = index == 0
        ? '$baseName$ext'
        : '${baseName}_$index$ext';
    final candidatePath = p.join(dir.path, candidateName);
    if (!File(candidatePath).existsSync()) {
      return candidatePath;
    }
    index++;
  }
}

Future<void> safeDeleteFile(String path) async {
  final file = File(path);
  if (file.existsSync()) {
    await file.delete();
  }
}
