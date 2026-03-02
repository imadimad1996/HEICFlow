import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/export_session.dart';
import '../utils/constants.dart';

class HistoryService {
  HistoryService(this._prefs);

  final SharedPreferences _prefs;

  static const String _historyKey = 'heicflow_history_v1';

  List<ExportSession> loadSessions() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return const <ExportSession>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const <ExportSession>[];
      }

      final sessions = <ExportSession>[];
      for (final entry in decoded) {
        if (entry is! Map<dynamic, dynamic>) {
          continue;
        }
        try {
          sessions.add(ExportSession.fromJson(entry.cast<String, dynamic>()));
        } catch (_) {
          // Ignore malformed session entries to keep history loading resilient.
        }
      }
      return retainHistorySessions(sessions, limit: AppLimits.historyRetention);
    } catch (_) {
      return const <ExportSession>[];
    }
  }

  Future<void> saveSessions(List<ExportSession> sessions) async {
    final retained = retainHistorySessions(
      sessions,
      limit: AppLimits.historyRetention,
    );
    final encoded = jsonEncode(
      retained.map((session) => session.toJson()).toList(),
    );
    await _prefs.setString(_historyKey, encoded);
  }
}

List<ExportSession> retainHistorySessions(
  List<ExportSession> sessions, {
  int limit = AppLimits.historyRetention,
}) {
  final sorted = List<ExportSession>.from(sessions)
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  if (sorted.length <= limit) {
    return sorted;
  }
  return sorted.take(limit).toList();
}
