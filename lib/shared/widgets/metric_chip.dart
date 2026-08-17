import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'staleness_badge.dart';

/// MetricChip — Tier-1 glass card for sensor parameters on the Dashboard.
///
/// Elevation tier: Tier 1 (resting).
/// Shadow: 0 4px 16px rgba(14,148,136,0.10) — palette-tinted, not gray.
/// Glass: frosted backdrop-blur with gradientCardGlass fill.
/// Staleness: delegates to StalenessBadge (radial-glow dot visual).
class MetricChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? unit;
  final DateTime? syncedAt;
  final VoidCallback? onTap;
  final bool isAlert;

  const MetricChip({
    super.key,
    required this.label,
    this.value,
    this.unit,
    this.syncedAt,
    this.onTap,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value ?? '--';
    final Color borderColor = isAlert
        ? AppColors.riskHigh.withValues(alpha: 0.5)
        : AppColors.border;
    final Color valueColor = isAlert ? AppColors.riskHigh : AppColors.textPrimary;
    final LinearGradient cardGradient = isAlert
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.riskHigh.withValues(alpha: 0.08),
              AppColors.criticalSurface,
            ],
          )
        : AppColors.gradientCardGlass;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.0),
              boxShadow: [
                // Tier-1 shadow: palette-tinted seagreen, not gray
                BoxShadow(
                  color: isAlert
                      ? AppColors.riskHigh.withValues(alpha: 0.14)
                      : AppColors.shadowTier1,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isAlert ? AppColors.riskHigh : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 2),
                      Text(
                        unit!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                StalenessBadge(syncedAt: syncedAt),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
