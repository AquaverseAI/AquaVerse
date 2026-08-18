import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/models/models.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';

class OfficerDashboardScreen extends ConsumerStatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  ConsumerState<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends ConsumerState<OfficerDashboardScreen> {
  String _search = '';
  String _filter = 'All'; // All | High Risk | Medium Risk | Low Risk

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(appLanguageProvider);
    final ponds = DemoDataService.officerPonds;
    final filtered = ponds.where((p) {
      final matchFilter =
          _filter == 'All' || p['risk'] == _filter.replaceAll(' Risk', '');
      final matchSearch = _search.isEmpty ||
          p['pondId'].toString().toLowerCase().contains(_search.toLowerCase()) ||
          p['farmerName'].toString().toLowerCase().contains(_search.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();

    final total = ponds.length;
    final highRisk = ponds.where((p) => p['risk'] == 'High').length;
    final medRisk = ponds.where((p) => p['risk'] == 'Medium').length;
    final good = ponds.where((p) => p['risk'] == 'Low').length;

    final filterTabs = currentLang == 'ta'
        ? ['All', 'High Risk', 'Medium Risk', 'Low Risk']
        : ['All', 'High Risk', 'Medium Risk', 'Low Risk'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentLang == 'ta' ? 'விரிவாக்க அலுவலர் தளம்' : 'Extension Officer Portal',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              currentLang == 'ta' ? 'நாகப்பட்டினம் மாவட்டம் · குழு 3' : 'Nagapattinam District · Cluster 3',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        backgroundColor: AppColors.langAccentSeagreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined),
          ),
          GestureDetector(
            onTap: () => context.push('/officer/profile'),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'OA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stat Bar (Gradient Theme) ───────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.langAccentSeagreen, Color(0xFF14B8A6)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                _StatBadge(
                    label: currentLang == 'ta' ? 'மொத்தக் குளங்கள்' : 'Total Ponds', value: '$total', color: Colors.white),
                const SizedBox(width: 8),
                _StatBadge(
                    label: currentLang == 'ta' ? 'அதிக அபாயம்' : 'High Risk',
                    value: '$highRisk',
                    color: AppColors.critical),
                const SizedBox(width: 8),
                _StatBadge(
                    label: currentLang == 'ta' ? 'நடுத்தரம்' : 'Medium',
                    value: '$medRisk',
                    color: AppColors.warning),
                const SizedBox(width: 8),
                _StatBadge(
                    label: currentLang == 'ta' ? 'சிறந்தது' : 'Good', value: '$good', color: AppColors.green600),
              ],
            ),
          ),

          // ── Working Quick Action Hub ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowTier1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickAction(
                  icon: Icons.send_rounded,
                  label: currentLang == 'ta' ? 'ஆலோசனை அனுப்பு' : 'Send Advice',
                  color: AppColors.langAccentPrimary,
                  onTap: () => context.push('/officer/send-advice'),
                ),
                _QuickAction(
                  icon: Icons.add_location_alt_rounded,
                  label: currentLang == 'ta' ? 'பார்வை பதிவு' : 'Add Visit',
                  color: AppColors.primary700,
                  onTap: () => context.push('/officer/visit-log'),
                ),
                _QuickAction(
                  icon: Icons.bar_chart_rounded,
                  label: currentLang == 'ta' ? 'அறிக்கைகளைப் பார்' : 'View Reports',
                  color: AppColors.warning,
                  onTap: () => context.push('/officer/reports'),
                ),
                _QuickAction(
                  icon: Icons.phone_in_talk_rounded,
                  label: currentLang == 'ta' ? 'விவசாயியை அழை' : 'Call Farmer',
                  color: AppColors.critical,
                  onTap: () => context.push('/officer/farmer-info'),
                ),
              ],
            ),
          ),

          // ── Search & Filter Controls ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: currentLang == 'ta' ? 'குளங்கள் அல்லது விவசாயிகளைத் தேடுங்கள்…' : 'Search ponds or farmers…',
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textSecondary),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: filterTabs.map((f) {
                final isActive = _filter == f;
                final displayLabel = currentLang == 'ta'
                    ? (f == 'All'
                        ? 'அனைத்தும்'
                        : f == 'High Risk'
                            ? 'அதிக அபாயம்'
                            : f == 'Medium Risk'
                                ? 'நடுத்தர அபாயம்'
                                : 'குறைந்த அபாயம்')
                    : f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.langAccentPrimary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isActive
                                ? AppColors.langAccentPrimary
                                : AppColors.border),
                      ),
                      child: Text(
                        displayLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.white : AppColors.textSecondary,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Pond List Table ─────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = filtered[i];
                final status = p['status'] as PondStatus;
                Color statusColor;
                switch (status) {
                  case PondStatus.good:
                    statusColor = AppColors.green600;
                    break;
                  case PondStatus.caution:
                    statusColor = AppColors.warning;
                    break;
                  case PondStatus.critical:
                    statusColor = AppColors.critical;
                    break;
                }

                return AppCard(
                  onTap: () => context.push('/officer/farmer-info', extra: p),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  p['pondId'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${p['risk']} Risk',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p['farmerName']} · ${p['location']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Last visit: ${p['lastVisit']}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone_outlined,
                            color: AppColors.langAccentPrimary, size: 20),
                        onPressed: () => context.push('/officer/farmer-info', extra: p),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted, size: 20),
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

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
