import 'package:flutter/material.dart';

/// AquaVerse Design Token: Spacing
///
/// Use these named constants everywhere instead of hardcoded pixel values.
/// This ensures consistent layout across all screens and makes global
/// spacing adjustments trivial.
abstract class AppSpacing {
  /// 4dp — micro gap; icon-to-label, badge inner padding
  static const double xs = 4.0;

  /// 8dp — small gap; between related items, compact list rows
  static const double sm = 8.0;

  /// 12dp — medium gap; within card content, between stacked labels
  static const double md = 12.0;

  /// 16dp — large gap; page horizontal margin, card padding
  static const double lg = 16.0;

  /// 24dp — extra-large gap; between card groups, section separators
  static const double xl = 24.0;

  /// 32dp — 2x-large gap; major section breaks
  static const double xxl = 32.0;

  /// 40dp — section gap; between page-level content zones
  static const double section = 40.0;

  // ── Convenience EdgeInsets factories ──────────────────────────────────────

  /// Horizontal page margins: lg (16) on both sides
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: lg);

  /// Standard card inner padding
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// Compact card inner padding
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(md);

  /// Vertical list spacing between cards
  static const SizedBox cardGap = SizedBox(height: md);

  /// Vertical spacing between sections
  static const SizedBox sectionGap = SizedBox(height: xl);
}

/// AquaVerse Design Token: Border Radius
abstract class AppRadius {
  /// 4dp — subtle rounding; tags, chips, compact labels
  static const double xs = 4.0;

  /// 8dp — small rounding; input fields (matches AppTheme.inputRadius)
  static const double sm = 8.0;

  /// 12dp — medium rounding; secondary buttons, small cards
  static const double md = 12.0;

  /// 14dp — button radius (matches AppTheme.buttonRadius)
  static const double button = 14.0;

  /// 16dp — card radius (matches AppTheme.cardRadius)
  static const double card = 16.0;

  /// 20dp — large radius; bottom sheets, panels
  static const double lg = 20.0;

  /// 100dp — pill/full-round; tags, FABs, toggle pills
  static const double pill = 100.0;

  // Convenience BorderRadius objects
  static BorderRadius get xsBorderRadius =>
      BorderRadius.circular(xs);
  static BorderRadius get smBorderRadius =>
      BorderRadius.circular(sm);
  static BorderRadius get mdBorderRadius =>
      BorderRadius.circular(md);
  static BorderRadius get cardBorderRadius =>
      BorderRadius.circular(card);
  static BorderRadius get buttonBorderRadius =>
      BorderRadius.circular(button);
  static BorderRadius get pillBorderRadius =>
      BorderRadius.circular(pill);
}

/// AquaVerse Design Token: Elevation / Shadow
abstract class AppShadow {
  /// No shadow — flat elements, disabled states
  static const List<BoxShadow> none = [];

  /// Tier 1 — standard card lift
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x1A0E9488), // shadowTier1: ~10% primary accent
      blurRadius: 14,
      offset: Offset(0, 3),
    ),
  ];

  /// Tier 2 — elevated panels, dialogs
  static const List<BoxShadow> panel = [
    BoxShadow(
      color: Color(0x2E0E9488), // shadowTier2: ~18% primary accent
      blurRadius: 24,
      offset: Offset(0, 6),
    ),
  ];

  /// Tier 3 — floating action, FAB-style buttons
  static const List<BoxShadow> fab = [
    BoxShadow(
      color: Color(0x400E9488),
      blurRadius: 32,
      offset: Offset(0, 10),
    ),
  ];

  /// Bottom navigation bar — upward shadow
  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x14153B56), // mountain900 ~8%
      blurRadius: 12,
      offset: Offset(0, -2),
    ),
  ];
}

/// AquaVerse Design Token: Icon Sizes
abstract class AppIconSize {
  /// 14dp — inline badge icons
  static const double xs = 14.0;

  /// 16dp — compact action icons
  static const double sm = 16.0;

  /// 20dp — default icon size (matches iconTheme)
  static const double md = 20.0;

  /// 24dp — primary action icons
  static const double lg = 24.0;

  /// 28dp — feature icons, nav active states
  static const double xl = 28.0;

  /// 32dp — hero icons, empty states
  static const double xxl = 32.0;

  /// 48dp — illustration-scale icons
  static const double hero = 48.0;
}

/// AquaVerse Design Token: Touch Targets
///
/// Per WCAG 2.5.5 and platform guidelines:
/// - Android minimum: 48dp
/// - iOS minimum: 44pt
/// - AquaVerse standard: 48dp (meets both)
abstract class AppTouchTarget {
  /// Minimum interactive area height/width for all tappable elements
  static const double minimum = 48.0;

  /// Standard button height (matches AppTheme.buttonHeight)
  static const double buttonHeight = 48.0;

  /// Compact interactive height (use sparingly; only for secondary actions)
  static const double compact = 44.0;
}

