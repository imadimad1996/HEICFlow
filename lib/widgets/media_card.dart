import 'dart:io';

import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../utils/constants.dart';
import '../utils/format_utils.dart';
import 'pulse_placeholder.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final MediaItem item;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final imagePath =
        item.thumbPath ??
        ((item.ext == 'jpg' || item.ext == 'jpeg' || item.ext == 'png')
            ? item.originalPath
            : null);

    return Semantics(
      button: true,
      label: '${item.displayName} ${mediaStatusLabel(item.status)}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: imagePath == null
                    ? const PulsePlaceholder()
                    : Hero(
                        tag: 'media_${item.id}',
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          cacheWidth: 512,
                          errorBuilder: (context, error, stackTrace) {
                            return const PulsePlaceholder();
                          },
                        ),
                      ),
              ),
              Positioned(
                left: AppSpacing.xs,
                top: AppSpacing.xs,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    key: ValueKey<String>('${item.id}_${item.status.name}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      mediaStatusLabel(item.status),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
              if (selectionMode)
                Positioned(
                  right: AppSpacing.xs,
                  top: AppSpacing.xs,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? colorScheme.primary
                          : Colors.black.withValues(alpha: 0.45),
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: colorScheme.onPrimary,
                          )
                        : null,
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0x00000000), Color(0xAA000000)],
                    ),
                  ),
                  child: Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
