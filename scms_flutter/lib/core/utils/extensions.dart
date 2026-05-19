import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Extension on String for common transformations
extension StringExtension on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Convert each word's first letter to uppercase
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Convert status string to a human-readable label
  String toStatusLabel() {
    switch (toUpperCase()) {
      case 'OPEN':
        return 'Open';
      case 'PENDING_SR_REVIEW':
        return 'Pending Review';
      case 'ASSIGNED':
        return 'Assigned';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED':
        return 'Resolved ✓';
      case 'CLOSED':
        return 'Closed';
      case 'REJECTED':
        return 'Rejected';
      default:
        return replaceAll('_', ' ').toTitleCase();
    }
  }

  /// Convert status string to corresponding color
  Color toStatusColor() {
    return AppColors.statusColor(this);
  }

  /// Convert severity string to corresponding color
  Color toSeverityColor() {
    return AppColors.severityColor(this);
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}…';
  }
}

/// Extension on DateTime for formatting helpers
extension DateTimeExtension on DateTime {
  /// Returns relative time string
  String get timeAgoString {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'min' : 'mins'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hr' : 'hrs'} ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  /// Whether the date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Whether the date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
}

/// Extension on num for readability
extension NumExtension on num {
  /// Convert to percentage string
  String toPercentString([int decimals = 0]) => '${toStringAsFixed(decimals)}%';

  /// Convert hours to human-readable duration
  String toHoursDuration() {
    if (this < 1) {
      return '${(this * 60).round()} min';
    }
    return '${toStringAsFixed(1)} hrs';
  }
}
