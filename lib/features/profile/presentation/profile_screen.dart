import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/storage/onboarding_flag_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/speaker_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showFarmerDetailsDialog(BuildContext context) {
    final farmer = DemoDataService.farmer;
    final pond = DemoDataService.pond;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_pin_rounded, color: AppColors.langAccentPrimary),
              SizedBox(width: 8),
              Text('Farmer Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'Farmer Name', value: farmer.name),
              const Divider(height: 12),
              _DetailRow(label: 'Registered Phone', value: farmer.phone),
              const Divider(height: 12),
              _DetailRow(label: 'Assigned Pond ID', value: farmer.pondId),
              const Divider(height: 12),
              _DetailRow(label: 'Farm Location', value: pond.location),
              const Divider(height: 12),
              _DetailRow(label: 'Culture Species', value: pond.species),
              const Divider(height: 12),
              _DetailRow(label: 'Pond Area / Depth', value: '${pond.areaSqM.toInt()} m² / ${pond.depthM}m'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.langAccentPrimary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.langAccentPrimary),
              SizedBox(width: 8),
              Text('About AquaVerse AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AquaVerse Farmer App · Version 1.2.0',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              SizedBox(height: 6),
              Text(
                'Smart Aquaculture Precision Platform for Farmers & Extension Officers.\n\n'
                '• Offline-First Drift (SQLite) Telemetry Cache\n'
                '• AI Sensor-Driven Pond Health Risk Engine\n'
                '• Native Multi-Language Support (Tamil, English, Hindi, Telugu)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.langAccentPrimary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmer = DemoDataService.farmer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/today')),
        title: const Text('Farmer Profile', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          SpeakerButton(textToSpeak: 'Farmer Profile for ${DemoDataService.farmer.name}. Pond ${DemoDataService.farmer.pondId}.'),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pageMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Farmer Profile Header ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.gradient3DPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowTier2,
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        farmer.name.isNotEmpty ? farmer.name[0].toUpperCase() : 'F',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmer.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          farmer.phone,
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.87)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Pond ID: ${farmer.pondId} · Active',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Profile Menu ─────────────────────────────────────────────
            const Text('Account & Preferences', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10),

            AppCard(
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.person_rounded,
                    title: 'My Profile & Farm Info',
                    subtitle: 'View registered farmer details and pond spec',
                    onTap: () => _showFarmerDetailsDialog(context),
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.water_rounded,
                    title: 'My Ponds & Culture Data',
                    subtitle: 'View active pond specs and stocking history',
                    onTap: () => context.push('/ponds'),
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.notifications_rounded,
                    title: 'Notification Settings',
                    subtitle: 'Manage SMS & push alerts',
                    onTap: () => context.push('/settings'),
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.language_rounded,
                    title: 'App Language',
                    subtitle: 'Tamil (தமிழ்), English, Hindi, Telugu',
                    onTap: () => context.push('/onboarding/language'),
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.help_rounded,
                    title: 'Help & Escalation Support',
                    subtitle: 'Contact officer or call helpline',
                    onTap: () => context.push('/help'),
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.info_rounded,
                    title: 'About AquaVerse',
                    subtitle: 'Version 1.2.0 · Platform specs',
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Sign Out ──────────────────────────────────────────────────
            SecondaryButton(
              label: 'Sign Out',
              icon: Icons.logout_rounded,
              onPressed: () async {
                final store = await OnboardingFlagStore.create();
                await store.clearAll();
                if (context.mounted) {
                  context.go('/onboarding/role');
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.langAccentPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.langAccentPrimary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
