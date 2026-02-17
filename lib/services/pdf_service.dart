import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/isolate_utils.dart';
import '../utils/pdf_layout_utils.dart';

class PdfService {
  Future<String> createCombinedPdf({
    required List<String> imagePaths,
    required String outputPath,
  }) async {
    await runInBackground(() async {
      await _buildCombinedPdf(imagePaths: imagePaths, outputPath: outputPath);
    });
    return outputPath;
  }

  Future<String> createSinglePdf({
    required String imagePath,
    required String outputPath,
  }) async {
    await runInBackground(() async {
      await _buildCombinedPdf(
        imagePaths: <String>[imagePath],
        outputPath: outputPath,
      );
    });
    return outputPath;
  }
}

Future<void> _buildCombinedPdf({
  required List<String> imagePaths,
  required String outputPath,
}) async {
  final document = pw.Document();
  const pageFormat = PdfPageFormat.a4;

  for (final imagePath in imagePaths) {
    final bytes = File(imagePath).readAsBytesSync();
    final memoryImage = pw.MemoryImage(bytes);

    final decoded = img.decodeImage(bytes);
    final fitted = decoded == null
        ? FittedRect(
            x: 0,
            y: 0,
            width: pageFormat.width,
            height: pageFormat.height,
          )
        : fitRectIntoPage(
            sourceWidth: decoded.width.toDouble(),
            sourceHeight: decoded.height.toDouble(),
            pageWidth: pageFormat.width,
            pageHeight: pageFormat.height,
          );

    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (_) {
          return pw.Stack(
            children: <pw.Widget>[
              pw.Positioned(
                left: fitted.x,
                top: fitted.y,
                child: pw.SizedBox(
                  width: fitted.width,
                  height: fitted.height,
                  child: pw.Image(memoryImage, fit: pw.BoxFit.fill),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  final bytes = await document.save();
  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes, flush: true);
}
