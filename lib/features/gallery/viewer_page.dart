import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/media/media_controller.dart';
import '../../models/media_item.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';
import '../../widgets/inline_native_ad.dart';

class ViewerPage extends ConsumerStatefulWidget {
  const ViewerPage({super.key, required this.initialId});

  final String initialId;

  @override
  ConsumerState<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends ConsumerState<ViewerPage> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _initialPageApplied = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref
        .watch(mediaControllerProvider)
        .items
        .where((item) => item.isSupported)
        .toList(growable: false);

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No images available.')),
      );
    }

    final initialIndex = items.indexWhere(
      (item) => item.id == widget.initialId,
    );
    final safeInitial = initialIndex < 0 ? 0 : initialIndex;

    if (!_initialPageApplied) {
      _initialPageApplied = true;
      _currentIndex = safeInitial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _pageController.jumpToPage(safeInitial);
      });
    }

    final current = items[_currentIndex.clamp(0, items.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        title: Text(
          '${_currentIndex + 1} of ${items.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (value) {
                setState(() {
                  _currentIndex = value;
                });
              },
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final imagePath =
                    item.thumbPath ??
                    ((item.ext == 'jpg' ||
                            item.ext == 'jpeg' ||
                            item.ext == 'png')
                        ? item.originalPath
                        : null);

                if (imagePath == null) {
                  return const Center(
                    child: Text(
                      'Preview unavailable for this file.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return Hero(
                  tag: 'media_${item.id}',
                  child: _ZoomableImage(imagePath: imagePath),
                );
              },
            ),
          ),
          _MetadataPanel(item: current),
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: InlineNativeAd(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.imagePath});

  final String imagePath;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  late final TransformationController _controller = TransformationController();
  bool _zoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    setState(() {
      _zoomed = !_zoomed;
      _controller.value = _zoomed
          ? Matrix4.diagonal3Values(2.4, 2.4, 1)
          : Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 4,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text(
                  'Unable to render image',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MetadataPanel extends StatelessWidget {
  const _MetadataPanel({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            item.displayName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              _ViewerChip(label: 'Type', value: item.ext.toUpperCase()),
              _ViewerChip(label: 'Size', value: formatBytes(item.bytesSize)),
              _ViewerChip(
                label: 'Dimensions',
                value: item.width == null || item.height == null
                    ? 'Unknown'
                    : '${item.width} × ${item.height}',
              ),
              _ViewerChip(
                label: 'Date',
                value: item.createdAt == null
                    ? 'Unknown'
                    : formatDateTime(item.createdAt!),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewerChip extends StatelessWidget {
  const _ViewerChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.86),
        ),
      ),
    );
  }
}
