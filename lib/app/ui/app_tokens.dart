import 'package:flutter/material.dart';

/// Central design tokens for Audivance design system.
abstract final class AppColors {
  // Surfaces & Backgrounds
  static const Color canvas = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161C26);
  static const Color surfaceElevated = Color(0xFF1E2634);
  static const Color surfaceSubtle = Color(0xFF111722);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFF222D3E);
  static const Color borderStrong = Color(0xFF334155);
  static const Color divider = Color(0xFF1E293B);

  // Typography & Neutrals
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

  // Brand
  static const Color brand = Color(0xFFD97706); // Warm Amber-Gold
  static const Color brandLight = Color(0xFFF59E0B);
  static const Color brandContainer = Color(0xFF382307);
  static const Color onBrand = Colors.white;

  // Semantics
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);
}

abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

abstract final class AppRadius {
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 14.0;
  static const double pill = 999.0;

  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);

  static const BorderRadius borderSm = BorderRadius.all(radiusSm);
  static const BorderRadius borderMd = BorderRadius.all(radiusMd);
  static const BorderRadius borderLg = BorderRadius.all(radiusLg);
  static const BorderRadius borderPill = BorderRadius.all(
    Radius.circular(pill),
  );
}

abstract final class AppMotion {
  // Durations
  static const Duration durationFast = Duration(milliseconds: 160);
  static const Duration durationStandard = Duration(milliseconds: 250);
  static const Duration durationEntrance = Duration(milliseconds: 320);
  static const Duration staggerStep = Duration(milliseconds: 60);

  // Curves
  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveInOut = Curves.easeInOutCubic;

  // Offsets
  static const Offset offsetEntrance = Offset(0, 12);
  static const Offset offsetSubtle = Offset(0, 6);
}
