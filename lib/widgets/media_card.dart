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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outlineVariant.withValues(alpha: 0.22),
            width: selected ? 1.6 : 1,
          ),
        ),
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
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.58),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.xs,
                top: AppSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.46),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    mediaStatusLabel(item.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (selectionMode)
                Positioned(
                  right: AppSpacing.xs,
                  top: AppSpacing.xs,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? colorScheme.primary
                          : Colors.black.withValues(alpha: 0.42),
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
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
