class FullScreenAdGuard {
  bool _isShowing = false;
  DateTime? _lastDismissedAt;

  bool tryAcquire() {
    if (_isShowing) {
      return false;
    }
    _isShowing = true;
    return true;
  }

  void release() {
    _isShowing = false;
    _lastDismissedAt = DateTime.now();
  }

  bool get isShowing => _isShowing;

  bool recentlyDismissed(Duration duration) {
    final lastDismissedAt = _lastDismissedAt;
    if (lastDismissedAt == null) {
      return false;
    }
    return DateTime.now().difference(lastDismissedAt) < duration;
  }
}
