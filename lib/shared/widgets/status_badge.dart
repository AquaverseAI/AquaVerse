import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Severity levels used across alerts, ponds, and risk indicators.
enum StatusLevel { ok, low, medium, high, critical, unknown }

/// StatusBadge — compact severity chip.
///
/// Use on alert cards, pond cards, officer panels, and any place a
/// qualitative severity label is needed. Never shows bare numerals.
///
/// Variants:
///   StatusLevel.ok       → teal   "Good"
///   StatusLevel.low      → teal   "Low Risk"
///   StatusLevel.medium   → amber  "Medium Risk"
///   StatusLevel.high     → red    "High Risk"
///   StatusLevel.critical → red    "Critical"
///   StatusLevel.unknown  → grey   "Unknown"
class StatusBadge extends StatelessWidget {
  final StatusLevel level;

  /// Override the display label. If null, the default English label is used.
  final String? label;

  /// Show the severity dot prefix. Defaults to true.
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.level,
    this.label,
    this.showDot = true,
  });

  // ── Semantics ─────────────────────────────────────────────────────────────

  Color get _bgColor {
    switch (level) {
      case StatusLevel.ok:
        return AppColors.green100;
      case StatusLevel.low:
        return AppColors.green100;
      case StatusLevel.medium:
        return AppColors.warningSurface;
      case StatusLevel.high:
        return AppColors.criticalSurface;
      case StatusLevel.critical:
        return AppColors.criticalSurface;
      case StatusLevel.unknown:
        return AppColors.surfaceSoft;
    }
  }

  Color get _borderColor {
    switch (level) {
      case StatusLevel.ok:
        return AppColors.green200;
      case StatusLevel.low:
        return AppColors.green200;
      case StatusLevel.medium:
        return AppColors.warningBorder;
      case StatusLevel.high:
        return AppColors.criticalBorder;
      case StatusLevel.critical:
        return AppColors.criticalBorder;
      case StatusLevel.unknown:
        return AppColors.border;
    }
  }

  Color get _textColor {
    switch (level) {
      case StatusLevel.ok:
        return AppColors.green700;
      case StatusLevel.low:
        return AppColors.green700;
      case StatusLevel.medium:
        return const Color(0xFFB45309); // amber-700
      case StatusLevel.high:
        return AppColors.critical;
      case StatusLevel.critical:
        return AppColors.critical;
      case StatusLevel.unknown:
        return AppColors.textMuted;
    }
  }

  String get _defaultLabel {
    switch (level) {
      case StatusLevel.ok:
        return 'Good';
      case StatusLevel.low:
        return 'Low Risk';
      case StatusLevel.medium:
        return 'Medium Risk';
      case StatusLevel.high:
        return 'High Risk';
      case StatusLevel.critical:
        return 'Critical';
      case StatusLevel.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayLabel = label ?? _defaultLabel;

    return Semantics(
      label: 'Status: $displayLabel',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: _borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _textColor,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _textColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

