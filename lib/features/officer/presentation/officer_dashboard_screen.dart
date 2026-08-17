import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  String _search = '';
  String _filter = 'All'; // All | High Risk | Medium Risk | Low Risk

  @override
  Widget build(BuildContext context) {
    final ponds = DemoDataService.officerPonds;
    final filtered = ponds.where((p) {
      final matchFilter = _filter == 'All' || p['risk'] == _filter.replaceAll(' Risk', '');
      final matchSearch = _search.isEmpty ||
          p['pondId'].toString().toLowerCase().contains(_search.toLowerCase()) ||
          p['farmerName'].toString().toLowerCase().contains(_search.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();

    final total    = ponds.length;
    final highRisk = ponds.where((p) => p['risk'] == 'High').length;
    final medRisk  = ponds.where((p) => p['risk'] == 'Medium').length;
    final good     = ponds.where((p) => p['risk'] == 'Low').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Officer Dashboard'),
        backgroundColor: AppColors.primary700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_outlined)),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Text('O', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // ── Stat bar ──────────────────────────────────────────────────────
          Container(
            color: AppColors.primary700,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _StatBadge(label: 'Total Ponds', value: '$total', color: Colors.white),
                const SizedBox(width: 10),
                _StatBadge(label: 'High Risk', value: '$highRisk', color: AppColors.critical),
                const SizedBox(width: 10),
                _StatBadge(label: 'Medium', value: '$medRisk', color: AppColors.warning),
                const SizedBox(width: 10),
                _StatBadge(label: 'Good', value: '$good', color: AppColors.green600),
              ],
            ),
          ),

          // ── Quick actions ─────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickAction(icon: Icons.send_rounded, label: 'Send Advice', color: AppColors.primary500, onTap: () {}),
                _QuickAction(icon: Icons.add_location_rounded, label: 'Add Visit', color: AppColors.primary700, onTap: () => context.push('/officer/visit-log')),
                _QuickAction(icon: Icons.bar_chart_rounded, label: 'View Reports', color: AppColors.warning, onTap: () {}),
                _QuickAction(icon: Icons.phone_rounded, label: 'Call Farmer', color: AppColors.critical, onTap: () {}),
              ],
            ),
          ),

          // ── Search + filter ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search ponds or farmers…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: ['All', 'High Risk', 'Medium Risk', 'Low Risk'].map((f) {
                final isActive = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary500 : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? AppColors.primary500 : AppColors.border),
                      ),
                      child: Text(f, style: TextStyle(fontSize: 12, color: isActive ? Colors.white : AppColors.textSecondary, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Pond table ────────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = filtered[i];
                final status = p['status'] as PondStatus;
                Color statusColor;
                switch (status) {
                  case PondStatus.good: statusColor = AppColors.green600; break;
                  case PondStatus.caution: statusColor = AppColors.warning; break;
                  case PondStatus.critical: statusColor = AppColors.critical; break;
                }

                return AppCard(
                  onTap: () => context.push('/pond-details'),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 40,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(p['pondId'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(p['risk'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('${p['farmerName']} · ${p['location']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text('Last visit: ${p['lastVisit']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ],
    ),
  );
}
