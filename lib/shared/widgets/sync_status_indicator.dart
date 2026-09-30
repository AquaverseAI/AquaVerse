import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// SyncStatusIndicator — compact inline sync state chip.
///
/// Shows one of four states:
///   pending  — data waiting to be uploaded (grey clock)
///   syncing  — actively uploading (blue spinner)
///   synced   — successfully uploaded (green tick)
///   failed   — upload failed (red x)
///
/// Place next to log entries, visit records, or any locally-saved item
/// that has a pending backend sync.
class SyncStatusIndicator extends StatefulWidget {
  final SyncState state;

  /// Override the display label. If null, the default label is used.
  final String? label;

  const SyncStatusIndicator({
    super.key,
    required this.state,
    this.label,
  });

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.state == SyncState.syncing) {
      _spinController.repeat();
    }
  }

  @override
  void didUpdateWidget(SyncStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == SyncState.syncing) {
      _spinController.repeat();
    } else {
      _spinController.stop();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.state) {
      case SyncState.pending:
        return AppColors.textMuted;
      case SyncState.syncing:
        return AppColors.info;
      case SyncState.synced:
        return AppColors.green600;
      case SyncState.failed:
        return AppColors.critical;
    }
  }

  IconData get _icon {
    switch (widget.state) {
      case SyncState.pending:
        return Icons.schedule_rounded;
      case SyncState.syncing:
        return Icons.sync_rounded;
      case SyncState.synced:
        return Icons.cloud_done_rounded;
      case SyncState.failed:
        return Icons.cloud_off_rounded;
    }
  }

  String get _defaultLabel {
    switch (widget.state) {
      case SyncState.pending:
        return 'Pending sync';
      case SyncState.syncing:
        return 'Syncing…';
      case SyncState.synced:
        return 'Synced';
      case SyncState.failed:
        return 'Sync failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label ?? _defaultLabel;

    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.state == SyncState.syncing
              ? RotationTransition(
                  turns: _spinController,
                  child: Icon(_icon, size: AppIconSize.sm, color: _color),
                )
              : Icon(_icon, size: AppIconSize.sm, color: _color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

enum SyncState { pending, syncing, synced, failed }

