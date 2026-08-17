import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/services/demo_data_service.dart'; // Still used for farmer/crop placeholders
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/action_card.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/blind_state_banner.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/speaker_button.dart';
import '../../../shared/widgets/staleness_badge.dart';
import '../../../shared/widgets/status_disc.dart';

final todayNavIndexProvider = StateProvider<int>((ref) => 0);

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIdx = ref.watch(todayNavIndexProvider);

    Widget body;
    switch (navIdx) {
      case 1: body = const SizedBox.shrink(); break;
      case 2: body = const SizedBox.shrink(); break;
      case 3: body = const SizedBox.shrink(); break;
      case 4: body = const SizedBox.shrink(); break;
      default: body = const _TodayBodyLoader();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: body,
      bottomNavigationBar: FarmerBottomNavBar(
        currentIndex: navIdx,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/today'); break;
            case 1: context.go('/log'); break;
            case 2: context.go('/ask'); break;
            case 3: context.go('/alerts'); break;
            case 4: context.go('/crop'); break;
          }
        },
      ),
    );
  }
}

class _TodayBodyLoader extends ConsumerWidget {
  const _TodayBodyLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pondAsync = ref.watch(currentPondProvider);
    final paramsAsync = ref.watch(currentPondParamsProvider);
    final recsAsync = ref.watch(recommendationsProvider);

    if (pondAsync.isLoading || paramsAsync.isLoading || recsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary500));
    }

    if (pondAsync.hasError || paramsAsync.hasError || recsAsync.hasError) {
      final err = pondAsync.error ?? paramsAsync.error ?? recsAsync.error;
      return Center(child: Text('Error loading data: $err', style: const TextStyle(color: AppColors.critical), textAlign: TextAlign.center));
    }

    return _TodayBody(
      pond: pondAsync.value!,
      params: paramsAsync.value!,
      recs: recsAsync.value!,
    );
  }
}

class _TodayBody extends ConsumerWidget {
  final Pond pond;
  final PondParams params;
  final List<Recommendation> recs;

  const _TodayBody({
    required this.pond,
    required this.params,
    required this.recs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(doForecastProvider);
    final forecast = forecastAsync.valueOrNull ?? DemoDataService.doForecast();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(context)),

          // ── Blind state banner (if applicable) ──────────────────────────────
          if (params.isBlindState)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BlindStateBanner(
                  suppressionReason: params.suppressionReason ??
                      'Data unreliable — no log in 3 days. Alerts paused until fresh data arrives.',
                ),
              ),
            ),

          // ── Offline banner ──────────────────────────────────────────────────
          const SliverToBoxAdapter(child: OfflineBanner()),

          // ── Pond status card ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _PondStatusCard(pond: pond, params: params),
            ),
          ),

          // ── Today's recommendations ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: "Today's Recommendations"),
                  const SizedBox(height: 10),
                  ...recs.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ActionCard(
                      title: r.title,
                      subtitle: r.subtitle,
                      timeText: r.timeText,
                      icon: _recIcon(r.icon),
                      isCompleted: r.isDone,
                    ),
                  )),
                ],
              ),
            ),
          ),

          // ── Risk level ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Overall Risk',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ),
                        if (!params.isBlindState)
                           StalenessBadge(syncedAt: params.recordedAt),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const RiskLevelBar(level: 'low'),
                  ],
                ),
              ),
            ),
          ),

          // ── DO Forecast chart ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _DOForecastCard(
                forecast: forecast,
                isLowConfidence: params.isLowConfidence,
              ),
            ),
          ),

          // ── Stat chips ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _StatChipsRow(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Vanakkam, ${DemoDataService.farmer.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('👋', style: TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Pond ID: ${DemoDataService.farmer.pondId}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
                Positioned(
                  top: -2, right: -2,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.critical,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary100,
              child: const Text(
                'M',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _recIcon(RecommendationIcon icon) {
    switch (icon) {
      case RecommendationIcon.feed:     return Icons.set_meal_rounded;
      case RecommendationIcon.aerator:  return Icons.air_rounded;
      case RecommendationIcon.waterCheck: return Icons.opacity_rounded;
      case RecommendationIcon.medicine: return Icons.medical_services_rounded;
      case RecommendationIcon.harvest:  return Icons.agriculture_rounded;
    }
  }
}

// ── Pond status card ─────────────────────────────────────────────────────────
class _PondStatusCard extends StatelessWidget {
  final Pond pond;
  final PondParams params;

  const _PondStatusCard({required this.pond, required this.params});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      type: pond.status == PondStatus.good ? CardType.healthy : CardType.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pond Status',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
              StalenessBadge(syncedAt: pond.lastUpdated),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatusDisc(
                status: pond.status == PondStatus.good
                    ? PondStatusLevel.good
                    : pond.status == PondStatus.caution
                        ? PondStatusLevel.caution
                        : PondStatusLevel.critical,
              ),
              const Spacer(),
              const SpeakerButton(
                textToSpeak: 'Pond status is Good. Data as of 4 hours ago.',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'இல் பொது நிலை சீராக உள்ளது',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ParamTile(label: 'pH', value: params.ph.toStringAsFixed(1)),
              _ParamTile(label: 'DO (mg/L)', value: params.dissolvedOxygen.toStringAsFixed(1), highlight: params.dissolvedOxygen < 4.0),
              _ParamTile(label: 'Temp (°C)', value: params.temperature.toStringAsFixed(0)),
              _ParamTile(label: 'Salinity', value: params.salinity.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParamTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ParamTile({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.critical : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── DO Forecast chart ─────────────────────────────────────────────────────────
class _DOForecastCard extends StatelessWidget {
  final List<DOForecastPoint> forecast;
  final bool isLowConfidence;

  const _DOForecastCard({required this.forecast, required this.isLowConfidence});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      type: CardType.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Overnight DO Forecast',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              if (isLowConfidence)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: const Text(
                    'Low confidence',
                    style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
                  ),
                ),
              const SpeakerButton(textToSpeak: 'Dissolved oxygen forecast. Overnight drop expected.'),
            ],
          ),
          const SizedBox(height: 6),

          // Legend
          const Row(
            children: [
              _LegendDot(color: AppColors.green600, label: 'Safe'),
              SizedBox(width: 12),
              _LegendDot(color: AppColors.warning, label: 'Caution'),
              SizedBox(width: 12),
              _LegendDot(color: AppColors.critical, label: 'Danger'),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 9,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 3,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                      reservedSize: 24,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4,
                      getTitlesWidget: (v, _) {
                        final int idx = v.toInt();
                        if (idx < 0 || idx >= forecast.length) return const SizedBox.shrink();
                        final h = forecast[idx].time.hour;
                        return Text(
                          '$h:00',
                          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                        );
                      },
                      reservedSize: 18,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                // Danger zone horizontal band
                rangeAnnotations: RangeAnnotations(
                  horizontalRangeAnnotations: [
                    HorizontalRangeAnnotation(
                      y1: 0,
                      y2: 4,
                      color: AppColors.criticalSurface,
                    ),
                    HorizontalRangeAnnotation(
                      y1: 4,
                      y2: 5,
                      color: AppColors.warningSurface,
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: forecast.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.value);
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.primary500,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) {
                        final isDanger = spot.y < 4.0;
                        return FlDotCirclePainter(
                          radius: 3,
                          color: isDanger ? AppColors.critical : AppColors.primary500,
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary500.withValues(alpha: 0.2),
                          AppColors.primary500.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Stat chips row ────────────────────────────────────────────────────────────
class _StatChipsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final crop = DemoDataService.cropCycle;
    final now  = DateTime.now();
    final daysOfCulture = now.difference(crop.stockingDate).inDays;
    final daysToHarvest = crop.harvestDate != null
        ? crop.harvestDate!.difference(now).inDays
        : 55;

    return Row(
      children: [
        Expanded(child: StatChip(label: 'Days of Culture', value: '$daysOfCulture days')),
        const SizedBox(width: 8),
        Expanded(child: StatChip(label: 'Biomass (est.)', value: '${(daysOfCulture * 0.16).toStringAsFixed(0)} kg', color: AppColors.primary500)),
        const SizedBox(width: 8),
        Expanded(child: StatChip(label: 'Days to Harvest', value: '$daysToHarvest days', color: AppColors.warning)),
      ],
    );
  }
}
