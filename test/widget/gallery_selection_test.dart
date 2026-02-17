import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:heicflow/features/gallery/gallery_page.dart';
import 'package:heicflow/features/media/media_controller.dart';
import 'package:heicflow/models/media_item.dart';
import 'package:heicflow/services/thumbnail_service.dart';

class _TestMediaController extends MediaController {
  _TestMediaController() : super(ThumbnailService(Logger()), Logger());

  void seed(MediaState value) {
    seedForTesting(value);
  }
}

void main() {
  testWidgets('gallery allows selecting a card in checkbox mode', (
    tester,
  ) async {
    final controller = _TestMediaController();
    controller.seed(
      MediaState.initial.copyWith(
        selectionMode: true,
        items: const <MediaItem>[
          MediaItem(
            id: 'one',
            originalPath: '/tmp/one.jpg',
            displayName: 'one.jpg',
            ext: 'jpg',
            bytesSize: 1024,
            width: 800,
            height: 600,
            createdAt: null,
            thumbPath: null,
            status: MediaItemStatus.idle,
            errorMessage: null,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          mediaControllerProvider.overrideWith((ref) => controller),
        ],
        child: const MaterialApp(home: GalleryPage()),
      ),
    );

    await tester.tap(find.text('one.jpg'));
    await tester.pump();

    expect(controller.state.selectedIds.contains('one'), isTrue);
  });
}
