import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heicflow/features/export/export_controller.dart';
import 'package:heicflow/features/export/export_progress_sheet.dart';
import 'package:heicflow/models/export_job.dart';

void main() {
  testWidgets('progress sheet shows progress and supports cancel', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          exportControllerProvider.overrideWith((ref) {
            final controller = ExportController(ref);
            controller.seedForTesting(
              ExportQueueState(
                activeJob: ExportJob(
                  jobId: 'job_1',
                  targetFormat: ExportTargetFormat.jpg,
                  quality: 92,
                  pdfMode: null,
                  selectedIds: const <String>['a', 'b'],
                  state: ExportJobState.running,
                  progress: 0.4,
                  cancelToken: CancelToken(),
                  currentFilename: 'a.heic',
                  remaining: 1,
                  errorMessage: null,
                ),
                outputPaths: const <String>[],
                zipPath: null,
                errorMessage: null,
              ),
            );
            return controller;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(body: ExportProgressSheet(onClose: () {})),
        ),
      ),
    );

    expect(find.text('Processing conversion'), findsOneWidget);
    expect(find.textContaining('40%'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ExportProgressSheet)),
    );
    final state = container.read(exportControllerProvider);
    expect(state.activeJob?.state, ExportJobState.canceled);
  });
}
