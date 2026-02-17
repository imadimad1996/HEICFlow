class FittedRect {
  const FittedRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;
}

FittedRect fitRectIntoPage({
  required double sourceWidth,
  required double sourceHeight,
  required double pageWidth,
  required double pageHeight,
}) {
  if (sourceWidth <= 0 || sourceHeight <= 0) {
    return FittedRect(x: 0, y: 0, width: pageWidth, height: pageHeight);
  }

  final sourceRatio = sourceWidth / sourceHeight;
  final pageRatio = pageWidth / pageHeight;

  late final double targetWidth;
  late final double targetHeight;

  if (sourceRatio > pageRatio) {
    targetWidth = pageWidth;
    targetHeight = pageWidth / sourceRatio;
  } else {
    targetHeight = pageHeight;
    targetWidth = pageHeight * sourceRatio;
  }

  final x = (pageWidth - targetWidth) / 2;
  final y = (pageHeight - targetHeight) / 2;

  return FittedRect(x: x, y: y, width: targetWidth, height: targetHeight);
}
