import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── System Palette (Apple) ───────────────────────────────
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemYellow = Color(0xFFFFCC00);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemTeal = Color(0xFF30B0C7);
  static const Color systemIndigo = Color(0xFF5E5CE6);
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemGray = Color(0xFF8E8E93);

  // ─── Primary Brand Colors ─────────────────────────────────
  // Apple system blue identity.
  static const Color primary = Color(0xFF007AFF); // system blue (light)
  static const Color primaryLight = Color(0xFF0A84FF); // system blue (dark mode)
  static const Color primaryDark = Color(0xFF0060DF);

  // ─── Accent ───────────────────────────────────────────────
  static const Color accent = systemIndigo;

  // ─── Status Colors (remapped to system palette) ───────────
  static const Color statusOpen = systemGray;
  static const Color statusPendingSrReview = systemIndigo;
  static const Color statusAssigned = systemBlue;
  static const Color statusInProgress = systemOrange;
  static const Color statusResolved = systemGreen;
  static const Color statusClosed = Color(0xFF636366);
  static const Color statusRejected = systemRed;

  // ─── Severity Colors ──────────────────────────────────────
  static const Color severityHigh = systemRed;
  static const Color severityMedium = systemOrange;
  static const Color severityLow = systemYellow;

  // ─── Neutrals (Light) — iOS grouped model ─────────────────
  static const Color background = Color(0xFFF2F2F7); // systemGroupedBackground
  static const Color groupedBackground = Color(0xFFF2F2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F2F7);
  static const Color border = Color(0xFFC6C6C8);
  static const Color separator = Color(0xFFC6C6C8);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textDisabled = Color(0xFFC7C7CC);

  // ─── Neutrals (Dark) ──────────────────────────────────────
  static const Color backgroundDark = Color(0xFF000000);
  static const Color groupedBackgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2E);
  static const Color borderDark = Color(0xFF38383A);
  static const Color separatorDark = Color(0xFF38383A);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF98989F);

  // ─── AI Confidence Colors ─────────────────────────────────
  static const Color confidenceHigh = systemGreen;
  static const Color confidenceMedium = systemOrange;
  static const Color confidenceLow = systemRed;

  // ─── Glass / surface tokens ───────────────────────────────
  // Blur is retained only for iOS-style chrome (nav bar + tab bar).
  static const Color glassFillLight = Color(0xB3FFFFFF); // ~70% white
  static const Color glassFillDark = Color(0xB31C1C1E); // ~70% dark surface
  static const Color glassBorderLight = Color(0x1A000000);
  static const Color glassBorderDark = Color(0x1AFFFFFF);
  static const double glassBlurSigma = 18.0;

  // ─── Brand surfaces (solid) ───────────────────────────────
  static const Color primarySurface = primary;
  static const Color primaryDeep = primaryDark;

  /// Soft full-screen backdrop (light) — flattened to the grouped background.
  static const LinearGradient backdropLight = LinearGradient(
    colors: [Color(0xFFF2F2F7), Color(0xFFF2F2F7)],
  );

  /// Soft full-screen backdrop (dark) — flattened to the grouped background.
  static const LinearGradient backdropDark = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF000000)],
  );

  // ─── Legacy gradient tokens (deprecated, unused on screen) ────────────────
  // Retained only so any stray reference still compiles. Flat, single-hue.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accent],
  );

  // ─── Helper Methods ───────────────────────────────────────

  /// Translucent tint of [c] for iOS "tinted" buttons/chips/backgrounds.
  static Color fillTinted(Color c, [double opacity = 0.15]) =>
      c.withValues(alpha: opacity);

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
