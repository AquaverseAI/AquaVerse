import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';

class OfficerReportsScreen extends StatelessWidget {
  const OfficerReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/officer/dashboard')),
        title: const Text('Cluster Analytics & Reports',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Exporting District Cluster Report (PDF)…')),
              );
            },
            icon: const Icon(Icons.file_download_rounded,
                color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pageMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Health Summary Card ─────────────────────────────────────────
            AppCard(
              type: CardType.info,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.langAccentPrimary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.analytics_rounded,
                        color: AppColors.langAccentPrimary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cluster Health Index',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        SizedBox(height: 2),
                        Text('84.2% Optimal',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.langAccentPrimary)),
                        SizedBox(height: 2),
                        Text('Nagapattinam District Cluster 3 · 12 Ponds',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Parameter Averages Grid ─────────────────────────────────────
            const Text('Cluster Parameter Averages',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.8,
              children: const [
                _ReportTile(
                  label: 'Average DO',
                  value: '5.6 mg/L',
                  sub: 'Normal (>4.0 mg/L)',
                  color: AppColors.green600,
                ),
                _ReportTile(
                  label: 'Average pH',
                  value: '7.6 pH',
                  sub: 'Stable (6.5 - 8.5)',
                  color: AppColors.langAccentPrimary,
                ),
                _ReportTile(
                  label: 'Average Salinity',
                  value: '14.8 ppt',
                  sub: 'Optimal Range',
                  color: AppColors.primary700,
                ),
                _ReportTile(
                  label: 'Water Temp',
                  value: '28.2 °C',
                  sub: 'Seasonal Average',
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── High Risk Ponds Needing Attention ──────────────────────────
            const Text('Priority Ponds (Requires Visit)',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),

            _RiskPondItem(
              pondId: 'TN-01-002',
              farmerName: 'R. Kumar',
              issue: 'Low DO Warning (3.8 mg/L at 4 AM check)',
              riskTier: 'High Risk',
              riskColor: AppColors.critical,
            ),
            const SizedBox(height: 10),
            _RiskPondItem(
              pondId: 'TN-01-004',
              farmerName: 'S. Murugan',
              issue: 'Slight pH Variance (8.6 pH evening reading)',
              riskTier: 'Medium Risk',
              riskColor: AppColors.warning,
            ),
            const SizedBox(height: 24),

            // ── Export Action ──────────────────────────────────────────────
            PrimaryButton(
              label: 'Download Full District Report (PDF)',
              icon: Icons.picture_as_pdf_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Report saved to local downloads')),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _ReportTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _RiskPondItem extends StatelessWidget {
  final String pondId;
  final String farmerName;
  final String issue;
  final String riskTier;
  final Color riskColor;

  const _RiskPondItem({
    required this.pondId,
    required this.farmerName,
    required this.issue,
    required this.riskTier,
    required this.riskColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/pond-details'),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 44,
            decoration: BoxDecoration(
              color: riskColor,
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
                    Text(pondId,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(riskTier,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: riskColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$farmerName · $issue',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}
