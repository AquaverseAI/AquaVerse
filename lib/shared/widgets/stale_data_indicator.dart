import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// StaleDataIndicator — shows when cached data is older than a threshold.
///
/// Displays the timestamp of the last successful sync and offers a
/// pull-to-refresh CTA. Distinct from StalenessBadge (which is a simple
/// text badge). This widget includes a human-readable age and a button.
///
/// Typically placed at the top of a data list or at the bottom of a card.
class StaleDataIndicator extends StatelessWidget {
  /// When the data was last successfully synced.
  final DateTime lastSyncedAt;

  /// Tap callback — typically triggers a refresh/refetch.
  final VoidCallback? onRefresh;

  /// Threshold after which data is considered stale.
  /// Defaults to 4 hours.
  final Duration staleThreshold;

  const StaleDataIndicator({
    super.key,
    required this.lastSyncedAt,
    this.onRefresh,
    this.staleThreshold = const Duration(hours: 4),
  });

  bool get _isStale =>
      DateTime.now().difference(lastSyncedAt) > staleThreshold;

  String _formatAge() {
    final age = DateTime.now().difference(lastSyncedAt);
    if (age.inMinutes < 1) return 'just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStale) return const SizedBox.shrink();

    return Semantics(
      label: 'Data may be outdated. Last updated ${_formatAge()}.',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.warningSurface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.warningBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: AppIconSize.sm,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Data last updated ${_formatAge()} — may be outdated',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                button: true,
                label: 'Refresh data',
                child: InkWell(
                  onTap: onRefresh,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: AppIconSize.md,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

