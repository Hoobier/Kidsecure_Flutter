import 'package:intl/intl.dart';

/// Centralized date/time formatting for KidSecure parent app screens.
class DateFormatter {
  DateFormatter._();

  /// e.g. "Jul 25, 2026"
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy').format(dateTime.toLocal());
  }

  /// e.g. "7:45 AM"
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime.toLocal());
  }

  /// e.g. "Jul 25, 2026 · 7:45 AM"
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} · ${formatTime(dateTime)}';
  }

  /// Returns "Today", "Yesterday", or a formatted date — used to group logs.
  static String formatDayLabel(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(local.year, local.month, local.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(local);
  }

  /// e.g. "2m ago", "3h ago" — used on the home screen's status card.
  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(dateTime);
  }
}
