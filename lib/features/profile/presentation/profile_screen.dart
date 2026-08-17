import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/storage/onboarding_flag_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farmer = DemoDataService.farmer;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ── Header with avatar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.deepNavy,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.deepNavy,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.seaGreen.withValues(alpha: 0.2),
                      child: Text(
                        farmer.name[0],
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(farmer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(farmer.phone, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              title: const Text('Profile', style: TextStyle(color: Colors.white)),
            ),
          ),

          // ── Menu ──────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AppCard(
                  child: Column(
                    children: [
                      _MenuItem(icon: Icons.person_rounded, label: 'My Profile', onTap: () {}),
                      const Divider(height: 1),
                      _MenuItem(icon: Icons.water_rounded, label: 'My Pond Details', onTap: () => context.push('/ponds')),
                      const Divider(height: 1),
                      _MenuItem(icon: Icons.notifications_rounded, label: 'Notification Settings', onTap: () => context.push('/settings')),
                      const Divider(height: 1),
                      _MenuItem(icon: Icons.language_rounded, label: 'Language', onTap: () {}),
                      const Divider(height: 1),
                      _MenuItem(icon: Icons.help_rounded, label: 'Help & Support', onTap: () => context.push('/help')),
                      const Divider(height: 1),
                      _MenuItem(icon: Icons.info_rounded, label: 'About AquaVerse', onTap: () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Pond ID chip
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.seaGreen, size: 18),
                      const SizedBox(width: 10),
                      Text('Pond ID: ${farmer.pondId}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Active', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final store = await OnboardingFlagStore.create();
                      await store.clearAll();
                      if (context.mounted) context.go('/onboarding/language');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.critical,
                      side: const BorderSide(color: AppColors.critical),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.seaGreen),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
        ],
      ),
    ),
  );
}
