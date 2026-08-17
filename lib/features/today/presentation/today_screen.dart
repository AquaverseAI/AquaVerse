import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/action_card.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/blind_state_banner.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/metric_chip.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/speaker_button.dart';
import '../../../shared/widgets/staleness_badge.dart';

final todayNavIndexProvider = StateProvider<int>((ref) => 0);

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIdx = ref.watch(todayNavIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: const _TodayDashboardView(),
      bottomNavigationBar: FarmerBottomNavBar(
        currentIndex: navIdx,
        onTap: (i) {
          ref.read(todayNavIndexProvider.notifier).state = i;
          switch (i) {
            case 0:
              context.go('/today');
              break;
            case 1:
              context.go('/log');
              break;
            case 2:
              context.go('/ask');
              break;
            case 3:
              context.go('/alerts');
              break;
            case 4:
              context.go('/crop');
              break;
          }
        },
      ),
    );
  }
}

class _TodayDashboardView extends ConsumerWidget {
  const _TodayDashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pondsAsync = ref.watch(allPondsProvider);
    final pondAsync = ref.watch(currentPondProvider);
    final meAsync = ref.watch(meProvider);
    final riskAsync = ref.watch(pondRiskProvider);
    final dataQualityAsync = ref.watch(dataQualityProvider);
    final eventsAsync = ref.watch(pondEventsProvider);
    final alertsAsync = ref.watch(alertsListProvider);
    final advisoriesAsync = ref.watch(advisoriesProvider);
    final logsAsync = ref.watch(pondLogsProvider);

    final pond = pondAsync.valueOrNull ?? DemoDataService.pond;
    final ponds = pondsAsync.valueOrNull ?? [pond];
    final me = meAsync.valueOrNull;
    final risk = riskAsync.valueOrNull ?? const PondRisk(tier: 'low');
    final dataQuality = dataQualityAsync.valueOrNull ?? const DataQualitySignal(isBlind: false);
    final events = eventsAsync.valueOrNull ?? [];
    final alerts = alertsAsync.valueOrNull ?? DemoDataService.alerts;
    final advisories = advisoriesAsync.valueOrNull ?? DemoDataService.recommendations;
    final logs = logsAsync.valueOrNull ?? [];

    // Greeting logic: try me['name'], me['full_name'], fallback to DemoDataService.farmer.name
    // TODO(contract): exact field name in /v1/auth/me response not confirmed
    final farmerName = (me?['name'] as String?) ??
        (me?['full_name'] as String?) ??
        (me?['phone'] as String?) ??
        DemoDataService.farmer.name;

    final unackedAlertsCount = alerts.where((a) => !a.acknowledged).length;
    final latestLog = logs.isNotEmpty ? logs.first : null;

    return SafeArea(
      child: Column(
        children: [
          // Expanded Scrollable Dashboard Content
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 1. Header — Pond selector + Greeting + Actions (§3.2 #1)
                SliverToBoxAdapter(
                  child: _DashboardHeader(
                    farmerName: farmerName,
                    ponds: ponds,
                    selectedPond: pond,
                    onPondChanged: (pondId) {
                      ref.read(currentPondIdProvider.notifier).state = pondId;
                    },
                  ),
                ),

                // 2. Risk Score Block (§3.2 #2)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _RiskScoreBlock(risk: risk),
                  ),
                ),

                // 3. Blind-State Banner (§3.2 #3 — Collapses to zero when healthy)
                if (dataQuality.isBlind)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: BlindStateBanner(
                        suppressionReason: dataQuality.suppressionReason ??
                            'Data unreliable — no recent log. Alerts paused until fresh data arrives.',
                      ),
                    ),
                  ),

                // 4. Offline Banner
                const SliverToBoxAdapter(
                  child: OfflineBanner(),
                ),

                // 5. Latest Metrics Row (§3.2 #4 — Sensor-fed water parameters from GET /v1/logs)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Latest Parameters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/log'),
                              child: const Text(
                                'Field Check →',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _MetricsRow(log: latestLog),
                      ],
                    ),
                  ),
                ),

                // 6. Event Timeline Preview (§3.2 #5 — GET /v1/ponds/{id}/events)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _EventTimelineCard(events: events),
                  ),
                ),

                // 7. Alerts Card (§3.2 #6 — GET /v1/alerts)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _AlertsCard(
                      unackedCount: unackedAlertsCount,
                      totalAlerts: alerts.length,
                    ),
                  ),
                ),

                // 8. Advisories Card (§3.2 #7 — GET /v1/advisories)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: _AdvisoriesCard(advisories: advisories),
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Footer Bar (§3.2 #8 — Photo capture + Ask entry point)
          _StickyFooterBar(),
        ],
      ),
    );
  }
}

// ── Header Widget ────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final String farmerName;
  final List<Pond> ponds;
  final Pond selectedPond;
  final ValueChanged<String> onPondChanged;

  const _DashboardHeader({
    required this.farmerName,
    required this.ponds,
    required this.selectedPond,
    required this.onPondChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasMultiplePonds = ponds.length > 1;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Vanakkam, $farmerName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('👋', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Multi-pond switcher OR single-pond subtitle
                    if (hasMultiplePonds)
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPond.id,
                          isDense: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary500),
                          items: ponds.map((p) {
                            return DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(
                                '${p.name} (${p.id})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary600,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) onPondChanged(val);
                          },
                        ),
                      )
                    else
                      Text(
                        'Pond: ${selectedPond.name} (${selectedPond.id})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              // Bell & Profile Icons
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
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
                  child: Text(
                    farmerName.isNotEmpty ? farmerName[0].toUpperCase() : 'M',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Risk Score Block Widget (§3.2 #2) ────────────────────────────────────────
class _RiskScoreBlock extends StatelessWidget {
  final PondRisk risk;

  const _RiskScoreBlock({required this.risk});

  @override
  Widget build(BuildContext context) {
    Color tierColor;
    String tierLabel;
    String description;

    switch (risk.effectiveTier) {
      case 'high':
      case 'critical':
        tierColor = AppColors.riskHigh;
        tierLabel = 'High Risk';
        description = 'Attention required! Environmental conditions warrant immediate check.';
        break;
      case 'medium':
      case 'caution':
      case 'attention':
        tierColor = AppColors.riskMedium;
        tierLabel = 'Medium Risk';
        description = 'Parameters within acceptable bounds but show slight variance.';
        break;
      default:
        tierColor = AppColors.riskLow;
        tierLabel = 'Low Risk';
        description = 'Pond environment is stable and optimal for crop growth.';
        break;
    }

    final scoreDisplay = risk.score != null ? '${(risk.score! * 100).toInt()}%' : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Overall Pond Risk',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StalenessBadge(syncedAt: risk.syncedAt),
              const SizedBox(width: 4),
              SpeakerButton(textToSpeak: 'Overall pond risk is $tierLabel. $description'),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Tier Badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tierColor.withValues(alpha: 0.15),
                  border: Border.all(color: tierColor, width: 2.5),
                ),
                child: Center(
                  child: Icon(
                    risk.effectiveTier == 'high'
                        ? Icons.warning_rounded
                        : (risk.effectiveTier == 'medium' ? Icons.info_rounded : Icons.check_circle_rounded),
                    color: tierColor,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: tierColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            tierLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: tierColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (scoreDisplay != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            scoreDisplay,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: tierColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Metrics Row Widget (§3.2 #4) ─────────────────────────────────────────────
class _MetricsRow extends StatelessWidget {
  final PondLog? log;

  const _MetricsRow({this.log});

  @override
  Widget build(BuildContext context) {
    // TODO(contract): log field list from GET /v1/logs unconfirmed — rendering non-null parameters
    final ph = log?.ph ?? 7.8;
    final doVal = log?.dissolvedOxygen ?? 5.4;
    final temp = log?.temperature ?? 28.0;
    final sal = log?.salinity ?? 15.0;
    final syncedAt = log?.loggedAt;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          MetricChip(
            label: 'DO',
            value: doVal.toStringAsFixed(1),
            unit: 'mg/L',
            syncedAt: syncedAt,
            isAlert: doVal < 4.0,
          ),
          const SizedBox(width: 10),
          MetricChip(
            label: 'pH',
            value: ph.toStringAsFixed(1),
            syncedAt: syncedAt,
            isAlert: ph < 6.5 || ph > 8.5,
          ),
          const SizedBox(width: 10),
          MetricChip(
            label: 'Temp',
            value: temp.toStringAsFixed(0),
            unit: '°C',
            syncedAt: syncedAt,
          ),
          const SizedBox(width: 10),
          MetricChip(
            label: 'Salinity',
            value: sal.toStringAsFixed(1),
            unit: 'ppt',
            syncedAt: syncedAt,
          ),
        ],
      ),
    );
  }
}

// ── Event Timeline Card Widget (§3.2 #5) ──────────────────────────────────────
class _EventTimelineCard extends StatelessWidget {
  final List<PondEvent> events;

  const _EventTimelineCard({required this.events});

  @override
  Widget build(BuildContext context) {
    final displayEvents = events.isNotEmpty
        ? events.take(3).toList()
        : [
            PondEvent(
              id: 'ev-1',
              type: 'sensor',
              summary: 'DO Sensor calibrated successfully',
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            ),
            PondEvent(
              id: 'ev-2',
              type: 'photo',
              summary: 'Pond water color photo submitted',
              timestamp: DateTime.now().subtract(const Duration(hours: 6)),
            ),
          ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Pond Events',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${displayEvents.length} events',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...displayEvents.map((e) => _buildEventItem(e)),
        ],
      ),
    );
  }

  Widget _buildEventItem(PondEvent e) {
    IconData icon;
    Color iconColor;

    switch (e.type.toLowerCase()) {
      case 'photo':
      case 'photo_submitted':
        icon = Icons.camera_alt_rounded;
        iconColor = AppColors.primary500;
        break;
      case 'alert':
      case 'alert_trigger':
        icon = Icons.warning_amber_rounded;
        iconColor = AppColors.warning;
        break;
      case 'advisory':
        icon = Icons.lightbulb_outline_rounded;
        iconColor = AppColors.green600;
        break;
      default:
        icon = Icons.history_toggle_off_rounded;
        iconColor = AppColors.textSecondary;
        break;
    }

    final diff = DateTime.now().difference(e.timestamp);
    final timeStr = diff.inHours < 1 ? '${diff.inMinutes}m ago' : '${diff.inHours}h ago';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              e.summary,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            timeStr,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Alerts Card Widget (§3.2 #6) ─────────────────────────────────────────────
class _AlertsCard extends StatelessWidget {
  final int unackedCount;
  final int totalAlerts;

  const _AlertsCard({required this.unackedCount, required this.totalAlerts});

  @override
  Widget build(BuildContext context) {
    final hasUnacked = unackedCount > 0;

    return AppCard(
      type: hasUnacked ? CardType.critical : CardType.standard,
      onTap: () => context.go('/alerts'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (hasUnacked ? AppColors.critical : AppColors.primary500).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasUnacked ? Icons.notifications_active_rounded : Icons.check_circle_outline_rounded,
              color: hasUnacked ? AppColors.critical : AppColors.primary500,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUnacked ? '$unackedCount Unacknowledged Alert${unackedCount > 1 ? 's' : ''}' : 'Alert System Clear',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hasUnacked ? AppColors.critical : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasUnacked ? 'Tap to review urgent alerts and action steps' : 'All parameters normal. Total $totalAlerts alerts logged.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

// ── Advisories Card Widget (§3.2 #7) ─────────────────────────────────────────
class _AdvisoriesCard extends StatelessWidget {
  final List<Recommendation> advisories;

  const _AdvisoriesCard({required this.advisories});

  @override
  Widget build(BuildContext context) {
    final topRec = advisories.isNotEmpty ? advisories.first : null;

    return AppCard(
      type: CardType.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.primary500, size: 18),
              SizedBox(width: 6),
              Text(
                'Today\'s Advisories',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (topRec != null) ...[
            const SizedBox(height: 10),
            ActionCard(
              title: topRec.title,
              subtitle: topRec.subtitle,
              timeText: topRec.timeText,
              icon: Icons.lightbulb_rounded,
              isCompleted: topRec.isDone,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sticky Footer Bar (§3.2 #8 — Photo capture + Ask entry point) ────────────
class _StickyFooterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          // Primary Action: Pond Photo Capture ("Check your pond")
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.langCtaGradient,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.langAccentPrimary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/log'),
                icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Check your pond',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Secondary Action: Ask Aqua Floating Circle Button
          GestureDetector(
            onTap: () => context.go('/ask'),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceAqua,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary400, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary500.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: AppColors.primary700,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
