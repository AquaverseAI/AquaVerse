import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/network/auth_api_service.dart';
import '../../../core/storage/onboarding_flag_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/speaker_button.dart';

class OfficerProfileScreen extends ConsumerWidget {
  const OfficerProfileScreen({super.key});

  void _showClusterDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.location_city_rounded, color: AppColors.langAccentPrimary),
              SizedBox(width: 8),
              Text('District Cluster Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'District', value: 'Nagapattinam'),
              Divider(height: 12),
              _DetailRow(label: 'Cluster ID', value: 'Cluster 3'),
              Divider(height: 12),
              _DetailRow(label: 'Supervised Ponds', value: '12 Ponds'),
              Divider(height: 12),
              _DetailRow(label: 'Assigned Farmers', value: '8 Farmers'),
              Divider(height: 12),
              _DetailRow(label: 'Senior Officer', value: 'Dr. K. Arunkumar (OFF-TN-804)'),
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

  void _showOfflineQueueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.sync_rounded, color: AppColors.langAccentPrimary),
              SizedBox(width: 8),
              Text('Offline Report Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '2 Field Visit Logs Queued for Sync',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              SizedBox(height: 8),
              _DetailRow(label: 'TN-01-002 Visit Log', value: 'Pending Sync'),
              Divider(height: 10),
              _DetailRow(label: 'TN-01-004 Visit Log', value: 'Pending Sync'),
              SizedBox(height: 10),
              Text(
                'Visit reports will auto-sync to backend when connected to mobile network.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Offline visit reports synced successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.langAccentPrimary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text('Sync Now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
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
              Text('About Extension Portal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AquaVerse Extension Officer Portal · v1.2.0',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              SizedBox(height: 6),
              Text(
                'Empowering Aquaculture Field Extension Officers with real-time pond telemetry, outbreak triage, and cluster analytics.',
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
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);
    const officerName = 'Dr. K. Arunkumar';
    final officerRole = currentLang == 'ta' ? 'மூத்த மீன்வள விரிவாக்க அலுவலர்' : 'Senior Aquaculture Extension Officer';
    const officerId = 'OFF-TN-804';
    final districtCluster = currentLang == 'ta' ? 'நாகப்பட்டினம் மாவட்டம் · குழு 3' : 'Nagapattinam District · Cluster 3';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/officer/dashboard')),
        title: Text(
          currentLang == 'ta' ? 'அலுவலர் விவரங்கள்' : 'Officer Profile',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          SpeakerButton(
            textToSpeak: currentLang == 'ta'
                ? 'அலுவலர் விவரங்கள் - முனைவர் K. அருண்குமார். நாகப்பட்டினம் குழு 3.'
                : 'Officer Profile for Dr. K. Arunkumar. Nagapattinam Cluster 3.',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pageMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Officer Identity Card ───────────────────────────────────────
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
                    child: const Center(
                      child: Text(
                        'OA',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          officerName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          officerRole,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.87),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$officerId · $districtCluster',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Cluster Statistics Grid ─────────────────────────────────────
            Text(
              currentLang == 'ta' ? 'குழுப் பார்வை' : 'Cluster Overview',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.8,
              children: [
                _StatTile(
                  label: currentLang == 'ta' ? 'கண்காணிக்கப்படும் குளங்கள்' : 'Supervised Ponds',
                  value: currentLang == 'ta' ? '12 குளங்கள்' : '12 Ponds',
                  icon: Icons.water_rounded,
                  color: AppColors.langAccentPrimary,
                ),
                _StatTile(
                  label: currentLang == 'ta' ? 'ஒதுக்கப்பட்ட விவசாயிகள்' : 'Assigned Farmers',
                  value: currentLang == 'ta' ? '8 விவசாயிகள்' : '8 Farmers',
                  icon: Icons.people_alt_rounded,
                  color: AppColors.primary700,
                ),
                _StatTile(
                  label: currentLang == 'ta' ? 'நடப்பு அறுவடைகள்' : 'Active Harvests',
                  value: currentLang == 'ta' ? '5 நடப்பில்' : '5 Active',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.green600,
                ),
                _StatTile(
                  label: currentLang == 'ta' ? 'நிலுவையிலுள்ள பார்வைகள்' : 'Pending Visits',
                  value: currentLang == 'ta' ? '3 திட்டமிடப்பட்டவை' : '3 Scheduled',
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Quick Settings & Actions ────────────────────────────────────
            Text(
              currentLang == 'ta' ? 'அலுவலர் நிர்வாகம்' : 'Officer Management',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            AppCard(
              child: Column(
                children: [
                  _OptionTile(
                    icon: Icons.location_city_rounded,
                    title: currentLang == 'ta' ? 'ஒதுக்கப்பட்ட மாவட்டக் குழு' : 'Assigned District Cluster',
                    subtitle: currentLang == 'ta' ? 'நாகப்பட்டினம் குழு 3 (12 குளங்கள்)' : 'Nagapattinam Cluster 3 (12 Ponds)',
                    onTap: () => _showClusterDetailsDialog(context),
                  ),
                  const Divider(height: 1),
                  _OptionTile(
                    icon: Icons.sync_rounded,
                    title: currentLang == 'ta' ? 'ஆஃப்லைன் அறிக்கை வரிசை' : 'Offline Report Queue',
                    subtitle: currentLang == 'ta' ? '2 பார்வைகள் இணைக்க நிலுவையில் உள்ளன' : '2 visit logs queued for sync',
                    trailingBadge: currentLang == 'ta' ? '2 நிலுவை' : '2 Pending',
                    onTap: () => _showOfflineQueueDialog(context),
                  ),
                  const Divider(height: 1),
                  _OptionTile(
                    icon: Icons.language_rounded,
                    title: currentLang == 'ta' ? 'செயலி மொழி' : 'App Language',
                    subtitle: currentLang == 'ta' ? 'தமிழ் (Tamil) / English' : 'English / Tamil (தமிழ்)',
                    onTap: () => context.push('/settings'),
                  ),
                  const Divider(height: 1),
                  _OptionTile(
                    icon: Icons.support_agent_rounded,
                    title: currentLang == 'ta' ? 'அக்வா மாஸ்டர் உதவி எண்' : 'Aqua Master Helpline',
                    subtitle: currentLang == 'ta' ? 'அவசர நோய்ப் பரவலுக்கான நேரடித் தொடர்பு' : 'Direct escalation line for urgent outbreaks',
                    onTap: () => context.push('/help'),
                  ),
                  const Divider(height: 1),
                  _OptionTile(
                    icon: Icons.info_rounded,
                    title: currentLang == 'ta' ? 'விரிவாக்கத் தளம் பற்றி' : 'About Extension Portal',
                    subtitle: currentLang == 'ta' ? 'பதிப்பு v1.2.0 · தள விவரக்குறிப்புகள்' : 'Version 1.2.0 · Platform specs',
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Clean Sign Out Button ────────────────
            SecondaryButton(
              label: currentLang == 'ta' ? 'வெளியேறு' : 'Sign Out',
              icon: Icons.logout_rounded,
              onPressed: () async {
                final authService = AuthApiService();
                await authService.logout();
                final flagStore = await OnboardingFlagStore.create();
                await flagStore.clearSession();
                if (context.mounted) {
                  context.go('/onboarding/mobile');
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingBadge;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingBadge,
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingBadge != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Text(
                  trailingBadge!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
