import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../models/export_session.dart';
import '../../services/history_service.dart';

class HistoryController extends StateNotifier<List<ExportSession>> {
  HistoryController(this._historyService)
    : super(_historyService.loadSessions());

  final HistoryService _historyService;

  Future<void> addSession(ExportSession session) async {
    final updated = retainHistorySessions(<ExportSession>[session, ...state]);
    state = updated;
    await _historyService.saveSessions(updated);
  }

  Future<void> deleteSession(String sessionId) async {
    final updated = state.where((session) => session.id != sessionId).toList();
    state = updated;
    await _historyService.saveSessions(updated);
  }

  Future<void> refresh() async {
    state = _historyService.loadSessions();
  }
}

final historyControllerProvider =
    StateNotifierProvider<HistoryController, List<ExportSession>>((ref) {
      return HistoryController(ref.watch(historyServiceProvider));
    });
