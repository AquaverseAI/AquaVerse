import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

// ── Settings providers ────────────────────────────────────────────────────────
final pushNotifProvider    = StateProvider<bool>((ref) => true);
final alertPrefProvider    = StateProvider<bool>((ref) => true);
final selectedUnitProvider = StateProvider<String>((ref) => 'metric');

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pushNotif = ref.watch(pushNotifProvider);
    final alertPref = ref.watch(alertPrefProvider);
    final unit      = ref.watch(selectedUnitProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── General ──────────────────────────────────────────────────────
            _SectionTitle('General'),
            AppCard(
              child: Column(
                children: [
                  _TileRow(icon: Icons.language_rounded, label: 'Language', trailing: const Text('தமிழ்', style: TextStyle(color: AppColors.seaGreen, fontWeight: FontWeight.w600))),
                  const Divider(height: 1),
                  _TileRow(
                    icon: Icons.straighten_rounded,
                    label: 'Units',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['metric', 'imperial'].map((u) {
                        final selected = unit == u;
                        return GestureDetector(
                          onTap: () => ref.read(selectedUnitProvider.notifier).state = u,
                          child: Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.seaGreen : AppColors.scaffoldBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? AppColors.seaGreen : AppColors.border),
                            ),
                            child: Text(u, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Notifications ─────────────────────────────────────────────────
            _SectionTitle('Notifications'),
            AppCard(
              child: Column(
                children: [
                  _SwitchTile(icon: Icons.notifications_rounded, label: 'Push Notifications', value: pushNotif, onChanged: (v) => ref.read(pushNotifProvider.notifier).state = v),
                  const Divider(height: 1),
                  _SwitchTile(icon: Icons.warning_rounded, label: 'Alert Preferences', value: alertPref, onChanged: (v) => ref.read(alertPrefProvider.notifier).state = v),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Others ────────────────────────────────────────────────────────
            _SectionTitle('Others'),
            AppCard(
              child: Column(
                children: [
                  _TileRow(icon: Icons.privacy_tip_rounded, label: 'Privacy Policy', onTap: () {}, trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18)),
                  const Divider(height: 1),
                  _TileRow(icon: Icons.description_rounded, label: 'Terms & Conditions', onTap: () {}, trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18)),
                  const Divider(height: 1),
                  _TileRow(icon: Icons.info_rounded, label: 'App Version', trailing: const Text('v1.2.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
  );
}

class _TileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _TileRow({required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.seaGreen),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
          if (trailing != null) trailing!,
        ],
      ),
    ),
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.seaGreen),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.seaGreen,
        ),
      ],
    ),
  );
}
