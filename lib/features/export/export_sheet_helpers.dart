import 'package:flutter/material.dart';

import 'export_progress_sheet.dart';

Future<void> showExportProgressSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (sheetContext) {
      return ExportProgressSheet(
        onClose: () {
          Navigator.of(sheetContext).pop();
        },
      );
    },
  );
}
