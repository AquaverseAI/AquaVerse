import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/connectivity_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// OfflineBanner — shows when the device has no network connectivity.
///
/// WIRED to [connectivityProvider] (`StreamProvider<bool>`):
///   - hidden when online
///   - shown when offline or on stream error (treated as offline for safety)
///   - collapses with zero height — does NOT obstruct content below it
///
/// Place at the top of page body content (below AppBar, above list/content).
///
/// Previous behavior (forceShow static flag) has been REMOVED.
/// The banner is now connectivity-driven.
class OfflineBanner extends ConsumerWidget {
  /// Number of pending items waiting to sync. Shown in the banner message.
  final int pendingSyncCount;

  /// Called when the user taps "View" (optional). Show offline log screen.
  final VoidCallback? onViewOfflineLogsTap;

  /// Optional custom message override.
  final String? message;

  const OfflineBanner({
    super.key,
    this.pendingSyncCount = 0,
    this.onViewOfflineLogsTap,
    this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (isOnline) {
        if (isOnline) return const SizedBox.shrink();
        return _buildBanner(context);
      },
      // While initializing connectivity: treat as online (don't flash offline)
      loading: () => const SizedBox.shrink(),
      // On error (e.g. permission denied): treat as offline to be safe
      error: (_, _) => _buildBanner(context),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final bannerMessage = message ??
        (pendingSyncCount > 0
            ? '$pendingSyncCount log${pendingSyncCount == 1 ? '' : 's'} queued — will sync when online'
            : 'You are offline. Some features limited.');

    return Semantics(
      liveRegion: true,
      label: 'Offline status: $bannerMessage',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        color: AppColors.warning,
        child: Row(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: AppIconSize.sm,
              color: Colors.white,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                bannerMessage,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onViewOfflineLogsTap != null)
              Semantics(
                button: true,
                label: 'View offline logs',
                child: GestureDetector(
                  onTap: onViewOfflineLogsTap,
                  child: const Text(
                    'View',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
