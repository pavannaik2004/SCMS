import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// Returns a relative time string like "2 hours ago", "Yesterday", etc.
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    } else if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return '$w ${w == 1 ? 'week' : 'weeks'} ago';
    } else {
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }

  /// Returns a full formatted date string, e.g. "15 Jun 2024, 10:30 AM"
  static String formatFull(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  /// Returns SLA display string, e.g. "14h 32m remaining" or "SLA Breached"
  static String formatSla(DateTime? deadline) {
    if (deadline == null) return 'No SLA set';

    final now = DateTime.now();
    final diff = deadline.difference(now);

    if (diff.isNegative) {
      final overdue = now.difference(deadline);
      final hours = overdue.inHours;
      final minutes = overdue.inMinutes.remainder(60);
      return 'Overdue by ${hours}h ${minutes}m';
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    return '${hours}h ${minutes}m remaining';
  }

  /// Returns the SLA progress ratio (0.0 = just started, 1.0+ = breached)
  static double slaProgressRatio(DateTime createdAt, DateTime? deadline) {
    if (deadline == null) return 0.0;
    final totalDuration = deadline.difference(createdAt);
    final elapsed = DateTime.now().difference(createdAt);
    if (totalDuration.inSeconds == 0) return 1.0;
    return elapsed.inSeconds / totalDuration.inSeconds;
  }

  /// Returns greeting based on current time
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
