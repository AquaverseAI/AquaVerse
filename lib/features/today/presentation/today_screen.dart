import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
// §3.1 Ambient Background: gradient + slow drifting water-light blob
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardAmbientBackground extends StatefulWidget {
  final Widget child;

  const _DashboardAmbientBackground({required this.child});

  @override
  State<_DashboardAmbientBackground> createState() => _DashboardAmbientBackgroundState();
}

class _DashboardAmbientBackgroundState extends State<_DashboardAmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25), // ~20-30s pure sine drift
    );
    if (!_isReducedMotion()) {
      _blobController.repeat();
    }
  }

  bool _isReducedMotion() {
    final binding = WidgetsBinding.instance;
    return binding.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  @override
  void dispose() {
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientBgAmbient),
      child: Stack(
        children: [
          // Slow drifting teal blob — purely decorative, subordinate
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, _) {
              final t = _blobController.value * 2 * math.pi;
              final dx = math.sin(t * 0.7) * 60.0;
              final dy = math.sin(t * 0.5) * 40.0;
              return Positioned(
                top: -60 + dy,
                left: MediaQuery.of(context).size.width * 0.3 + dx,
                child: IgnorePointer(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF14B8A6).withValues(alpha: 0.12),
                          const Color(0xFF14B8A6).withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.85],
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              );
            },
          ),
          widget.child,
        ],
      ),
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

    // §4.3: 9-section staggered load-in controllers (~60ms stagger, 250ms each)
    _loadInControllers = List.generate(
      9,
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
    // §4.3: stagger header → risk → banner → offline → metrics → events → alerts → advisories → footer
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
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _loadInRises[index].value),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Data reads — same providers, no changes ──────────────────────────────
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
                      isReducedMotion: _isReducedMotion,
                      onPondChanged: (id) =>
                          ref.read(currentPondIdProvider.notifier).state = id,
                    ),
                  ),
                ),

                // §3.3 Risk Score Block — Tier 2 (hero element, glow + float)
                SliverToBoxAdapter(
                  child: _sectionFadeRise(
                    1,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _RiskDiscBlock(
                        risk: risk,
                        isReducedMotion: _isReducedMotion,
                      ),
                    ),
                  ),
                ),

                // §3.4 Blind-State Banner — Tier 2 when active, spring slide-in
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

                // §3.7 Alerts Card — Tier 1 resting, Tier 2 + pulse when unacked
                SliverToBoxAdapter(
                  child: _sectionFadeRise(
                    6,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _AlertsCard(
                        unackedCount: unackedAlertsCount,
                        totalAlerts: alerts.length,
                        isReducedMotion: _isReducedMotion,
                      ),
                    ),
                  ),
                ),

                // §3.8 Advisories Card — Tier 1, deliberately calm (no pulse)
                SliverToBoxAdapter(
                  child: _sectionFadeRise(
                    7,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: _AdvisoriesCard(advisories: advisories),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // §3.9 Sticky Footer Bar — Tier 2, gradient CTA + breathing glow
          _sectionFadeRise(
            8,
            _StickyFooterBar(isReducedMotion: _isReducedMotion),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3.2 Header — Tier 0 (no card, flat)
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatefulWidget {
  final String farmerName;
  final List<Pond> ponds;
  final Pond selectedPond;
  final bool hasUnackedAlerts;
  final bool isReducedMotion;
  final ValueChanged<String> onPondChanged;

  const _DashboardHeader({
    required this.farmerName,
    required this.ponds,
    required this.selectedPond,
    required this.hasUnackedAlerts,
    required this.isReducedMotion,
    required this.onPondChanged,
  });

  @override
  State<_DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<_DashboardHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellGlowController;
  late Animation<double> _bellGlowAnim;

  @override
  void initState() {
    super.initState();
    _bellGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _bellGlowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _bellGlowController, curve: Curves.easeInOut),
    );
    _updateBellGlow();
  }

  void _updateBellGlow() {
    if (widget.hasUnackedAlerts && !widget.isReducedMotion) {
      _bellGlowController.repeat(reverse: true);
    } else {
      _bellGlowController.stop();
      _bellGlowController.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(_DashboardHeader old) {
    super.didUpdateWidget(old);
    if (old.hasUnackedAlerts != widget.hasUnackedAlerts) {
      _updateBellGlow();
    }
  }

  @override
  void dispose() {
    _bellGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiplePonds = widget.ponds.length > 1;

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
                        'Vanakkam, ${widget.farmerName} 👋',
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
                      value: widget.selectedPond.id,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded,
                          color: AppColors.langAccentPrimary, size: 18),
                      items: widget.ponds.map((p) {
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
                        if (val != null) widget.onPondChanged(val);
                      },
                    ),
                  )
                else
                  Text(
                    '${widget.selectedPond.name} · ${widget.selectedPond.id}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Bell with pulsing glow ring when unread alerts exist
          AnimatedBuilder(
            animation: _bellGlowAnim,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.hasUnackedAlerts)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.riskHigh
                                .withValues(alpha: 0.22 * _bellGlowAnim.value),
                            AppColors.riskHigh.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  child!,
                ],
              );
            },
            child: IconButton(
              onPressed: () => context.push('/notifications'),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: AppColors.textPrimary, size: 24),
                  if (widget.hasUnackedAlerts)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.riskHigh,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color:
                                    AppColors.riskHigh.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1)
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
                  widget.farmerName.isNotEmpty
                      ? widget.farmerName[0].toUpperCase()
                      : 'M',
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
// §3.3 Risk Disc Block — Tier 2: float + glow breathing + inner highlight
// ─────────────────────────────────────────────────────────────────────────────
class _RiskDiscBlock extends StatefulWidget {
  final PondRisk risk;
  final bool isReducedMotion;

  const _RiskDiscBlock({required this.risk, required this.isReducedMotion});

  @override
  State<_RiskDiscBlock> createState() => _RiskDiscBlockState();
}

class _RiskDiscBlockState extends State<_RiskDiscBlock>
    with TickerProviderStateMixin {
  // Idle float — Tier 2, translateY ±3px, 6s
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  // Halo breathing — scale 1.0→1.08→1.0, opacity 0.5→0.25→0.5, ~4s
  late final AnimationController _glowController;
  late final Animation<double> _glowScale;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );
    _floatAnim = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _glowScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.5, end: 0.25).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (!widget.isReducedMotion) {
      _floatController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  LinearGradient get _discGradient {
    switch (widget.risk.effectiveTier) {
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
    switch (widget.risk.effectiveTier) {
      case 'high':
      case 'critical':
        return AppColors.riskHigh;
      case 'medium':
        return AppColors.riskMedium;
      default:
        return AppColors.riskLow;
    }
  }

  String get _tierLabel {
    switch (widget.risk.effectiveTier) {
      case 'high':
      case 'critical':
        return 'High Risk';
      case 'medium':
        return 'Medium Risk';
      default:
        return 'Low Risk';
    }
  }

  String get _tierDescription {
    switch (widget.risk.effectiveTier) {
      case 'high':
      case 'critical':
        return 'Attention required! Environmental conditions warrant immediate check.';
      case 'medium':
        return 'Parameters show slight variance. Monitor closely today.';
      default:
        return 'Pond environment is stable and optimal for crop growth.';
    }
  }

  IconData get _tierIcon {
    switch (widget.risk.effectiveTier) {
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
  Widget build(BuildContext context) {
    final scoreDisplay = widget.risk.score != null
        ? '${(widget.risk.score! * 100).toInt()}%'
        : null;

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _glowController]),
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: _Tier2GlassCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3D Disc with halo + inner highlight
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Halo glow ring — breathing
                        Transform.scale(
                          scale: _glowScale.value,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _tierGlowColor.withValues(
                                      alpha: _glowOpacity.value),
                                  _tierGlowColor.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.70],
                              ),
                            ),
                          ),
                        ),
                        // The disc itself
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _discGradient,
                            boxShadow: [
                              BoxShadow(
                                color: _tierGlowColor.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Inner top-left highlight — reads as "3D sphere"
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
                                child: Icon(_tierIcon,
                                    color: Colors.white, size: 28),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          const Text(
                            'Overall Pond Risk',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const Spacer(),
                          SpeakerButton(
                              textToSpeak:
                                  'Overall pond risk is $_tierLabel. $_tierDescription'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _tierGlowColor.withValues(alpha: 0.18),
                              _tierGlowColor.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  _tierGlowColor.withValues(alpha: 0.3),
                              width: 1),
                        ),
                        child: Text(
                          _tierLabel.toUpperCase(),
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
                        _tierDescription,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      StalenessBadge(syncedAt: widget.risk.syncedAt),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3.5 Metrics Scroll Row — Tier 1 MetricChip glass chips
// ─────────────────────────────────────────────────────────────────────────────
class _MetricsScrollRow extends StatelessWidget {
  final PondLog? log;

  const _MetricsScrollRow({this.log});

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
      clipBehavior: Clip.none, // allow chip shadows to bleed naturally
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
          const SizedBox(width: 4), // trailing breathing room for shadow
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3.6 Event Timeline Card — Tier 1, nested icon chips
// ─────────────────────────────────────────────────────────────────────────────
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

    return _Tier1GlassCard(
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
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '${displayEvents.length} events',
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
          // Nested Tier-1 icon chip — floats above the base card
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
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
// §3.7 Alerts Card — Tier 1 resting, Tier 2 + pulse glow when unacked
// ─────────────────────────────────────────────────────────────────────────────
class _AlertsCard extends StatefulWidget {
  final int unackedCount;
  final int totalAlerts;
  final bool isReducedMotion;

  const _AlertsCard({
    required this.unackedCount,
    required this.totalAlerts,
    required this.isReducedMotion,
  });

  @override
  State<_AlertsCard> createState() => _AlertsCardState();
}

class _AlertsCardState extends State<_AlertsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _updatePulse();
  }

  void _updatePulse() {
    if (widget.unackedCount > 0 && !widget.isReducedMotion) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(_AlertsCard old) {
    super.didUpdateWidget(old);
    if (old.unackedCount != widget.unackedCount) _updatePulse();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnacked = widget.unackedCount > 0;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final glowAlpha = hasUnacked ? (0.18 * _pulseAnim.value) : 0.0;

        Widget card = hasUnacked
            ? _Tier2GlassCard(
                glowColor: AppColors.riskHigh,
                glowAlpha: glowAlpha,
                onTap: () => context.go('/alerts'),
                child: child!,
              )
            : _Tier1GlassCard(
                onTap: () => context.go('/alerts'),
                child: child!,
              );

        return card;
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.unackedCount > 0
                  ? LinearGradient(colors: [
                      AppColors.riskHigh.withValues(alpha: 0.18),
                      AppColors.riskHigh.withValues(alpha: 0.06),
                    ])
                  : LinearGradient(colors: [
                      AppColors.riskLow.withValues(alpha: 0.18),
                      AppColors.riskLow.withValues(alpha: 0.06),
                    ]),
              boxShadow: widget.unackedCount > 0
                  ? [
                      BoxShadow(
                        color: AppColors.riskHigh.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Icon(
              widget.unackedCount > 0
                  ? Icons.notifications_active_rounded
                  : Icons.check_circle_outline_rounded,
              color: widget.unackedCount > 0
                  ? AppColors.riskHigh
                  : AppColors.riskLow,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.unackedCount > 0
                      ? '${widget.unackedCount} Unacknowledged Alert${widget.unackedCount > 1 ? 's' : ''}'
                      : 'Alert System Clear',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.unackedCount > 0
                        ? AppColors.riskHigh
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.unackedCount > 0
                      ? 'Tap to review urgent alerts and action steps'
                      : 'All parameters normal. ${widget.totalAlerts} alerts total.',
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

// ─────────────────────────────────────────────────────────────────────────────
// §3.8 Advisories Card — Tier 1, deliberately calm (no pulse, no glow)
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
// §3.9 Sticky Footer Bar — Tier 2 CTA with breathing glow + idle float
// ─────────────────────────────────────────────────────────────────────────────
class _StickyFooterBar extends StatefulWidget {
  final bool isReducedMotion;

  const _StickyFooterBar({required this.isReducedMotion});

  @override
  State<_StickyFooterBar> createState() => _StickyFooterBarState();
}

class _StickyFooterBarState extends State<_StickyFooterBar>
    with TickerProviderStateMixin {
  // CTA button glow — same rhythm family as risk disc (slightly faster phase)
  late final AnimationController _ctaGlowController;
  late final Animation<double> _ctaGlowAnim;

  // Mic button pulse — slower, 5s, reads "always listening"
  late final AnimationController _micPulseController;
  late final Animation<double> _micPulseAnim;

  // Press/release scale
  bool _ctaPressed = false;
  bool _micPressed = false;

  @override
  void initState() {
    super.initState();
    _ctaGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
    _ctaGlowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctaGlowController, curve: Curves.easeInOut),
    );

    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _micPulseAnim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _micPulseController, curve: Curves.easeInOut),
    );

    if (!widget.isReducedMotion) {
      _ctaGlowController.repeat(reverse: true);
      _micPulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctaGlowController.dispose();
    _micPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        // Subtle glass bottom bar
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.97),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowTier2,
            blurRadius: 20,
            offset: const Offset(0, -6),
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
          // "Check your pond" — Tier 2 gradient CTA with breathing glow
          Expanded(
            child: AnimatedBuilder(
              animation: _ctaGlowAnim,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Breathing glow behind CTA button
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: RadialGradient(
                            colors: [
                              AppColors.riskLow.withValues(
                                  alpha: 0.22 * _ctaGlowAnim.value),
                              AppColors.riskLow.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child!,
                  ],
                );
              },
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
                          blurRadius: _ctaPressed ? 8 : 18,
                          offset: Offset(0, _ctaPressed ? 2 : 6),
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
          ),

          const SizedBox(width: 12),

          // Ask mic — Tier 2 glass circle, slow idle pulse
          AnimatedBuilder(
            animation: _micPulseAnim,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.riskLow.withValues(
                              alpha: 0.2 * _micPulseAnim.value),
                          AppColors.riskLow.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  child!,
                ],
              );
            },
            child: GestureDetector(
              onTapDown: (_) => setState(() => _micPressed = true),
              onTapUp: (_) {
                setState(() => _micPressed = false);
                context.go('/ask');
              },
              onTapCancel: () => setState(() => _micPressed = false),
              child: AnimatedScale(
                scale: _micPressed ? 0.94 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
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
                            color: AppColors.shadowTier2,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Glass Card Primitives — elevation tier system
// ─────────────────────────────────────────────────────────────────────────────

/// Tier 1 — Resting glass card.
/// Shadow: 0 4px 16px rgba(14,148,136,0.10) — palette-tinted.
class _Tier1GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const _Tier1GlassCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
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
                  child: Padding(padding: padding, child: child),
                )
              : Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Tier 2 — Elevated glass card (hero elements).
/// Shadow: 0 12px 32px rgba(14,148,136,0.18) — larger, cooler.
/// Optionally accepts a glow color + alpha for the pulse motif.
class _Tier2GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? glowColor;
  final double glowAlpha;

  const _Tier2GlassCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.glowColor,
    this.glowAlpha = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Optional glow halo beneath the card (for pulse motif)
        if (glowColor != null && glowAlpha > 0)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: glowColor!.withValues(alpha: glowAlpha),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.gradientCardGlass,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.langAccentPrimary.withValues(alpha: 0.2),
                    width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowTier2,
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: onTap != null
                  ? InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(padding: padding, child: child),
                    )
                  : Padding(padding: padding, child: child),
            ),
          ),
        ),
      ],
    );
  }
}

/// Wraps a child in Tier-2 visual treatment without gradient card glass —
/// used for elements like BlindStateBanner that bring their own background.
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
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spring curve for blind-state banner slide-in (§3.4 — overshoot then settle)
// ─────────────────────────────────────────────────────────────────────────────
class _SpringCurve extends Curve {
  const _SpringCurve();

  @override
  double transformInternal(double t) {
    // Mild overshoot: settles at 1.0 with a small bounce
    return 1.0 -
        math.exp(-10.0 * t) * math.cos(math.pi * 2.2 * t) * (1.0 - t) * 1.1;
  }
}
