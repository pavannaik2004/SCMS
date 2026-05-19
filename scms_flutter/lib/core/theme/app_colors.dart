import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary Brand Colors ─────────────────────────────────
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryLight = Color(0xFF4D7FE0);
  static const Color primaryDark = Color(0xFF1240B0);

  // ─── Accent ───────────────────────────────────────────────
  static const Color accent = Color(0xFF00C896);

  // ─── Status Colors ────────────────────────────────────────
  static const Color statusOpen = Color(0xFF6B7280);
  static const Color statusPendingSrReview = Color(0xFF8B5CF6);
  static const Color statusAssigned = Color(0xFF3B82F6);
  static const Color statusInProgress = Color(0xFFF59E0B);
  static const Color statusResolved = Color(0xFF10B981);
  static const Color statusClosed = Color(0xFF374151);
  static const Color statusRejected = Color(0xFFEF4444);

  // ─── Severity Colors ──────────────────────────────────────
  static const Color severityHigh = Color(0xFFEF4444);
  static const Color severityMedium = Color(0xFFF97316);
  static const Color severityLow = Color(0xFFEAB308);

  // ─── Neutrals (Light) ─────────────────────────────────────
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);

  // ─── Neutrals (Dark) ──────────────────────────────────────
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color surfaceVariantDark = Color(0xFF374151);
  static const Color borderDark = Color(0xFF4B5563);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // ─── AI Confidence Colors ─────────────────────────────────
  static const Color confidenceHigh = Color(0xFF10B981);
  static const Color confidenceMedium = Color(0xFFF59E0B);
  static const Color confidenceLow = Color(0xFFEF4444);

  // ─── Helper Methods ───────────────────────────────────────

  /// Get color for a complaint status string
  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return statusOpen;
      case 'PENDING_SR_REVIEW':
        return statusPendingSrReview;
      case 'ASSIGNED':
        return statusAssigned;
      case 'IN_PROGRESS':
        return statusInProgress;
      case 'RESOLVED':
        return statusResolved;
      case 'CLOSED':
        return statusClosed;
      case 'REJECTED':
        return statusRejected;
      default:
        return statusOpen;
    }
  }

  /// Get color for a severity string
  static Color severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
        return severityHigh;
      case 'MEDIUM':
        return severityMedium;
      case 'LOW':
        return severityLow;
      default:
        return severityMedium;
    }
  }

  /// Get color for AI confidence score
  static Color confidenceColor(double score) {
    if (score >= 0.80) return confidenceHigh;
    if (score >= 0.60) return confidenceMedium;
    return confidenceLow;
  }
}
