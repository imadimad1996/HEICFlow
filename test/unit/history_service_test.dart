import 'package:flutter_test/flutter_test.dart';

import 'package:heicflow/models/export_job.dart';
import 'package:heicflow/models/export_session.dart';
import 'package:heicflow/services/history_service.dart';

void main() {
  test('retainHistorySessions keeps latest 20 sessions', () {
    final sessions = List<ExportSession>.generate(
      25,
      (index) => ExportSession(
        id: 'session_$index',
        timestamp: DateTime.utc(2026, 1, 1).add(Duration(minutes: index)),
        format: ExportTargetFormat.jpg,
        count: 1,
        outputPaths: <String>['/tmp/out_$index.jpg'],
      ),
    );

    final retained = retainHistorySessions(sessions, limit: 20);

    expect(retained.length, 20);
    expect(retained.first.id, 'session_24');
    expect(retained.last.id, 'session_5');
  });
}
