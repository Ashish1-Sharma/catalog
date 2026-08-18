class AppDateUtils {
  /// Computes trial/subscription days remaining from validity string (YYYY-MM-DD)
  static int getDaysRemaining(String? validityDateStr) {
    if (validityDateStr == null || validityDateStr.isEmpty) return 0;
    try {
      final validityDate = DateTime.parse(validityDateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(validityDate.year, validityDate.month, validityDate.day);
      final diff = target.difference(today).inDays;
      return diff < 0 ? 0 : diff;
    } catch (_) {
      return 0;
    }
  }

  static String formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}
