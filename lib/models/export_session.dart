import 'package:flutter/foundation.dart';

import 'export_job.dart';

@immutable
class ExportSession {
  const ExportSession({
    required this.id,
    required this.timestamp,
    required this.format,
    required this.count,
    required this.outputPaths,
    this.zipPath,
  });

  final String id;
  final DateTime timestamp;
  final ExportTargetFormat format;
  final int count;
  final List<String> outputPaths;
  final String? zipPath;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'format': format.name,
      'count': count,
      'outputPaths': outputPaths,
      'zipPath': zipPath,
    };
  }

  factory ExportSession.fromJson(Map<String, dynamic> json) {
    final formatName = json['format'] as String? ?? 'jpg';
    final format = ExportTargetFormat.values.firstWhere(
      (element) => element.name == formatName,
      orElse: () => ExportTargetFormat.jpg,
    );

    return ExportSession(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      format: format,
      count: json['count'] as int,
      outputPaths: (json['outputPaths'] as List<dynamic>).cast<String>(),
      zipPath: json['zipPath'] as String?,
    );
  }
}
