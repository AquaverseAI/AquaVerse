import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'status_badge.dart';

/// PondCard — reusable pond list item.
///
/// Shows pond name, area, species, current status badge, and last-updated
/// timestamp. Used in My Ponds (farmer) and Officer Pond List.
///
/// Never shows raw risk scores. Status is always qualitative.
class PondCard extends StatelessWidget {
  final Pond pond;
  final VoidCallback? onTap;

  /// If true, shows a compact layout for officer lists.
  final bool compact;

  const PondCard({
    super.key,
    required this.pond,
    this.onTap,
    this.compact = false,
  });

  StatusLevel _pondStatusToLevel(PondStatus status) {
    switch (status) {
      case PondStatus.good:
        return StatusLevel.ok;
      case PondStatus.caution:
        return StatusLevel.medium;
      case PondStatus.critical:
        return StatusLevel.high;
    }
  }

  String _formatArea() {
    if (pond.areaHectares != null) {
      return '${pond.areaHectares!.toStringAsFixed(2)} ha';
    }
    if (pond.areaSqM != null) {
      return '${(pond.areaSqM! / 10000).toStringAsFixed(2)} ha';
    }
    return '—';
  }

  String _formatAge(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final age = DateTime.now().difference(dt);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final statusLevel = _pondStatusToLevel(pond.status);

    return Semantics(
      button: onTap != null,
      label: '${pond.name}, ${_pondStatusToLevel(pond.status).name} status',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadow.card,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status disc
                Container(
                  width: compact ? 36 : 44,
                  height: compact ? 36 : 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _discColor(statusLevel).withValues(alpha: 0.12),
                    border: Border.all(
                      color: _discColor(statusLevel),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _discIcon(statusLevel),
                    size: compact ? AppIconSize.md : AppIconSize.lg,
                    color: _discColor(statusLevel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              pond.name,
                              style: TextStyle(
                                fontSize: compact ? 14 : 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusBadge(level: statusLevel),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Metadata row
                      DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        child: Wrap(
                          spacing: AppSpacing.md,
                          children: [
                            if (pond.species != null)
                              Text(pond.species!),
                            Text(_formatArea()),
                            if (!compact)
                              Text(
                                pond.location ?? pond.district,
                              ),
                          ],
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: AppIconSize.xs,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Updated ${_formatAge(pond.lastUpdated ?? pond.updatedAt)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: AppIconSize.lg,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _discColor(StatusLevel level) {
    switch (level) {
      case StatusLevel.ok:
        return AppColors.green600;
      case StatusLevel.medium:
        return AppColors.warning;
      case StatusLevel.high:
      case StatusLevel.critical:
        return AppColors.critical;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _discIcon(StatusLevel level) {
    switch (level) {
      case StatusLevel.ok:
        return Icons.check_circle_outline_rounded;
      case StatusLevel.medium:
        return Icons.warning_amber_rounded;
      case StatusLevel.high:
      case StatusLevel.critical:
        return Icons.error_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

