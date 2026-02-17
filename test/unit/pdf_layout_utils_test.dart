import 'package:flutter_test/flutter_test.dart';

import 'package:heicflow/utils/pdf_layout_utils.dart';

void main() {
  group('fitRectIntoPage', () {
    test('fits landscape image within portrait page', () {
      final rect = fitRectIntoPage(
        sourceWidth: 4000,
        sourceHeight: 2000,
        pageWidth: 600,
        pageHeight: 800,
      );

      expect(rect.width, 600);
      expect(rect.height, 300);
      expect(rect.x, 0);
      expect(rect.y, 250);
    });

    test('fits portrait image within portrait page', () {
      final rect = fitRectIntoPage(
        sourceWidth: 1000,
        sourceHeight: 2000,
        pageWidth: 600,
        pageHeight: 800,
      );

      expect(rect.height, 800);
      expect(rect.width, 400);
      expect(rect.x, 100);
      expect(rect.y, 0);
    });
  });
}
