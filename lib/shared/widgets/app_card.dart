import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

enum CardType { standard, info, healthy, critical }

/// Standard app card implemented strictly against AquaVerse_AI_Design_System.md
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final CardType type;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.type = CardType.standard,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;

    switch (type) {
      case CardType.info:
        bgColor = AppColors.surfaceAqua;
        borderColor = AppColors.border;
        break;
      case CardType.healthy:
        bgColor = AppColors.surfaceGreen;
        borderColor = AppColors.green200;
        break;
      case CardType.critical:
        bgColor = AppColors.criticalSurface;
        borderColor = AppColors.criticalBorder;
        break;
      case CardType.standard:
        bgColor = AppColors.surface;
        borderColor = AppColors.border;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: type == CardType.standard
            ? [
                BoxShadow(
                  color: AppColors.mountain900.withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
    );
  }
}

/// A small stat chip — label + value in a pastel pill.
class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c),
          ),
        ],
      ),
    );
  }
}

/// Section header with optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary700,
              ),
            ),
          ),
      ],
    );
  }
}

/// Risk level bar — Low / Medium / High Risk qualitative display only.
class RiskLevelBar extends StatelessWidget {
  final String level; // 'low' | 'medium' | 'high'

  const RiskLevelBar({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    double fillFraction;

    switch (level.toLowerCase()) {
      case 'high':
      case 'critical':
        color = AppColors.critical;
        label = 'High Risk';
        fillFraction = 0.85;
        break;
      case 'medium':
      case 'attention':
        color = AppColors.warning;
        label = 'Medium Risk';
        fillFraction = 0.5;
        break;
      default:
        color = AppColors.green600;
        label = 'Low Risk';
        fillFraction = 0.2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Risk Level', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: fillFraction,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
