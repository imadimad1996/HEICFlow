import 'package:flutter/foundation.dart';

enum MediaItemStatus {
  idle,
  queued,
  processing,
  done,
  error,
  canceled,
  unsupported,
}

@immutable
class MediaItem {
  const MediaItem({
    required this.id,
    required this.originalPath,
    required this.displayName,
    required this.ext,
    required this.bytesSize,
    required this.width,
    required this.height,
    required this.createdAt,
    required this.thumbPath,
    required this.status,
    required this.errorMessage,
  });

  final String id;
  final String originalPath;
  final String displayName;
  final String ext;
  final int bytesSize;
  final int? width;
  final int? height;
  final DateTime? createdAt;
  final String? thumbPath;
  final MediaItemStatus status;
  final String? errorMessage;

  bool get isSupported => status != MediaItemStatus.unsupported;

  MediaItem copyWith({
    String? id,
    String? originalPath,
    String? displayName,
    String? ext,
    int? bytesSize,
    int? width,
    int? height,
    DateTime? createdAt,
    String? thumbPath,
    MediaItemStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearThumbPath = false,
  }) {
    return MediaItem(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      displayName: displayName ?? this.displayName,
      ext: ext ?? this.ext,
      bytesSize: bytesSize ?? this.bytesSize,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      thumbPath: clearThumbPath ? null : (thumbPath ?? this.thumbPath),
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
