import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'splash_controller.dart';

// =============================================================================
// TIMING CONSTANTS
//
// Reference motion choreography (Slack-inspired rhythm adapted for AquaVerse):
//
// STATE 01 (0ms - 400ms):    Deep tranquil ocean canvas
// STATE 02 (400ms - 800ms):  Luminous aquatic seed emerges at center
// STATE 03 (700ms - 1700ms): 4 pure liquid droplets burst outward in cardinal cross
//                            Water ripples radiate outward across the canvas
// STATE 04 (1600ms - 2600ms):Droplets hover in buoyant equilibrium (breathing micro-motion)
// STATE 05 (2500ms - 3300ms):Droplets accelerate inward, converging to center
// STATE 06 (3200ms - 4100ms):HERO LOGO emerges from fusion with majestic scale & glow
// STATE 07 (3700ms - 4600ms):"AquaVerse" wordmark slides up with crisp typography
// STATE 08 (4300ms - 5000ms):Tagline resolves ("Better decisions, better harvest")
// STATE 09 (5200ms):         Seamless navigation handoff
//
// Total timeline: 5400ms (can also tap anywhere to advance immediately)
// =============================================================================

const int _kTotalMs = 5400;

const double _kSeedStart     = 400  / _kTotalMs;
const double _kSeedEnd       = 800  / _kTotalMs;
const double _kBurstStart    = 700  / _kTotalMs;
const double _kBurstEnd      = 1700 / _kTotalMs;
const double _kConvergeStart = 2500 / _kTotalMs;
const double _kConvergeEnd   = 3300 / _kTotalMs;
const double _kLogoStart     = 3100 / _kTotalMs;
const double _kLogoEnd       = 4100 / _kTotalMs;
const double _kWordmarkStart = 3700 / _kTotalMs;
const double _kWordmarkEnd   = 4600 / _kTotalMs;
const double _kTaglineStart  = 4300 / _kTotalMs;
const double _kTaglineEnd    = 5000 / _kTotalMs;
const double _kNavTrigger    = 5200 / _kTotalMs;

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
  late final AnimationController _floatCtrl;

  // State 02: Seed droplet
  late final Animation<double> _seedScale;
  late final Animation<double> _seedOpacity;

  // State 03-05: Droplet burst & convergence
  late final Animation<double> _dropletSpread;
  late final Animation<double> _dropletConverge;
  late final Animation<double> _dropletsOpacity;

  // State 06: Hero Logo reveal
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoGlow;

  // State 07: Wordmark reveal
  late final Animation<double> _wordmarkSlide;
  late final Animation<double> _wordmarkOpacity;

  // State 08: Tagline reveal
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
        systemNavigationBarColor: Color(0xFF061A2B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _timelineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kTotalMs),
    );

    // Continuous subtle floating / breathing motion
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // ── Seed Droplet ─────────────────────────────────────────────────────────
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

    // ── 4 Liquid Droplets: Burst outward ─────────────────────────────────────
    _dropletSpread = CurvedAnimation(
      parent: _timelineCtrl,
      curve: const Interval(_kBurstStart, _kBurstEnd, curve: Curves.easeOutBack),
    );

    // ── 4 Liquid Droplets: Converge inward ───────────────────────────────────
    _dropletConverge = CurvedAnimation(
      parent: _timelineCtrl,
      curve: const Interval(_kConvergeStart, _kConvergeEnd, curve: Curves.easeInOutCubic),
    );

    // Droplets vanish as logo takes over
    _dropletsOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kConvergeEnd - 0.03, _kLogoStart + 0.08, curve: Curves.easeOut),
      ),
    );

    // ── Hero Logo (Majestic scale, prominent presence) ───────────────────────
    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kLogoStart, _kLogoEnd, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kLogoStart, _kLogoStart + 0.10, curve: Curves.easeIn),
      ),
    );
    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineCtrl,
        curve: const Interval(_kLogoStart, _kLogoEnd + 0.08, curve: Curves.easeOut),
      ),
    );

    // ── Wordmark "AquaVerse" ────────────────────────────────────────────────
    _wordmarkSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
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

    // ── Tagline ─────────────────────────────────────────────────────────────
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
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final l10n = AppLocalizations.of(context);
    final tagline =
        l10n?.betterDecisionsBetterHarvest ?? 'Better decisions, better harvest';

    // If accessibility reduced motion is active, jump directly to completed state
    if (disableAnimations && !_timelineCtrl.isCompleted) {
      _timelineCtrl.value = 1.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF061A2B),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_hasNavigated) {
            _hasNavigated = true;
            _proceedToNext();
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_timelineCtrl, _floatCtrl]),
          builder: (context, _) {
            final spread = _dropletSpread.value;
            final converge = _dropletConverge.value;
            final floatOffset = math.sin(_floatCtrl.value * math.pi) * 3.5;

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── 1. Deep Ocean Ambience & Radial Glow ────────────────────
                const Positioned.fill(
                  child: _OceanBackdrop(),
                ),

                // ── 2. Subtle Water Ripple Dynamics ────────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WaterRipplesPainter(
                      progress: _timelineCtrl.value,
                      spread: spread,
                    ),
                  ),
                ),

                // ── 3. Central Seed Droplet (Initial Pulse) ─────────────────
                if (_seedOpacity.value > 0.01 && spread < 0.15)
                  Center(
                    child: Opacity(
                      opacity: _seedOpacity.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _seedScale.value,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Colors.white, AppColors.primary500],
                              stops: [0.3, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary500.withValues(alpha: 0.6),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── 4. Four Liquid Droplets (Cardinal Cross Formation) ─────
                // Pure minimalist liquid beads with brand gradient & glass depth.
                // NO cartoon clip art, NO ai slop illustrations.
                if (_dropletsOpacity.value > 0.01 && spread > 0.05)
                  Positioned.fill(
                    child: Opacity(
                      opacity: _dropletsOpacity.value.clamp(0.0, 1.0),
                      child: _CardinalDroplets(
                        size: size,
                        spread: spread,
                        converge: converge,
                        floatOffset: floatOffset,
                      ),
                    ),
                  ),

                // ── 5. Hero Logo & AquaVerse Brand Lockup ────────────────────
                // Centered, prominent, large-scale, authoritative.
                if (_logoOpacity.value > 0.01)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── HERO LOGO (Large, majestic app emblem) ────────
                          Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value.clamp(0.0, 1.0),
                              child: _HeroLogoEmblem(
                                glowProgress: _logoGlow.value,
                                size: size.shortestSide * 0.34, // ~130-145dp
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ── HERO WORDMARK "AquaVerse" ─────────────────────
                          Transform.translate(
                            offset: Offset(0, _wordmarkSlide.value),
                            child: Opacity(
                              opacity: _wordmarkOpacity.value.clamp(0.0, 1.0),
                              child: const Text(
                                'AquaVerse',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Palatino',
                                  fontFamilyFallback: [
                                    'Palatino Linotype',
                                    'Georgia',
                                    'serif'
                                  ],
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── LOCALIZED TAGLINE ─────────────────────────────
                          Transform.translate(
                            offset: Offset(0, _taglineSlide.value),
                            child: Opacity(
                              opacity: _taglineOpacity.value.clamp(0.0, 1.0),
                              child: Text(
                                tagline,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.78),
                                  letterSpacing: 0.3,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── 6. Bottom Brand Indicator ───────────────────────────────
                Positioned(
                  bottom: MediaQuery.paddingOf(context).bottom + 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: _taglineOpacity.value.clamp(0.0, 1.0) * 0.65,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF14B8A6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI FOR SUSTAINABLE AQUACULTURE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
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
// HERO LOGO EMBLEM
// Renders the authentic high-resolution AquaVerse app icon with an ambient
// aqua glow, rounded corner styling, and subtle glass depth border.
// =============================================================================

class _HeroLogoEmblem extends StatelessWidget {
  final double glowProgress;
  final double size;

  const _HeroLogoEmblem({
    required this.glowProgress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final clampedSize = size.clamp(120.0, 150.0);

    return SizedBox(
      width: clampedSize + 48,
      height: clampedSize + 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient aquatic bloom glow behind logo
          Opacity(
            opacity: (glowProgress * 0.85).clamp(0.0, 1.0),
            child: Container(
              width: clampedSize + 36,
              height: clampedSize + 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF14B8A6).withValues(alpha: 0.45),
                    const Color(0xFF27AFC0).withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Authentic AquaVerse App Icon
          Container(
            width: clampedSize,
            height: clampedSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(clampedSize * 0.24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: const Color(0xFF0E9488).withValues(alpha: 0.30 * glowProgress),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(clampedSize * 0.24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/icons/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                  // Subtle top-edge glass rim highlight
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(clampedSize * 0.24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1.5,
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

// =============================================================================
// CARDINAL DROPLETS (4 PURE LIQUID ORBS)
// Clean minimalist liquid glass beads inspired by the Slack reference motion.
// No cartoon illustrations or clip art.
// =============================================================================

class _CardinalDroplets extends StatelessWidget {
  final Size size;
  final double spread;
  final double converge;
  final double floatOffset;

  const _CardinalDroplets({
    required this.size,
    required this.spread,
    required this.converge,
    required this.floatOffset,
  });

  @override
  Widget build(BuildContext context) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    // Radius of the orbit: reaches ~85dp, then snaps back to center
    final maxOrbit = size.shortestSide * 0.25;
    final currentOrbit = maxOrbit * (spread - converge).clamp(0.0, 1.0);

    // Droplet size: ~26-30dp
    const dropletR = 14.0;

    // 4 Cardinal positions: North, East, South, West
    // Each with its own brand-aligned liquid gradient
    final droplets = [
      // Top (North) — Vibrant Aqua
      _DropletData(
        offset: Offset(cx, cy - currentOrbit - floatOffset),
        colors: const [Color(0xFF55C4C8), Color(0xFF1495AE)],
        shadowColor: const Color(0xFF27AFC0),
      ),
      // Right (East) — Luminous Teal
      _DropletData(
        offset: Offset(cx + currentOrbit + floatOffset * 0.7, cy),
        colors: const [Color(0xFF2DD4BF), Color(0xFF0E9488)],
        shadowColor: const Color(0xFF14B8A6),
      ),
      // Bottom (South) — Deep Ocean Blue
      _DropletData(
        offset: Offset(cx, cy + currentOrbit + floatOffset),
        colors: const [Color(0xFF4BA8C1), Color(0xFF124C73)],
        shadowColor: const Color(0xFF176F9C),
      ),
      // Left (West) — Vital Spring Green
      _DropletData(
        offset: Offset(cx - currentOrbit - floatOffset * 0.7, cy),
        colors: const [Color(0xFF34D399), Color(0xFF059669)],
        shadowColor: const Color(0xFF10B981),
      ),
    ];

    return Stack(
      children: [
        for (final d in droplets)
          Positioned(
            left: d.offset.dx - dropletR,
            top: d.offset.dy - dropletR,
            child: Container(
              width: dropletR * 2,
              height: dropletR * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: d.colors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: d.shadowColor.withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                // Specular liquid reflection dot
                child: Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 5, right: 5),
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DropletData {
  final Offset offset;
  final List<Color> colors;
  final Color shadowColor;

  const _DropletData({
    required this.offset,
    required this.colors,
    required this.shadowColor,
  });
}

// =============================================================================
// OCEAN BACKDROP
// Premium deep ocean gradient with soft aquatic atmospheric lighting
// =============================================================================

class _OceanBackdrop extends StatelessWidget {
  const _OceanBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.15),
          radius: 1.25,
          colors: [
            Color(0xFF0E3854), // Ambient aqua center
            Color(0xFF0A263D), // Mid ocean blue
            Color(0xFF061A2B), // Deep abyss foundation
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

// =============================================================================
// WATER RIPPLES PAINTER
// Fine concentric ripples that expand outwards from center like water droplets
// =============================================================================

class _WaterRipplesPainter extends CustomPainter {
  final double progress;
  final double spread;

  const _WaterRipplesPainter({
    required this.progress,
    required this.spread,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (spread <= 0.05) return;

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final maxRadius = size.shortestSide * 0.45;

    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 3; i++) {
      final waveOffset = (spread * 1.5 - i * 0.28).clamp(0.0, 1.0);
      if (waveOffset > 0.0 && waveOffset < 1.0) {
        final currentR = waveOffset * maxRadius;
        final opacity = ((1.0 - waveOffset) * 0.22).clamp(0.0, 1.0);

        ripplePaint.color = const Color(0xFF27AFC0).withValues(alpha: opacity);
        canvas.drawCircle(center, currentR, ripplePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_WaterRipplesPainter old) =>
      old.progress != progress || old.spread != spread;
}
