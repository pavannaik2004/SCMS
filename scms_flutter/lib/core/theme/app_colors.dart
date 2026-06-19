import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary Brand Colors ─────────────────────────────────
  // Indigo/violet identity (refreshed from the original blue/teal).
  static const Color primary = Color(0xFF4F46E5); // indigo-600
  static const Color primaryLight = Color(0xFF818CF8); // indigo-400
  static const Color primaryDark = Color(0xFF3730A3); // indigo-800

  // ─── Accent ───────────────────────────────────────────────
  static const Color accent = Color(0xFF8B5CF6); // violet-500

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

  // ─── Glass / surface tokens ───────────────────────────────
  // Frosted-glass surfaces are built with BackdropFilter + these translucent
  // fills/borders. Keep dense text on solid surfaces; glass is for chrome,
  // cards over the gradient backdrop, and hero panels.
  static const Color glassFillLight = Color(0x99FFFFFF); // ~60% white
  static const Color glassFillDark = Color(0x401F2937); // ~25% dark surface
  static const Color glassBorderLight = Color(0x4DFFFFFF); // ~30% white
  static const Color glassBorderDark = Color(0x33FFFFFF); // ~20% white
  static const double glassBlurSigma = 18.0;

  // ─── Brand surfaces (solid) ───────────────────────────────
  // Premium look uses SOLID brand fills — no gradients on screen.
  // A slightly deeper indigo is available for subtle layering (e.g. a darker
  // hero footer or pressed state) without ever blending two hues.
  static const Color primarySurface = primary; // indigo-600 header/hero fill
  static const Color primaryDeep = Color(0xFF4338CA); // indigo-700

  /// Soft full-screen backdrop behind glass surfaces (light theme).
  /// Kept as a [LinearGradient] for API stability, but flattened to a single
  /// tone so nothing renders as a gradient.
  static const LinearGradient backdropLight = LinearGradient(
    colors: [Color(0xFFF6F7FB), Color(0xFFF6F7FB)],
  );

  /// Soft full-screen backdrop behind glass surfaces (dark theme), flattened.
  static const LinearGradient backdropDark = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF111827)],
  );

  // ─── Legacy gradient tokens (deprecated, unused on screen) ────────────────
  // Retained only so any stray reference still compiles. Do not use for new
  // surfaces — the app is solid + frosted-glass, no gradient fills.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accent],
  );

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
