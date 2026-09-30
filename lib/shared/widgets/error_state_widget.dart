import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// ErrorStateWidget — standardized error state presentation.
///
/// Use when a screen or data feed fails to load. Never exposes raw
/// server error messages or stack traces. Shows a human-readable
/// explanation and a Retry action where appropriate.
class ErrorStateWidget extends StatelessWidget {
  /// Required: human-readable error title.
  final String title;

  /// Optional: additional detail (e.g. "Check your connection and try again.").
  /// Do NOT pass raw exception messages here.
  final String? detail;

  /// If provided, a Retry button is shown.
  final VoidCallback? onRetry;

  /// Optional: override the error icon.
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    required this.title,
    this.detail,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

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
                  color: AppColors.criticalSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.criticalBorder,
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: AppIconSize.hero,
                  color: AppColors.critical,
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
              if (detail != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: AppTouchTarget.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: AppIconSize.md),
                    label: const Text('Try Again'),
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

