import 'package:flutter_test/flutter_test.dart';

import 'package:heicflow/utils/file_utils.dart';

void main() {
  group('generateOutputFileName', () {
    test('uses deterministic timestamp and extension', () {
      final value = generateOutputFileName(
        originalName: 'IMG 0001.HEIC',
        timestamp: DateTime.utc(2026, 2, 17, 9, 30, 5),
        extension: 'jpg',
      );

      expect(value, 'IMG_0001_converted_20260217_093005.jpg');
    });

    test('adds numeric suffix when provided', () {
      final value = generateOutputFileName(
        originalName: 'Vacation Photo.png',
        timestamp: DateTime.utc(2026, 2, 17, 9, 30, 5),
        extension: 'pdf',
        suffixIndex: 3,
      );

      expect(value, 'Vacation_Photo_converted_20260217_093005_3.pdf');
    });
  });
}
