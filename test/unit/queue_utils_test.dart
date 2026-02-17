import 'package:flutter_test/flutter_test.dart';

import 'package:heicflow/utils/queue_utils.dart';

void main() {
  group('canceledQueueIds', () {
    test('returns remaining ids after current index', () {
      final result = canceledQueueIds(
        allIds: <String>['a', 'b', 'c', 'd'],
        lastProcessedIndex: 1,
      );

      expect(result, <String>['c', 'd']);
    });

    test('returns full queue when cancel happens before first item', () {
      final result = canceledQueueIds(
        allIds: <String>['a', 'b', 'c'],
        lastProcessedIndex: -1,
      );

      expect(result, <String>['a', 'b', 'c']);
    });

    test('returns empty when all items already processed', () {
      final result = canceledQueueIds(
        allIds: <String>['a', 'b', 'c'],
        lastProcessedIndex: 5,
      );

      expect(result, isEmpty);
    });
  });
}
