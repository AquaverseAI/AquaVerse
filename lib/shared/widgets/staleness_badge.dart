import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// StalenessBadge Component (PRD-AV-04 Mandatory Constraint).
/// Every cached data display shows a staleness indicator via StalenessBadge
/// reading the synced-at timestamp — never assuming data is "current".
class StalenessBadge extends StatelessWidget {
  final DateTime? syncedAt;
  final String? customText;

  const StalenessBadge({
    super.key,
    this.syncedAt,
    this.customText,
  });

  String _formatTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Data synced just now';
    } else if (difference.inMinutes < 60) {
      return 'Data as of ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Data as of ${difference.inHours}h ago';
    } else {
      return 'Data as of ${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = customText ?? (syncedAt != null ? _formatTimeAgo(syncedAt!) : 'Data as of 4h ago');
    final isStale = syncedAt != null && DateTime.now().difference(syncedAt!).inHours >= 12;

    final color = isStale ? AppColors.warning : AppColors.textSecondary;
    final bgColor = isStale ? AppColors.warningSurface : AppColors.surface;
    final borderColor = isStale ? AppColors.warningBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
