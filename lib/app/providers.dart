import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/conversion_service.dart';
import '../services/export_service.dart';
import '../services/history_service.dart';
import '../services/pdf_service.dart';
import '../services/thumbnail_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main().',
  );
});

final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 4,
      lineLength: 100,
      colors: false,
      printEmojis: false,
      noBoxingByDefault: true,
    ),
  );
});

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService(ref.watch(sharedPreferencesProvider));
});

final conversionServiceProvider = Provider<ConversionService>((ref) {
  return ConversionService(ref.watch(loggerProvider));
});

final thumbnailServiceProvider = Provider<ThumbnailService>((ref) {
  return ThumbnailService(ref.watch(loggerProvider));
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    ref.watch(conversionServiceProvider),
    ref.watch(pdfServiceProvider),
    ref.watch(loggerProvider),
  );
});
