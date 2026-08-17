import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/blind_state_banner.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/speaker_button.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
final alertsProvider = StateProvider<List<AlertItem>>((ref) => DemoDataService.alerts);
final alertsTabProvider = StateProvider<int>((ref) => 0);

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts  = ref.watch(alertsProvider);
    final tabIdx  = ref.watch(alertsTabProvider);

    final tabs = ['All', 'Critical', 'Attention', 'Info'];
    List<AlertItem> filtered;
    switch (tabIdx) {
      case 1: filtered = alerts.where((a) => a.severity == AlertSeverity.critical).toList(); break;
      case 2: filtered = alerts.where((a) => a.severity == AlertSeverity.attention).toList(); break;
      case 3: filtered = alerts.where((a) => a.severity == AlertSeverity.info).toList(); break;
      default: filtered = alerts;
    }

    // Check for any suppression reason
    final hasSuppression = alerts.any((a) => a.hasSuppressionReason);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/today')),
        title: const Text('Alerts', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as acknowledged
              final updated = alerts.map((a) => a.copyWith(acknowledged: true)).toList();
              ref.read(alertsProvider.notifier).state = updated;
            },
            child: const Text('Mark all read', style: TextStyle(fontSize: 12, color: AppColors.primary500)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Blind state banner ───────────────────────────────────────────────
          if (hasSuppression)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: BlindStateBanner(suppressionReason: 'Some alerts are suppressed due to data gaps.'),
            ),

          // ── Filter tabs ──────────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: tabs.asMap().entries.map((e) {
                  final isActive = e.key == tabIdx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => ref.read(alertsTabProvider.notifier).state = e.key,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary500 : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isActive ? AppColors.primary500 : AppColors.border),
                        ),
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                            color: isActive ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Alert list ───────────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No alerts in this category.',
                      style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _AlertCard(
                      alert: filtered[i],
                      onAck: () {
                        final idx = alerts.indexWhere((a) => a.id == filtered[i].id);
                        if (idx >= 0) {
                          final updated = List<AlertItem>.from(alerts);
                          updated[idx] = alerts[idx].copyWith(acknowledged: true);
                          ref.read(alertsProvider.notifier).state = updated;
                        }
                      },
                      onFeedback: (fb) {
                        final idx = alerts.indexWhere((a) => a.id == filtered[i].id);
                        if (idx >= 0) {
                          final updated = List<AlertItem>.from(alerts);
                          updated[idx] = alerts[idx].copyWith(feedback: fb);
                          ref.read(alertsProvider.notifier).state = updated;
                        }
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: FarmerBottomNavBar(
        currentIndex: 3,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/today'); break;
            case 1: context.go('/log'); break;
            case 2: context.go('/ask'); break;
            case 3: break;
            case 4: context.go('/crop'); break;
          }
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertItem alert;
  final VoidCallback onAck;
  final ValueChanged<AlertFeedback> onFeedback;

  const _AlertCard({required this.alert, required this.onAck, required this.onFeedback});

  @override
  Widget build(BuildContext context) {
    Color severityColor;
    String severityLabel;
    IconData severityIcon;
    CardType type;

    switch (alert.severity) {
      case AlertSeverity.critical:
        severityColor = AppColors.critical;
        severityLabel = 'CRITICAL';
        severityIcon = Icons.error_rounded;
        type = CardType.critical;
        break;
      case AlertSeverity.attention:
        severityColor = AppColors.warning;
        severityLabel = 'ATTENTION';
        severityIcon = Icons.warning_rounded;
        type = CardType.standard; // Use standard since there's no attention specific background in tokens
        break;
      case AlertSeverity.info:
        severityColor = AppColors.primary500;
        severityLabel = 'INFO';
        severityIcon = Icons.info_rounded;
        type = CardType.info;
        break;
    }

    return AppCard(
      type: alert.acknowledged ? CardType.standard : type,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(severityIcon, color: severityColor, size: 12),
                    const SizedBox(width: 4),
                    Text(severityLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: severityColor)),
                  ],
                ),
              ),
              const Spacer(),
              Text(_timeAgo(alert.timestamp), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 6),
              SpeakerButton(textToSpeak: '${alert.title}. ${alert.description}'),
            ],
          ),
          const SizedBox(height: 8),

          Text(alert.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(alert.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),

          // Low confidence badge
          if (alert.isLowConfidence) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                border: Border.all(color: AppColors.warningBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Low confidence — limited data', style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
            ),
          ],

          const Divider(height: 16),

          // What / Why / Action
          _AlertDetail(label: 'What happened', text: alert.what),
          const SizedBox(height: 4),
          _AlertDetail(label: 'Why', text: alert.why),
          const SizedBox(height: 4),
          _AlertDetail(label: 'Recommended action', text: alert.action, bold: true),
          const SizedBox(height: 10),

          // Action buttons row
          Row(
            children: [
              // Feedback: thumbs up/down (labeled-data flywheel)
              _FeedbackButton(
                icon: Icons.thumb_up_outlined,
                activeIcon: Icons.thumb_up_rounded,
                label: 'This was right',
                isActive: alert.feedback == AlertFeedback.correct,
                color: AppColors.green600,
                onTap: () => onFeedback(AlertFeedback.correct),
              ),
              const SizedBox(width: 6),
              _FeedbackButton(
                icon: Icons.thumb_down_outlined,
                activeIcon: Icons.thumb_down_rounded,
                label: 'This was wrong',
                isActive: alert.feedback == AlertFeedback.incorrect,
                color: AppColors.critical,
                onTap: () => onFeedback(AlertFeedback.incorrect),
              ),
              const Spacer(),
              // Acknowledge
              if (!alert.acknowledged)
                TextButton(
                  onPressed: onAck,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Got it', style: TextStyle(fontSize: 12, color: AppColors.primary500, fontWeight: FontWeight.w600)),
                ),
            ],
          ),

          // Call Officer button for critical alerts
          if (alert.severity == AlertSeverity.critical) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.critical,
                  backgroundColor: AppColors.criticalSurface,
                  side: const BorderSide(color: AppColors.criticalBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.phone_rounded, size: 14),
                label: const Text('Call Officer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
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

class _AlertDetail extends StatelessWidget {
  final String label;
  final String text;
  final bool bold;
  const _AlertDetail({required this.label, required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _FeedbackButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, size: 14, color: isActive ? color : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: isActive ? color : AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
