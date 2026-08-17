import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = DemoDataService.notifications;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              for (var n in notifications) {
                n.copyWith(isRead: true);
              }
            },
            child: const Text('Mark all read', style: TextStyle(fontSize: 12, color: AppColors.seaGreen)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final n = notifications[i];
          Color iconColor;
          IconData icon;
          switch (n.category) {
            case NotificationCategory.alert:
              iconColor = AppColors.critical;
              icon = Icons.warning_rounded;
              break;
            case NotificationCategory.reminder:
              iconColor = AppColors.warning;
              icon = Icons.access_time_rounded;
              break;
            case NotificationCategory.system:
              iconColor = AppColors.info;
              icon = Icons.system_update_rounded;
              break;
            default:
              iconColor = AppColors.seaGreen;
              icon = Icons.info_rounded;
          }

          return AppCard(
            onTap: n.routeTo != null ? () => context.push(n.routeTo!) : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: n.isRead ? AppColors.textSecondary : AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(n.body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                      const SizedBox(height: 4),
                      Text(_timeAgo(n.timestamp), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (!n.isRead)
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.seaGreen, shape: BoxShape.circle),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
