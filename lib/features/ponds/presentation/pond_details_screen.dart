import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/staleness_badge.dart';
import '../../../shared/widgets/status_disc.dart';

class PondDetailsScreen extends StatefulWidget {
  const PondDetailsScreen({super.key});

  @override
  State<PondDetailsScreen> createState() => _PondDetailsScreenState();
}

class _PondDetailsScreenState extends State<PondDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pond   = DemoDataService.pond;
    final params = DemoDataService.params;
    final trend  = DemoDataService.weeklyTrend();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: AppColors.deepNavy,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.deepNavy,
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(pond.id, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(width: 10),
                        StatusDisc(status: PondStatusLevel.good, showLabel: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(pond.name, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                    Text(pond.location, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              title: Text(pond.id, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.brightMint,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Summary'),
                Tab(text: 'Charts'),
                Tab(text: 'Logs'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Summary tab ──────────────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  StalenessBadge(syncedAt: pond.lastUpdated),
                  const SizedBox(height: 12),

                  // Pond info
                  AppCard(
                    child: Column(
                      children: [
                        _InfoRow('Species', pond.species),
                        const Divider(height: 1),
                        _InfoRow('Area', '${pond.areaSqM.toInt()} m²'),
                        const Divider(height: 1),
                        _InfoRow('Depth', '${pond.depthM} m'),
                        const Divider(height: 1),
                        _InfoRow('Liner Type', pond.linerType),
                        const Divider(height: 1),
                        _InfoRow('Water Source', pond.waterSource),
                        const Divider(height: 1),
                        _InfoRow('Stocking Date', _dateStr(pond.stockingDate)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current parameters
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Parameters', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ParamDisc(label: 'pH', value: params.ph.toStringAsFixed(1), color: AppColors.seaGreen),
                            _ParamDisc(label: 'DO', value: '${params.dissolvedOxygen} mg/L', color: params.dissolvedOxygen < 4.0 ? AppColors.critical : AppColors.success),
                            _ParamDisc(label: 'Temp', value: '${params.temperature}°C', color: AppColors.aqua),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Charts tab ────────────────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('7-Day DO Trend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  AppCard(
                    child: SizedBox(
                      height: 160,
                      child: LineChart(
                        LineChartData(
                          minY: 0, maxY: 9,
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 3, reservedSize: 24, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)))),
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                              const days = ['M','T','W','T','F','S','S'];
                              final i = v.toInt();
                              if (i < 0 || i >= days.length) return const SizedBox.shrink();
                              return Text(days[i], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                            }, reservedSize: 16)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['do']!)).toList(),
                              isCurved: true,
                              color: AppColors.seaGreen,
                              barWidth: 2.5,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.seaGreen.withValues(alpha: 0.15), Colors.transparent])),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('7-Day pH Trend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  AppCard(
                    child: SizedBox(
                      height: 120,
                      child: LineChart(
                        LineChartData(
                          minY: 6, maxY: 10,
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['ph']!)).toList(),
                              isCurved: true,
                              color: AppColors.aqua,
                              barWidth: 2.5,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Logs tab ──────────────────────────────────────────────────────
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final day = DateTime.now().subtract(Duration(days: i));
                return AppCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.seaGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: AppColors.seaGreen, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Log — ${_dateStr(day)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text('Feed: ${(18 - i * 0.5).toStringAsFixed(1)} kg · DO: ${(5.2 - i * 0.1).toStringAsFixed(1)} mg/L', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _dateStr(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      ],
    ),
  );
}

class _ParamDisc extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ParamDisc({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Center(child: Text(value.split(' ')[0], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color))),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ],
  );
}
