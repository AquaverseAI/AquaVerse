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

  void _showCallFarmerModal(BuildContext context, Map<String, dynamic>? selectedPond) {
    final farmerName = selectedPond?['farmerName'] ?? 'M. Selvam';
    final pondId = selectedPond?['pondId'] ?? 'TN-01-001';
    final location = selectedPond?['location'] ?? 'Nagapattinam';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.langAccentPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk_rounded,
                    color: AppColors.langAccentPrimary, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                'Contact $farmerName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$pondId · $location · Nagapattinam Cluster 3',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.call_rounded, color: AppColors.green600),
                title: const Text('+91 98765 43210'),
                subtitle: const Text('Direct Voice Line'),
                trailing: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dialing $farmerName (+91 98765 43210)…')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call'),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.langAccentPrimary),
                title: const Text('Send SMS Recommendation'),
                subtitle: const Text('Send text message fallback'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/officer/send-advice');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Extension Officer Portal',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            Text('Nagapattinam District · Cluster 3',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
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
                    label: 'Total Ponds', value: '$total', color: Colors.white),
                const SizedBox(width: 8),
                _StatBadge(
                    label: 'High Risk',
                    value: '$highRisk',
                    color: AppColors.critical),
                const SizedBox(width: 8),
                _StatBadge(
                    label: 'Medium',
                    value: '$medRisk',
                    color: AppColors.warning),
                const SizedBox(width: 8),
                _StatBadge(
                    label: 'Good', value: '$good', color: AppColors.green600),
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
                  label: 'Send Advice',
                  color: AppColors.langAccentPrimary,
                  onTap: () => context.push('/officer/send-advice'),
                ),
                _QuickAction(
                  icon: Icons.add_location_alt_rounded,
                  label: 'Add Visit',
                  color: AppColors.primary700,
                  onTap: () => context.push('/officer/visit-log'),
                ),
                _QuickAction(
                  icon: Icons.bar_chart_rounded,
                  label: 'View Reports',
                  color: AppColors.warning,
                  onTap: () => context.push('/officer/reports'),
                ),
                _QuickAction(
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Call Farmer',
                  color: AppColors.critical,
                  onTap: () => _showCallFarmerModal(context, null),
                ),
              ],
            ),
          ),

          // ── Search & Filter Controls ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ponds or farmers…',
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
              children: ['All', 'High Risk', 'Medium Risk', 'Low Risk'].map((f) {
                final isActive = _filter == f;
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
                        f,
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
              separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                  onTap: () => context.push('/pond-details'),
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
                        onPressed: () => _showCallFarmerModal(context, p),
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
