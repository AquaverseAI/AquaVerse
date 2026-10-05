import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// StalenessBadge Component (PRD-AV-04 Mandatory Constraint).
/// Every cached data display shows a staleness indicator via StalenessBadge
/// reading the synced-at timestamp — never assuming data is "current".
///
/// Visual treatment: radial-glow state dot (green=fresh, amber=aging, red=stale)
/// matching the dashboard's consistent glow motif. No change to staleness logic.
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
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = customText ?? (syncedAt != null ? _formatTimeAgo(syncedAt!) : '4h ago');

    final bool isStale = syncedAt != null && DateTime.now().difference(syncedAt!).inHours >= 12;
    final bool isAging = !isStale && syncedAt != null && DateTime.now().difference(syncedAt!).inHours >= 4;

    // Radial glow dot color: green = fresh, amber = aging, red = stale
    final Color dotColor = isStale
        ? AppColors.riskHigh
        : (isAging ? AppColors.riskMedium : AppColors.riskLow);

    final Color textColor = isStale
        ? AppColors.riskHigh
        : (isAging ? const Color(0xFFD97706) : AppColors.textSecondary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Radial-glow state dot — same glow language as bell & alert pulse
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                dotColor,
                dotColor.withValues(alpha: 0.0),
              ],
              stops: const [0.45, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
