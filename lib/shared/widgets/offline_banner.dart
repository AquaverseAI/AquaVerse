import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// OfflineBanner — shown when connectivity is lost.
/// Light-theme variant: amber warning bar at top of screen area.
class OfflineBanner extends StatelessWidget {
  final int pendingSyncCount;
  final VoidCallback? onViewOfflineLogsTap;
  final String? message;

  const OfflineBanner({
    super.key,
    this.pendingSyncCount = 0,
    this.onViewOfflineLogsTap,
    this.message,
  });

  // For demo, always hidden. Set `forceShow: true` for testing.
  static bool forceShow = false;

  @override
  Widget build(BuildContext context) {
    if (!forceShow) return const SizedBox.shrink();

    final text = message ??
        (pendingSyncCount > 0
            ? '$pendingSyncCount logs queued — will sync when online'
            : 'You are offline. Some features limited.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.warning,
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500))),
          if (onViewOfflineLogsTap != null)
            GestureDetector(
              onTap: onViewOfflineLogsTap,
              child: const Text('View', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
            ),
        ],
      ),
    );
  }
}
