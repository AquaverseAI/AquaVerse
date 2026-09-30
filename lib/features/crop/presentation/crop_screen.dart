import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class CropScreen extends ConsumerWidget {
  const CropScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);
    final pondAsync = ref.watch(currentPondProvider);
    final pond = pondAsync.valueOrNull;
    final logsAsync = ref.watch(pondLogsProvider);
    final logs = logsAsync.valueOrNull ?? const [];
    final eventsAsync = ref.watch(pondEventsProvider);
    final rawEvents = eventsAsync.valueOrNull ?? const [];

    final pondId = pond?.name ?? pond?.id ?? 'TN-01-001';
    final species = pond?.species ?? 'L. vannamei';
    final stockingDate = pond?.stockingDate ?? DateTime.now().subtract(const Duration(days: 42));
    final now = DateTime.now();
    final doc = now.difference(stockingDate).inDays.clamp(0, 365);

    // Aggregate metrics from real pond logs
    final cumulativeFeedKg = logs.fold<double>(0.0, (sum, l) => sum + (l.feedGivenKg ?? 0.0));
    final totalMortalities = logs.fold<int>(0, (sum, l) => sum + (l.mortalityCount ?? 0));

    // Realistic estimates based on pond area and feed data
    final areaSqM = pond?.areaSqM ?? 4000.0;
    final estimatedBiomassKg = cumulativeFeedKg > 0 ? (cumulativeFeedKg / 1.35) : (areaSqM * 0.8);
    final fcr = estimatedBiomassKg > 0 && cumulativeFeedKg > 0 ? (cumulativeFeedKg / estimatedBiomassKg) : 1.35;
    final expectedHarvestKg = (areaSqM * 1.15).clamp(1000.0, 15000.0);
    const costPerKg = 210.0;
    const marketPricePerKg = 380.0;
    final profitPerKg = (marketPricePerKg - costPerKg).clamp(50.0, 300.0);
    final expectedProfitMin = expectedHarvestKg * profitPerKg * 0.85;
    final expectedProfitMax = expectedHarvestKg * profitPerKg * 1.15;

    // Timeline events
    final List<CropEvent> timeline;
    if (rawEvents.isNotEmpty) {
      timeline = rawEvents.map((e) => CropEvent(
        label: e.type,
        date: e.timestamp,
        description: e.summary,
        status: e.timestamp.isBefore(now) ? CropEventStatus.completed : CropEventStatus.upcoming,
      )).toList();
    } else {
      timeline = [
        CropEvent(
          label: currentLang == 'ta' ? 'இருப்பு வைக்கப்பட்டது' : 'Stocking Day',
          date: stockingDate,
          description: currentLang == 'ta' ? '$species குஞ்சுகள் இருப்பு வைக்கப்பட்டன' : 'Post-larvae ($species) stocked',
          status: CropEventStatus.completed,
        ),
        CropEvent(
          label: currentLang == 'ta' ? 'தற்போதைய நிலை (DOC $doc)' : 'Current Progress (DOC $doc)',
          date: now,
          description: currentLang == 'ta'
              ? 'தீவனம்: ${cumulativeFeedKg.toStringAsFixed(1)} kg | இறப்பு: $totalMortalities'
              : 'Cumulative feed: ${cumulativeFeedKg.toStringAsFixed(1)} kg | Total mortality: $totalMortalities',
          status: CropEventStatus.active,
        ),
        CropEvent(
          label: currentLang == 'ta' ? 'மாதாந்திர மாதிரி சோதனை' : 'Mid-Cycle Sampling',
          date: stockingDate.add(const Duration(days: 60)),
          description: currentLang == 'ta' ? 'சராசரி உடல் எடை (ABW) சோதனை' : 'Average body weight (ABW) & health check',
          status: doc >= 60 ? CropEventStatus.completed : CropEventStatus.upcoming,
        ),
        CropEvent(
          label: currentLang == 'ta' ? 'திட்டமிடப்பட்ட அறுவடை' : 'Target Harvest',
          date: stockingDate.add(const Duration(days: 100)),
          description: currentLang == 'ta' ? 'இலக்கு: 30 எண்ணிக்கை / கிலோ' : 'Target count: ~30 pcs/kg',
          status: doc >= 100 ? CropEventStatus.completed : CropEventStatus.upcoming,
        ),
      ];
    }

    final docLabel = currentLang == 'ta' ? 'வளர்ப்பு நாட்கள்' : 'Days of Culture';
    final docVal = currentLang == 'ta' ? '$doc நாட்கள்' : '$doc days';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/today')),
        title: Text(
          currentLang == 'ta' ? 'பயிர்ப் பருவம் — $pondId' : 'Crop / Cycle — $pondId',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final text =
                'AquaVerse AI — Crop Summary\n'
                'Pond: $pondId\n'
                'Species: $species\n'
                'DOC: $doc days\n'
                'Cumulative Feed: ${cumulativeFeedKg.toStringAsFixed(1)} kg\n'
                'FCR: ${fcr.toStringAsFixed(2)}\n'
                'Expected Profit: ₹${_formatNum(expectedProfitMin)}–₹${_formatNum(expectedProfitMax)}';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(currentLang == 'ta' ? 'பயிர்ப் பருவ விவரம் நகலெடுக்கப்பட்டது' : 'Crop summary copied to clipboard')),
              );
            },
            icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentPondProvider);
          ref.invalidate(pondLogsProvider);
          ref.invalidate(pondEventsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  _MetricCard(label: docLabel, value: docVal, icon: Icons.calendar_today_rounded, color: AppColors.primary500),
                  _MetricCard(label: 'Est. FCR', value: fcr.toStringAsFixed(2), icon: Icons.bar_chart_rounded, color: AppColors.primary700),
                  _MetricCard(label: currentLang == 'ta' ? 'உற்பத்திச் செலவு/கிலோ' : 'Cost/kg', value: '₹${costPerKg.toInt()}', icon: Icons.account_balance_wallet_rounded, color: AppColors.warning),
                  _MetricCard(label: currentLang == 'ta' ? 'சந்தை விலை/கிலோ' : 'Market Price/kg', value: '₹${marketPricePerKg.toInt()}', icon: Icons.trending_up_rounded, color: AppColors.green600),
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
                          Text(
                            currentLang == 'ta' ? 'எதிர்பார்க்கப்படும் லாபம்' : 'Expected Profit',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_formatNum(expectedProfitMin)} – ₹${_formatNum(expectedProfitMax)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.green600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentLang == 'ta'
                                ? 'மதிப்பீடு — அறுவடை எடை மற்றும் சந்தை விலையைப் பொறுத்தது'
                                : 'Range estimate — actual depends on harvest weight & market price',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
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
                      Text(
                        currentLang == 'ta' ? 'மொத்தத் தீவனம்' : 'Cumulative Feed',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text('${cumulativeFeedKg.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ]),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        currentLang == 'ta' ? 'எதிர்பார்க்கப்படும் அறுவடை' : 'Expected Harvest',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text('${expectedHarvestKg.toInt()} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ]),
                  )),
                ],
              ),
              const SizedBox(height: 20),

              // ── Timeline ──────────────────────────────────────────────────────
              Text(
                currentLang == 'ta' ? 'பயிர்ப் பருவக் காலவரிசை' : 'Crop Timeline',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              ...timeline.asMap().entries.map((e) {
                final isLast = e.key == timeline.length - 1;
                return _TimelineItem(event: e.value, isLast: isLast);
              }),

              const SizedBox(height: 24),
            ],
          ),
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
