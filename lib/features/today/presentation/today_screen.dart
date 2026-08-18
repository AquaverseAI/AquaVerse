import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/action_card.dart';
import '../../../shared/widgets/blind_state_banner.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/metric_chip.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/speaker_button.dart';
import '../../../shared/widgets/staleness_badge.dart';

final todayNavIndexProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// TodayScreen — Root
// ─────────────────────────────────────────────────────────────────────────────
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIdx = ref.watch(todayNavIndexProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: const _DashboardAmbientBackground(child: _TodayDashboardView()),
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

// ─────────────────────────────────────────────────────────────────────────────
// §3.1 Ambient Background: static clean underwater-light gradient
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardAmbientBackground extends StatelessWidget {
  final Widget child;

  const _DashboardAmbientBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientBgAmbient),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Dashboard View — data watcher + load-in choreography
// ─────────────────────────────────────────────────────────────────────────────
class _TodayDashboardView extends ConsumerStatefulWidget {
  const _TodayDashboardView();

  @override
  ConsumerState<_TodayDashboardView> createState() => _TodayDashboardViewState();
}

class _TodayDashboardViewState extends ConsumerState<_TodayDashboardView>
    with TickerProviderStateMixin {
  late final List<AnimationController> _loadInControllers;
  late final List<Animation<double>> _loadInFades;
  late final List<Animation<double>> _loadInRises;

  bool _isReducedMotion = false;

  @override
  void initState() {
    super.initState();
    _isReducedMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    // 10-section staggered entrance (~60ms stagger)
    _loadInControllers = List.generate(
      10,
      (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 280)),
    );
    _loadInFades = _loadInControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _loadInRises = _loadInControllers
        .map((c) => Tween<double>(begin: 10.0, end: 0.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    _startLoadInChoreography();
  }

  void _startLoadInChoreography() async {
    if (_isReducedMotion) {
      for (final c in _loadInControllers) {
        c.value = 1.0;
      }
      return;
    }
    for (int i = 0; i < _loadInControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) _loadInControllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _loadInControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _sectionFadeRise(int index, Widget child) {
    return FadeTransition(
      opacity: _loadInFades[index],
      child: AnimatedBuilder(
        animation: _loadInRises[index],
        builder: (_, _) => Transform.translate(
          offset: Offset(0, _loadInRises[index].value),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final farmerName = (me?['name'] as String?) ??
        (me?['full_name'] as String?) ??
        (me?['phone'] as String?) ??
        DemoDataService.farmer.name;

    final unackedAlertsCount = alerts.where((a) => !a.acknowledged).length;
    final latestLog = logs.isNotEmpty ? logs.first : null;

    return SafeArea(
      child: Column(
        children: [
          // Scrollable body
          Expanded(
            child: CustomScrollView(
              slivers: [
                // §3.2 Header — Tier 0 (flat against background, no card)
                SliverToBoxAdapter(
                  child: _sectionFadeRise(
                    0,
                    _DashboardHeader(
                      farmerName: farmerName,
                      ponds: ponds,
                      selectedPond: pond,
                      hasUnackedAlerts: unackedAlertsCount > 0,
                      onPondChanged: (id) =>
                          ref.read(currentPondIdProvider.notifier).state = id,
                    ),
                  ),
                ),

                // §3.3 Risk Score Block — Tier 2 (hero element, steady disc)
                SliverToBoxAdapter(
                  child: _sectionFadeRise(
                    1,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _RiskDiscBlock(risk: risk),
                    ),
                  ),
                ),

                // §3.4 Blind-State Banner — Tier 2 when active
                SliverToBoxAdapter(
                  child: _sectionFadeRise(
                    2,
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: _isReducedMotion
                          ? Curves.easeOut
                          : const _SpringCurve(),
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.3),
                          end: Offset.zero,
                        ).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: dataQuality.isBlind
                          ? Padding(
                              key: const ValueKey('blind-active'),
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                              child: _Tier2Wrapper(
                                child: BlindStateBanner(
                                  suppressionReason: dataQuality.suppressionReason ??
                                      'Data unreliable — no recent log. Alerts paused until fresh data arrives.',
                                ),
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('blind-inactive')),
                    ),
                  ),
                ),

                // Offline Banner
                SliverToBoxAdapter(
                  child: _sectionFadeRise(3, const OfflineBanner()),
                ),

                // §3.5 Latest Metrics Row — Tier 1 glass MetricChip scroll
                SliverToBoxAdapter(
                  child: _sectionFadeRise(
                    4,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Latest Parameters',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/log'),
                                child: const Text(
                                  'Field Check →',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.langAccentPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _MetricsScrollRow(log: latestLog),
                        ],
                      ),
                    ),
                  ),
                ),

                // §3.6 Event Timeline — Tier 1 glass card, nested icon chips
                SliverToBoxAdapter(
                  child: _sectionFadeRise(
                    5,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _EventTimelineCard(events: events),
                    ),
                  ),
                ),

                // §3.7 Alerts Card — Static clean display
                SliverToBoxAdapter(
                  child: _sectionFadeRise(
                    6,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _AlertsCard(
                        unackedCount: unackedAlertsCount,
                        totalAlerts: alerts.length,
                      ),
                    ),
                  ),
                ),

                // §3.8 Forecast Card — Stubbed state per unresolved contract gap
                SliverToBoxAdapter(
                  child: _sectionFadeRise(
                    7,
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _ForecastStubCard(),
                    ),
                  ),
                ),

                // §3.9 Advisories Card — Tier 1, calm display
                SliverToBoxAdapter(
                  child: _sectionFadeRise(
                    8,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: _AdvisoriesCard(advisories: advisories),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // §3.10 Sticky Footer Bar — Clean steady CTA bar
          _sectionFadeRise(
            9,
            const _StickyFooterBar(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3.2 Header — Tier 0 (no card, clean static bell)
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeader extends ConsumerWidget {
  final String farmerName;
  final List<Pond> ponds;
  final Pond selectedPond;
  final bool hasUnackedAlerts;
  final ValueChanged<String> onPondChanged;

  const _DashboardHeader({
    required this.farmerName,
    required this.ponds,
    required this.selectedPond,
    required this.hasUnackedAlerts,
    required this.onPondChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMultiplePonds = ponds.length > 1;
    final currentLang = ref.watch(appLanguageProvider);
    final greeting = AppTranslations.getText('vanakkam', currentLang);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$greeting $farmerName 👋',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (hasMultiplePonds)
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedPond.id,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded,
                          color: AppColors.langAccentPrimary, size: 18),
                      items: ponds.map((p) {
                        return DropdownMenuItem<String>(
                          value: p.id,
                          child: Text(
                            '${p.name} · ${p.id}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.langAccentPrimary,
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
                    '${selectedPond.name} · ${selectedPond.id}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Bell button — clean static icon with unread red dot
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary, size: 24),
                if (hasUnackedAlerts)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.riskHigh,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Profile avatar
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.gradient3DPrimary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowTier1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  farmerName.isNotEmpty ? farmerName[0].toUpperCase() : 'M',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3.3 Risk Disc Block — Tier 2: steady 3D disc with subtle static highlight
// ─────────────────────────────────────────────────────────────────────────────
class _RiskDiscBlock extends ConsumerWidget {
  final PondRisk risk;

  const _RiskDiscBlock({required this.risk});

  LinearGradient get _discGradient {
    switch (risk.effectiveTier) {
      case 'high':
      case 'critical':
        return AppColors.gradient3DHighRisk;
      case 'medium':
      case 'caution':
      case 'attention':
        return AppColors.gradient3DMediumRisk;
      default:
        return AppColors.gradient3DPrimary;
    }
  }

  Color get _tierGlowColor {
    switch (risk.effectiveTier) {
      case 'high':
      case 'critical':
        return AppColors.riskHigh;
      case 'medium':
        return AppColors.riskMedium;
      default:
        return AppColors.riskLow;
    }
  }

  String _getTierLabel(String lang) {
    switch (risk.effectiveTier) {
      case 'high':
      case 'critical':
        return AppTranslations.getText('highRisk', lang);
      case 'medium':
        return AppTranslations.getText('mediumRisk', lang);
      default:
        return AppTranslations.getText('lowRisk', lang);
    }
  }

  String _getTierDescription(String lang) {
    switch (risk.effectiveTier) {
      case 'high':
      case 'critical':
        return AppTranslations.getText('highRiskDesc', lang);
      case 'medium':
        return AppTranslations.getText('mediumRiskDesc', lang);
      default:
        return AppTranslations.getText('lowRiskDesc', lang);
    }
  }

  IconData get _tierIcon {
    switch (risk.effectiveTier) {
      case 'high':
      case 'critical':
        return Icons.warning_rounded;
      case 'medium':
        return Icons.info_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);
    final tierLabel = _getTierLabel(currentLang);
    final tierDesc = _getTierDescription(currentLang);

    final scoreDisplay =
        risk.score != null ? '${(risk.score! * 100).toInt()}%' : null;

    return _Tier2GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3D Disc — static, clean elevation
          Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _discGradient,
                  boxShadow: [
                    BoxShadow(
                      color: _tierGlowColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Inner top-left highlight — static 3D sphere look
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.45),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(_tierIcon, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
              if (scoreDisplay != null) ...[
                const SizedBox(height: 4),
                Text(
                  scoreDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _tierGlowColor,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(width: 16),

          // Right side: label, description, staleness
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppTranslations.getText('overallPondRisk', currentLang),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    SpeakerButton(
                        textToSpeak:
                            'Overall pond risk is $tierLabel. $tierDesc'),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _tierGlowColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _tierGlowColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(
                    tierLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _tierGlowColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tierDesc,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                StalenessBadge(syncedAt: risk.syncedAt),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3.5 Metrics Scroll Row — Tier 1 MetricChip glass chips
// ─────────────────────────────────────────────────────────────────────────────
class _MetricsScrollRow extends ConsumerWidget {
  final PondLog? log;

  const _MetricsScrollRow({this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);
    final ph = log?.ph ?? 7.8;
    final doVal = log?.dissolvedOxygen ?? 5.4;
    final temp = log?.temperature ?? 28.0;
    final sal = log?.salinity ?? 15.0;
    final syncedAt = log?.loggedAt;

    final doLabel = currentLang == 'ta' ? 'கரைந்த ஆக்சிஜன்' : 'DO';
    final tempLabel = currentLang == 'ta' ? 'வெப்பநிலை' : 'Temp';
    final salLabel = currentLang == 'ta' ? 'உவர்ப்புத் தன்மை' : 'Salinity';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          MetricChip(
            label: doLabel,
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
            label: tempLabel,
            value: temp.toStringAsFixed(0),
            unit: '°C',
            syncedAt: syncedAt,
          ),
          const SizedBox(width: 10),
          MetricChip(
            label: salLabel,
            value: sal.toStringAsFixed(1),
            unit: 'ppt',
            syncedAt: syncedAt,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3.6 Event Timeline Card — Tier 1, nested icon chips
// ─────────────────────────────────────────────────────────────────────────────
class _EventTimelineCard extends ConsumerWidget {
  final List<PondEvent> events;

  const _EventTimelineCard({required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);

    final displayEvents = events.isNotEmpty
        ? events.take(3).toList()
        : [
            PondEvent(
              id: 'ev-1',
              type: 'sensor',
              summary: currentLang == 'ta'
                  ? 'DO சென்சார் வெற்றிகரமாக அளவீடு செய்யப்பட்டது'
                  : 'DO Sensor calibrated successfully',
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            ),
            PondEvent(
              id: 'ev-2',
              type: 'photo',
              summary: currentLang == 'ta'
                  ? 'குளத்து நீரின் புகைப்படம் சமர்ப்பிக்கப்பட்டது'
                  : 'Pond water color photo submitted',
              timestamp: DateTime.now().subtract(const Duration(hours: 6)),
            ),
          ];

    return _Tier1GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.getText('recentEvents', currentLang),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                currentLang == 'ta' ? '${displayEvents.length} நிகழ்வுகள்' : '${displayEvents.length} events',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...displayEvents.map((e) => _buildEventRow(e)),
        ],
      ),
    );
  }

  Widget _buildEventRow(PondEvent e) {
    IconData icon;
    Color iconColor;

    switch (e.type.toLowerCase()) {
      case 'photo':
      case 'photo_submitted':
        icon = Icons.camera_alt_rounded;
        iconColor = AppColors.langAccentPrimary;
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
    final timeStr = diff.inHours < 1
        ? '${diff.inMinutes}m ago'
        : '${diff.inHours}h ago';

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: iconColor.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              e.summary,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3.7 Alerts Card — Static clean alert display
// ─────────────────────────────────────────────────────────────────────────────
class _AlertsCard extends StatelessWidget {
  final int unackedCount;
  final int totalAlerts;

  const _AlertsCard({
    required this.unackedCount,
    required this.totalAlerts,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnacked = unackedCount > 0;

    return _Tier1GlassCard(
      onTap: () => context.go('/alerts'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasUnacked
                  ? AppColors.riskHigh.withValues(alpha: 0.12)
                  : AppColors.riskLow.withValues(alpha: 0.12),
            ),
            child: Icon(
              hasUnacked
                  ? Icons.notifications_active_rounded
                  : Icons.check_circle_outline_rounded,
              color: hasUnacked ? AppColors.riskHigh : AppColors.riskLow,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUnacked
                      ? '$unackedCount Unacknowledged Alert${unackedCount > 1 ? 's' : ''}'
                      : 'Alert System Clear',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hasUnacked ? AppColors.riskHigh : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasUnacked
                      ? 'Tap to review urgent alerts and action steps'
                      : 'All parameters normal. $totalAlerts alerts total.',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
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

// TODO(contract): Dedicated forecast endpoint (/v1/forecast/do) is missing from confirmed endpoint contract.
// Displaying a calm "Forecast Unavailable" state until response shape inside /v1/ponds/{pond_id}/risk is confirmed.
class _ForecastStubCard extends StatelessWidget {
  const _ForecastStubCard();

  @override
  Widget build(BuildContext context) {
    return _Tier1GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.show_chart_rounded, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '24-Hour DO Forecast',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Forecast band pending backend contract confirmation',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3.9 Advisories Card — Tier 1, calm display
// ─────────────────────────────────────────────────────────────────────────────
class _AdvisoriesCard extends StatelessWidget {
  final List<Recommendation> advisories;

  const _AdvisoriesCard({required this.advisories});

  @override
  Widget build(BuildContext context) {
    final topRec = advisories.isNotEmpty ? advisories.first : null;

    return _Tier1GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: AppColors.langAccentPrimary, size: 16),
              SizedBox(width: 6),
              Text(
                "Today's Advisories",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          if (topRec != null) ...[
            const SizedBox(height: 12),
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

// ─────────────────────────────────────────────────────────────────────────────
// §3.9 Sticky Footer Bar — Clean steady CTA bar with touch feedback
// ─────────────────────────────────────────────────────────────────────────────
class _StickyFooterBar extends StatefulWidget {
  const _StickyFooterBar();

  @override
  State<_StickyFooterBar> createState() => _StickyFooterBarState();
}

class _StickyFooterBarState extends State<_StickyFooterBar> {
  bool _ctaPressed = false;
  bool _micPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowTier1,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // "Check your pond" CTA
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => setState(() => _ctaPressed = true),
              onTapUp: (_) {
                setState(() => _ctaPressed = false);
                context.go('/log');
              },
              onTapCancel: () => setState(() => _ctaPressed = false),
              child: AnimatedScale(
                scale: _ctaPressed ? 0.97 : 1.0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient3DPrimary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowTier2,
                        blurRadius: _ctaPressed ? 4 : 12,
                        offset: Offset(0, _ctaPressed ? 2 : 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Check your pond',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Ask mic icon button
          GestureDetector(
            onTapDown: (_) => setState(() => _micPressed = true),
            onTapUp: (_) {
              setState(() => _micPressed = false);
              context.go('/ask');
            },
            onTapCancel: () => setState(() => _micPressed = false),
            child: AnimatedScale(
              scale: _micPressed ? 0.94 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradientCardGlass,
                  border: Border.all(
                    color: AppColors.riskLow.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowTier1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppColors.langAccentPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Glass Card Primitives — static elevation tier system
// ─────────────────────────────────────────────────────────────────────────────

/// Tier 1 — Resting glass card.
class _Tier1GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Tier1GlassCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradientCardGlass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.7), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowTier1,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
    );
  }
}

/// Tier 2 — Elevated glass card.
class _Tier2GlassCard extends StatelessWidget {
  final Widget child;

  const _Tier2GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradientCardGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.langAccentPrimary.withValues(alpha: 0.2),
            width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowTier2,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

/// Wraps a child in Tier-2 visual treatment.
class _Tier2Wrapper extends StatelessWidget {
  final Widget child;

  const _Tier2Wrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowTier2,
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spring curve for blind-state banner slide-in
// ─────────────────────────────────────────────────────────────────────────────
class _SpringCurve extends Curve {
  const _SpringCurve();

  @override
  double transformInternal(double t) {
    return 1.0 -
        math.exp(-10.0 * t) * math.cos(math.pi * 2.2 * t) * (1.0 - t) * 1.1;
  }
}
