import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class CropScreen extends ConsumerWidget {
  const CropScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crop = DemoDataService.cropCycle;
    final now  = DateTime.now();
    final doc  = now.difference(crop.stockingDate).inDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/today')),
        title: Text('Crop / Cycle — ${DemoDataService.farmer.pondId}', style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            onPressed: () {
              final text =
                'AquaVerse AI — Crop Summary\n'
                'Pond: ${DemoDataService.farmer.pondId}\n'
                'Species: ${crop.species}\n'
                'DOC: $doc days\n'
                'FCR: ${crop.fcr}\n'
                'Expected Profit: ₹${_formatNum(crop.expectedProfitMin)}–₹${_formatNum(crop.expectedProfitMax)}';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Crop summary copied to clipboard')),
              );
            },
            icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Metrics grid ─────────────────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: [
                _MetricCard(label: 'Days of Culture', value: '$doc days', icon: Icons.calendar_today_rounded, color: AppColors.primary500),
                _MetricCard(label: 'FCR', value: crop.fcr.toStringAsFixed(2), icon: Icons.bar_chart_rounded, color: AppColors.primary700),
                _MetricCard(label: 'Cost/kg', value: '₹${crop.costPerKg.toInt()}', icon: Icons.account_balance_wallet_rounded, color: AppColors.warning),
                _MetricCard(label: 'Market Price/kg', value: '₹${crop.marketPricePerKg.toInt()}', icon: Icons.trending_up_rounded, color: AppColors.green600),
              ],
            ),
            const SizedBox(height: 16),

            // ── Expected Profit band ──────────────────────────────────────────
            AppCard(
              type: CardType.healthy,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.green600.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.currency_rupee_rounded, color: AppColors.green600, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expected Profit', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${_formatNum(crop.expectedProfitMin)} – ₹${_formatNum(crop.expectedProfitMax)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.green600),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Range estimate — actual depends on harvest weight & market price',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Additional metrics row ────────────────────────────────────────
            Row(
              children: [
                Expanded(child: AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Cumulative Feed', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('${crop.cumulativeFeedKg.toInt()} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ]),
                )),
                const SizedBox(width: 10),
                Expanded(child: AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Expected Harvest', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('${crop.expectedHarvestKg.toInt()} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ]),
                )),
              ],
            ),
            const SizedBox(height: 20),

            // ── Timeline ──────────────────────────────────────────────────────
            const Text('Crop Timeline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            ...crop.timeline.asMap().entries.map((e) {
              final isLast = e.key == crop.timeline.length - 1;
              return _TimelineItem(event: e.value, isLast: isLast);
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: FarmerBottomNavBar(
        currentIndex: 4,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/today'); break;
            case 1: context.go('/log'); break;
            case 2: context.go('/ask'); break;
            case 3: context.go('/alerts'); break;
            case 4: break;
          }
        },
      ),
    );
  }

  String _formatNum(double n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(2)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toInt().toString();
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final CropEvent event;
  final bool isLast;
  const _TimelineItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    IconData dotIcon;
    switch (event.status) {
      case CropEventStatus.completed:
        dotColor = AppColors.green600;
        dotIcon = Icons.check_circle_rounded;
        break;
      case CropEventStatus.active:
        dotColor = AppColors.primary500;
        dotIcon = Icons.radio_button_checked_rounded;
        break;
      case CropEventStatus.upcoming:
        dotColor = AppColors.borderStrong;
        dotIcon = Icons.radio_button_unchecked_rounded;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Icon(dotIcon, color: dotColor, size: 20),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: event.status == CropEventStatus.upcoming ? AppColors.textSecondary : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(event.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                  const SizedBox(height: 2),
                  Text(
                    _dateLabel(event.date),
                    style: const TextStyle(fontSize: 11, color: AppColors.primary500, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime d) {
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
}
