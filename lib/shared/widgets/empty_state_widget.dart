import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// EmptyStateWidget — standardized empty state presentation.
///
/// Use when a list, feed, or data view has no items to show.
/// Provides a consistent visual treatment across all screens.
///
/// Variants controlled by [EmptyStateType]:
///   noData        — no items exist yet
///   noNetwork     — connectivity required but unavailable
///   noPermission  — user lacks access
///   searchEmpty   — search returned no results
///   custom        — supply your own icon + strings
class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;

  /// Override the icon for custom variant.
  final IconData? icon;

  /// Primary title. Required.
  final String title;

  /// Optional supporting subtitle/explanation.
  final String? subtitle;

  /// Optional call-to-action button label.
  final String? ctaLabel;

  /// Callback when CTA is tapped.
  final VoidCallback? onCta;

  const EmptyStateWidget({
    super.key,
    this.type = EmptyStateType.noData,
    this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  IconData get _icon {
    if (icon != null) return icon!;
    switch (type) {
      case EmptyStateType.noData:
        return Icons.inbox_outlined;
      case EmptyStateType.noNetwork:
        return Icons.wifi_off_rounded;
      case EmptyStateType.noPermission:
        return Icons.lock_outline_rounded;
      case EmptyStateType.searchEmpty:
        return Icons.search_off_rounded;
      case EmptyStateType.custom:
        return Icons.info_outline_rounded;
    }
  }

  Color get _iconColor {
    switch (type) {
      case EmptyStateType.noNetwork:
        return AppColors.warning;
      case EmptyStateType.noPermission:
        return AppColors.textMuted;
      default:
        return AppColors.primary400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _icon,
                  size: AppIconSize.hero,
                  color: _iconColor,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              if (ctaLabel != null && onCta != null) ...[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: AppTouchTarget.buttonHeight,
                  child: ElevatedButton(
                    onPressed: onCta,
                    child: Text(ctaLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum EmptyStateType { noData, noNetwork, noPermission, searchEmpty, custom }

