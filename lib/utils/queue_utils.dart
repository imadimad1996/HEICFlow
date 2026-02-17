List<String> canceledQueueIds({
  required List<String> allIds,
  required int lastProcessedIndex,
}) {
  if (allIds.isEmpty) {
    return const <String>[];
  }

  final start = (lastProcessedIndex + 1).clamp(0, allIds.length);
  return allIds.sublist(start);
}
