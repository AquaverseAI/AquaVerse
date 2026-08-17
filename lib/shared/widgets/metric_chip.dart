import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'staleness_badge.dart';

/// MetricChip Component — Reusable metric card pill for Dashboard & Field Check.
/// Displays sensor reading label, value, unit, alert state, and staleness timestamp.
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
    final borderColor = isAlert ? AppColors.critical : AppColors.border;
    final valueColor = isAlert ? AppColors.critical : AppColors.textPrimary;
    final bgColor = isAlert ? AppColors.criticalSurface : AppColors.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isAlert ? 1.5 : 1.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.mountain900.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            StalenessBadge(syncedAt: syncedAt),
          ],
        ),
      ),
    );
  }
}
