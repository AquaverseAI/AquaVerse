import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'splash_controller.dart';

// =============================================================================
// TIMING CONSTANTS — Faithfully mapped from reference video
//
// STATE 01 (0ms - 400ms):    Deep tranquil solid ocean canvas
// STATE 02 (300ms - 700ms):  White/cyan seed dot appears in center
// STATE 03 (600ms - 1500ms): 4 Nano-Banana generated circular icons burst outward:
//                            • Top: Farmer inspecting pond (Amber-Yellow)
//                            • Left: IoT Pond Metrics (Emerald-Green)
//                            • Right: Extension Officer (Coral-Magenta)
//                            • Bottom: Water Ecosystem (Cyan-Blue)
// STATE 04 (1500ms - 2400ms):Circular icons hover & float with subtle micro-scale
// STATE 05 (2300ms - 3200ms):Icons accelerate inward, converging to Logo Mark position
// STATE 06 (3000ms - 3800ms):AquaVerse Logo Mark emerges prominently from fusion
// STATE 07 (3400ms - 4300ms):Wordmark "AquaVerse" letters slide in from right
// STATE 08 (4100ms - 4800ms):Tagline resolves ("Better decisions, better harvest")
// STATE 09 (5000ms):         Automatic navigation handoff
//
// Total timeline: 5200ms (tap anywhere to skip immediately)
// =============================================================================

const int _kTotalMs = 5200;

const double _kSeedStart     = 300  / _kTotalMs;
const double _kSeedEnd       = 700  / _kTotalMs;
const double _kBurstStart    = 600  / _kTotalMs;
const double _kBurstEnd      = 1500 / _kTotalMs;
const double _kConvergeStart = 2300 / _kTotalMs;
const double _kConvergeEnd   = 3200 / _kTotalMs;
const double _kLogoStart     = 3000 / _kTotalMs;
const double _kLogoEnd       = 3800 / _kTotalMs;
const double _kWordmarkStart = 3400 / _kTotalMs;
const double _kWordmarkEnd   = 4300 / _kTotalMs;
const double _kTaglineStart  = 4100 / _kTotalMs;
const double _kTaglineEnd    = 4800 / _kTotalMs;
const double _kNavTrigger    = 5000 / _kTotalMs;

// =============================================================================
// SPLASH SCREEN
// =============================================================================

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _timelineCtrl;
  late final AnimationController _hoverCtrl;

  // State 02: Seed Dot
  late final Animation<double> _seedScale;
  late final Animation<double> _seedOpacity;

  // State 03-05: 4 Circular Icons Burst & Convergence
  late final Animation<double> _iconsSpread;
  late final Animation<double> _iconsConverge;
  late final Animation<double> _iconsOpacity;

  // State 06: Logo Mark Reveal
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // State 07: Wordmark Reveal
  late final Animation<double> _wordmarkSlide;
  late final Animation<double> _wordmarkOpacity;

  // State 08: Tagline Reveal
  late final Animation<double> _taglineSlide;
  late final Animation<double> _taglineOpacity;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF072033),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _timelineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kTotalMs),
    );

    // Subtle breathing micro-motion during hover phase
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // ── Seed Dot ─────────────────────────────────────────────────────────────
    _seedScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kSeedStart, _kSeedEnd, curve: Curves.easeOutBack),
      ),
    );
    _seedOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kSeedStart, _kSeedEnd, curve: Curves.easeIn),
      ),
    );

    // ── 4 Circular Icons: Burst outward ──────────────────────────────────────
    _iconsSpread = CurvedAnimation(
      parent: _timelineCtrl,
      curve: const Interval(_kBurstStart, _kBurstEnd, curve: Curves.easeOutBack),
    );

    // ── 4 Circular Icons: Converge inward ────────────────────────────────────
    _iconsConverge = CurvedAnimation(
      parent: _timelineCtrl,
      curve: const Interval(_kConvergeStart, _kConvergeEnd, curve: Curves.easeInOutCubic),
    );

    // Icons fade as logo mark takes over
    _iconsOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kConvergeEnd - 0.04, _kLogoStart + 0.08, curve: Curves.easeOut),
      ),
    );

    // ── Logo Mark Reveal ─────────────────────────────────────────────────────
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kLogoStart, _kLogoEnd, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kLogoStart, _kLogoStart + 0.08, curve: Curves.easeIn),
      ),
    );

    // ── Wordmark "AquaVerse" Letter Reveal ───────────────────────────────────
    _wordmarkSlide = Tween<double>(begin: 45.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kWordmarkStart, _kWordmarkEnd, curve: Curves.easeOutCubic),
      ),
    );
    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kWordmarkStart, _kWordmarkEnd, curve: Curves.easeIn),
      ),
    );

    // ── Tagline Reveal ───────────────────────────────────────────────────────
    _taglineSlide = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kTaglineStart, _kTaglineEnd, curve: Curves.easeOutCubic),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kTaglineStart, _kTaglineEnd, curve: Curves.easeIn),
      ),
    );

    _timelineCtrl.addListener(_onTimelineTick);
    _timelineCtrl.forward();
  }

  void _onTimelineTick() {
    if (!_hasNavigated && _timelineCtrl.value >= _kNavTrigger) {
      _hasNavigated = true;
      _proceedToNext();
    }
  }

  Future<void> _proceedToNext() async {
    if (!mounted) return;
    final splashController = ref.read(splashControllerProvider);
    final targetRoute = await splashController.determineNextRoute();
    if (mounted) {
      context.go(targetRoute);
    }
  }

  @override
  void dispose() {
    _timelineCtrl.removeListener(_onTimelineTick);
    _timelineCtrl.dispose();
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final l10n = AppLocalizations.of(context);
    final tagline =
        l10n?.betterDecisionsBetterHarvest ?? 'Better decisions, better harvest';

    // If reduced motion is requested, snap to end state
    if (disableAnimations && !_timelineCtrl.isCompleted) {
      _timelineCtrl.value = 1.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF072033),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_hasNavigated) {
            _hasNavigated = true;
            _proceedToNext();
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_timelineCtrl, _hoverCtrl]),
          builder: (context, _) {
            final spread = _iconsSpread.value;
            final converge = _iconsConverge.value;
            final hoverOffset = math.sin(_hoverCtrl.value * math.pi) * 3.5;

            // Geometry setup matching reference video:
            // Centered lockup containing [Logo Mark] + [Wordmark]
            const logoSize = 72.0;
            const gap = 16.0;
            // Estimated text width for "AquaVerse" at 38sp bold is ~195dp
            const textWidth = 195.0;
            const totalLockupWidth = logoSize + gap + textWidth;

            final cx = size.width * 0.5;
            final cy = size.height * 0.48; // Centered visual sweet spot

            // Target center for the logo mark
            final targetLogoCenterX = cx - (totalLockupWidth / 2) + (logoSize / 2);
            final targetLogoCenterY = cy;

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── 1. Deep Solid Ocean Backdrop ────────────────────────────
                const Positioned.fill(
                  child: ColoredBox(color: Color(0xFF072033)),
                ),

                // ── 2. Subtle Radial Light Depth ────────────────────────────
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.0, -0.1),
                        radius: 1.2,
                        colors: [
                          const Color(0xFF144D6B).withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.75],
                      ),
                    ),
                  ),
                ),

                // ── 3. Central Seed Dot (Initial Pulse) ─────────────────────
                if (_seedOpacity.value > 0.01 && spread < 0.15)
                  Positioned(
                    left: cx - 9,
                    top: cy - 9,
                    child: Opacity(
                      opacity: _seedOpacity.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _seedScale.value,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary500,
                                blurRadius: 14,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── 4. Four Circular Icons (Burst & Convergence) ───────────
                // Using high-fidelity Nano-Banana generated circular illustrations
                if (_iconsOpacity.value > 0.01 && spread > 0.05)
                  Positioned.fill(
                    child: Opacity(
                      opacity: _iconsOpacity.value.clamp(0.0, 1.0),
                      child: _ReferenceOrbs(
                        originX: cx,
                        originY: cy,
                        targetX: targetLogoCenterX,
                        targetY: targetLogoCenterY,
                        spread: spread,
                        converge: converge,
                        hoverOffset: hoverOffset,
                        size: size,
                      ),
                    ),
                  ),

                // ── 5. Main Brand Lockup (Logo Mark + "AquaVerse") ──────────
                // Settles horizontally exactly like Slack reference video
                if (_logoOpacity.value > 0.01)
                  Positioned(
                    left: cx - (totalLockupWidth / 2),
                    top: cy - (logoSize / 2),
                    child: SizedBox(
                      width: totalLockupWidth + 20,
                      height: logoSize,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ── PROMINENT LOGO MARK ───────────────────────────
                          Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value.clamp(0.0, 1.0),
                              child: Container(
                                width: logoSize,
                                height: logoSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                    BoxShadow(
                                      color: AppColors.primary500.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.asset(
                                    'assets/icons/app_icon.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: gap),

                          // ── WORDMARK "AquaVerse" (Slide In from Right) ────
                          Expanded(
                            child: ClipRect(
                              child: Transform.translate(
                                offset: Offset(_wordmarkSlide.value, 0),
                                child: Opacity(
                                  opacity: _wordmarkOpacity.value.clamp(0.0, 1.0),
                                  child: const Text(
                                    'AquaVerse',
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      fontFamily: 'Palatino',
                                      fontFamilyFallback: [
                                        'Palatino Linotype',
                                        'Georgia',
                                        'serif'
                                      ],
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.6,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── 6. Localized Tagline ────────────────────────────────────
                if (_taglineOpacity.value > 0.01)
                  Positioned(
                    top: cy + (logoSize / 2) + 18,
                    left: 24,
                    right: 24,
                    child: Transform.translate(
                      offset: Offset(0, _taglineSlide.value),
                      child: Opacity(
                        opacity: _taglineOpacity.value.clamp(0.0, 1.0),
                        child: Text(
                          tagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.80),
                            letterSpacing: 0.3,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// REFERENCE ORBS
// Renders the 4 circular icons bursting outward from center, floating, then
// converging with acceleration directly into the target Logo Mark position.
// =============================================================================

class _ReferenceOrbs extends StatelessWidget {
  final double originX;
  final double originY;
  final double targetX;
  final double targetY;
  final double spread;
  final double converge;
  final double hoverOffset;
  final Size size;

  const _ReferenceOrbs({
    required this.originX,
    required this.originY,
    required this.targetX,
    required this.targetY,
    required this.spread,
    required this.converge,
    required this.hoverOffset,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Orbit spread distance (~85dp on mobile)
    final maxRadius = size.shortestSide * 0.24;

    // Size of each circular icon: ~64dp
    const orbSize = 64.0;
    const halfOrb = orbSize / 2;

    // 4 Cardinal positions: Top, Left, Right, Bottom (matching reference video)
    final orbConfigs = [
      // Top: Farmer inspecting pond (Amber-Yellow)
      _OrbConfig(
        assetPath: 'assets/images/orb_farmer.png',
        directionX: 0.0,
        directionY: -1.0,
        hoverX: 0.0,
        hoverY: -hoverOffset,
      ),
      // Left: IoT Pond Metrics (Emerald-Green)
      _OrbConfig(
        assetPath: 'assets/images/orb_metrics.png',
        directionX: -1.0,
        directionY: 0.0,
        hoverX: -hoverOffset * 0.7,
        hoverY: 0.0,
      ),
      // Right: Extension Officer (Coral-Magenta)
      _OrbConfig(
        assetPath: 'assets/images/orb_officer.png',
        directionX: 1.0,
        directionY: 0.0,
        hoverX: hoverOffset * 0.7,
        hoverY: 0.0,
      ),
      // Bottom: Water Ecosystem (Cyan-Blue)
      _OrbConfig(
        assetPath: 'assets/images/orb_ecosystem.png',
        directionX: 0.0,
        directionY: 1.0,
        hoverX: 0.0,
        hoverY: hoverOffset,
      ),
    ];

    // Scale of orbs: expands on burst (0.2 -> 1.0), collapses on converge (1.0 -> 0.3)
    final orbScale = (spread * (1.0 - converge * 0.7)).clamp(0.0, 1.0);

    return Stack(
      children: [
        for (final orb in orbConfigs)
          Builder(
            builder: (context) {
              // Outward position from center
              final burstX = originX + (orb.directionX * maxRadius * spread) + orb.hoverX;
              final burstY = originY + (orb.directionY * maxRadius * spread) + orb.hoverY;

              // Converge smoothly to target logo position
              final currentX = burstX + (targetX - burstX) * converge;
              final currentY = burstY + (targetY - burstY) * converge;

              return Positioned(
                left: currentX - halfOrb,
                top: currentY - halfOrb,
                child: Transform.scale(
                  scale: orbScale,
                  child: Container(
                    width: orbSize,
                    height: orbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.30),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        orb.assetPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _OrbConfig {
  final String assetPath;
  final double directionX;
  final double directionY;
  final double hoverX;
  final double hoverY;

  const _OrbConfig({
    required this.assetPath,
    required this.directionX,
    required this.directionY,
    required this.hoverX,
    required this.hoverY,
  });
}