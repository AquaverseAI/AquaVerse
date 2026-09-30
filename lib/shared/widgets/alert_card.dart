import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'status_badge.dart';

/// AlertCard — reusable alert list item.
///
/// Shows severity badge, title, message summary, pond name, timestamp,
/// and optional acknowledgement + feedback controls.
///
/// Suppressed alerts are visually dimmed with an explanation.
/// Acknowledged alerts show a muted ✓ indicator.
class AlertCard extends StatelessWidget {
  final AlertItem alert;

  /// Called when the user taps the card body (navigate to alert detail).
  final VoidCallback? onTap;

  /// Called when the user acknowledges the alert.
  final VoidCallback? onAcknowledge;

  /// Whether to show the full message body or a truncated summary.
  final bool expanded;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onAcknowledge,
    this.expanded = false,
  });

  StatusLevel _severityToLevel(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return StatusLevel.high;
      case 'warning':
      case 'medium':
        return StatusLevel.medium;
      case 'low':
        return StatusLevel.low;
      default:
        return StatusLevel.unknown;
    }
  }

  String _formatAge(DateTime dt) {
    final age = DateTime.now().difference(dt);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final level = _severityToLevel(alert.severity);
    final isSuppressed = alert.suppressed;
    final isAcked = alert.acked;

    return Semantics(
      button: onTap != null,
      label:
          '${level.name} alert: ${alert.title}. ${isAcked ? 'Acknowledged.' : ''}',
      child: Opacity(
        opacity: isSuppressed ? 0.55 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: _cardBgColor(level),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: _cardBorderColor(level)),
                boxShadow: isSuppressed ? AppShadow.none : AppShadow.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ──────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alert icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _iconColor(level).withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          _alertIcon(level),
                          size: AppIconSize.md,
                          color: _iconColor(level),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Title + badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StatusBadge(level: level),
                                if (isAcked) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: AppIconSize.sm,
                                    color: AppColors.green600,
                                  ),
                                ],
                                if (isSuppressed) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  const Icon(
                                    Icons.volume_off_rounded,
                                    size: AppIconSize.sm,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              alert.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isAcked
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Timestamp
                      Text(
                        _formatAge(alert.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Message ─────────────────────────────────────────────
                  Text(
                    alert.message,
                    maxLines: expanded ? null : 2,
                    overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  // ── Suppression explanation ──────────────────────────────
                  if (isSuppressed && alert.suppressionReason != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: AppIconSize.sm,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Suppressed: ${alert.suppressionReason}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Pond name ────────────────────────────────────────────
                  if (alert.pondName != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.water_rounded,
                          size: AppIconSize.sm,
                          color: AppColors.primary500,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          alert.pondName!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Acknowledge action ────────────────────────────────────
                  if (!isAcked && onAcknowledge != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: AppTouchTarget.compact,
                      child: OutlinedButton.icon(
                        onPressed: onAcknowledge,
                        icon: const Icon(
                          Icons.check_rounded,
                          size: AppIconSize.sm,
                        ),
                        label: const Text('Acknowledge'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, AppTouchTarget.compact),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _cardBgColor(StatusLevel level) {
    switch (level) {
      case StatusLevel.high:
      case StatusLevel.critical:
        return AppColors.criticalSurface;
      case StatusLevel.medium:
        return AppColors.warningSurface;
      default:
        return AppColors.surface;
    }
  }

  Color _cardBorderColor(StatusLevel level) {
    switch (level) {
      case StatusLevel.high:
      case StatusLevel.critical:
        return AppColors.criticalBorder;
      case StatusLevel.medium:
        return AppColors.warningBorder;
      default:
        return AppColors.border;
    }
  }

  Color _iconColor(StatusLevel level) {
    switch (level) {
      case StatusLevel.high:
      case StatusLevel.critical:
        return AppColors.critical;
      case StatusLevel.medium:
        return AppColors.warning;
      case StatusLevel.low:
        return AppColors.riskLow;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _alertIcon(StatusLevel level) {
    switch (level) {
      case StatusLevel.high:
      case StatusLevel.critical:
        return Icons.error_outline_rounded;
      case StatusLevel.medium:
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

