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
// Adapted from Slack-style reference video (Splash screen reference.mp4):
//
// STATE 01 — Solid ocean background:               t=0ms     → t=400ms
// STATE 02 — Seed dot appears at center:           t=400ms   → t=700ms
// STATE 03 — 4 orbs burst outward to positions:   t=700ms   → t=1600ms
// STATE 04 — Orbs animate content inside:         t=1600ms  → t=2800ms
// STATE 05 — Orbs converge back to center:        t=2800ms  → t=3600ms
// STATE 06 — Logo mark assembles from orbs:       t=3500ms  → t=4000ms
// STATE 07 — Wordmark letters fly in right→left:  t=3900ms  → t=4700ms
// STATE 08 — Tagline fades in:                    t=4600ms  → t=5000ms
// STATE 09 — Static hold then navigate:           t=5000ms  → t=5600ms
//
// Total controller duration: 5600ms
// =============================================================================

const int _kTotalMs = 5600;

// Phase fractions (out of _kTotalMs)
const double _kSeedStart        = 400  / _kTotalMs;
const double _kSeedEnd          = 700  / _kTotalMs;
const double _kOrbsOutStart     = 700  / _kTotalMs;
const double _kOrbsOutEnd       = 1600 / _kTotalMs;
const double _kOrbsInStart      = 2800 / _kTotalMs;
const double _kOrbsInEnd        = 3600 / _kTotalMs;
const double _kMarkStart        = 3500 / _kTotalMs;
const double _kMarkEnd          = 4000 / _kTotalMs;
const double _kWordStart        = 3900 / _kTotalMs;
const double _kWordEnd          = 4700 / _kTotalMs;
const double _kTaglineStart     = 4600 / _kTotalMs;
const double _kTaglineEnd       = 5000 / _kTotalMs;
const double _kNavigateAt       = 5400 / _kTotalMs;

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
  // Main timeline controller
  late final AnimationController _ctrl;

  // Seed dot
  late final Animation<double> _seedScale;
  late final Animation<double> _seedOpacity;

  // Orb burst outward (0 = center, 1 = final orbit position)
  late final Animation<double> _orbsOut;

  // Orbs hold — individual rotation per orb for content animation
  late final AnimationController _orbSpinCtrl;

  // Orbs converge back (0 = orbit, 1 = center merged)
  late final Animation<double> _orbsIn;

  // Logo mark: as orbs converge, the mark appears
  late final Animation<double> _markOpacity;
  late final Animation<double> _markScale;

  // Wordmark letter-by-letter slide in
  late final Animation<double> _wordOpacity;
  late final Animation<double> _wordSlide;

  // Tagline
  late final Animation<double> _taglineOpacity;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kTotalMs),
    );

    // Orb spin: continuous 360° during hold phase
    _orbSpinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // ── Seed dot ──────────────────────────────────────────────────────────
    _seedScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kSeedStart, _kSeedEnd, curve: Curves.easeOut),
      ),
    );
    _seedOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kSeedStart, _kSeedEnd, curve: Curves.easeIn),
      ),
    );

    // ── Orbs burst outward ─────────────────────────────────────────────────
    _orbsOut = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(_kOrbsOutStart, _kOrbsOutEnd, curve: Curves.easeOutBack),
    );

    // ── Orbs converge back ─────────────────────────────────────────────────
    _orbsIn = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(_kOrbsInStart, _kOrbsInEnd, curve: Curves.easeInBack),
    );

    // ── Logo mark ──────────────────────────────────────────────────────────
    _markOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kMarkStart, _kMarkEnd, curve: Curves.easeOut),
      ),
    );
    _markScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kMarkStart, _kMarkEnd, curve: Curves.easeOutBack),
      ),
    );

    // ── Wordmark ────────────────────────────────────────────────────────────
    _wordOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kWordStart, _kWordEnd, curve: Curves.easeOut),
      ),
    );
    _wordSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kWordStart, _kWordEnd, curve: Curves.easeOut),
      ),
    );

    // ── Tagline ─────────────────────────────────────────────────────────────
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kTaglineStart, _kTaglineEnd, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();

    // Navigate when animation reaches the trigger point
    _ctrl.addListener(_checkNavigate);
  }

  void _checkNavigate() {
    if (!_hasNavigated && _ctrl.value >= _kNavigateAt) {
      _hasNavigated = true;
      _navigateAway();
    }
  }

  Future<void> _navigateAway() async {
    final splashController = ref.read(splashControllerProvider);
    final targetRoute = await splashController.determineNextRoute();
    if (mounted) context.go(targetRoute);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_checkNavigate);
    _ctrl.dispose();
    _orbSpinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final reducedMotion =
        MediaQuery.of(context).disableAnimations;
    final l10n = AppLocalizations.of(context);
    final tagline =
        l10n?.betterDecisionsBetterHarvest ?? 'Better decisions, better harvest.';

    return Scaffold(
      backgroundColor: AppColors.mountain900,
      body: AnimatedBuilder(
        animation: Listenable.merge([_ctrl, _orbSpinCtrl]),
        builder: (context, _) {
          return _SplashCanvas(
            size: size,
            reducedMotion: reducedMotion,
            seedScale: _seedScale.value,
            seedOpacity: _seedOpacity.value,
            orbsOut: _orbsOut.value,
            orbsIn: _orbsIn.value,
            orbSpinAngle: _orbSpinCtrl.value * math.pi * 2,
            markOpacity: _markOpacity.value,
            markScale: _markScale.value,
            wordOpacity: _wordOpacity.value,
            wordSlide: _wordSlide.value,
            taglineOpacity: _taglineOpacity.value,
            tagline: tagline,
          );
        },
      ),
    );
  }
}

// =============================================================================
// SPLASH CANVAS — Stateless layout widget driven by animation values
// =============================================================================

class _SplashCanvas extends StatelessWidget {
  final Size size;
  final bool reducedMotion;
  final double seedScale;
  final double seedOpacity;
  final double orbsOut;
  final double orbsIn;
  final double orbSpinAngle;
  final double markOpacity;
  final double markScale;
  final double wordOpacity;
  final double wordSlide;
  final double taglineOpacity;
  final String tagline;

  const _SplashCanvas({
    required this.size,
    required this.reducedMotion,
    required this.seedScale,
    required this.seedOpacity,
    required this.orbsOut,
    required this.orbsIn,
    required this.orbSpinAngle,
    required this.markOpacity,
    required this.markScale,
    required this.wordOpacity,
    required this.wordSlide,
    required this.taglineOpacity,
    required this.tagline,
  });

  // ── Orb definitions: 4 aquaculture-themed circles ────────────────────────
  // Positions follow Slack-style: top-center, left-center, right-center, bottom-center
  // i.e. a cross/diamond arrangement
  static const List<_OrbDef> _orbs = [
    _OrbDef(                                      // TOP — Water / Pond
      angle: -math.pi / 2,                        // up
      primaryColor: Color(0xFF27AFC0),             // primary500 aqua
      secondaryColor: Color(0xFF8DD9DB),           // primary300
      painter: _OrbType.water,
    ),
    _OrbDef(                                      // LEFT — Fish / Aquaculture
      angle: math.pi,                             // left
      primaryColor: Color(0xFF35A58A),             // green600 success
      secondaryColor: Color(0xFFCDEEE3),           // green200
      painter: _OrbType.fish,
    ),
    _OrbDef(                                      // RIGHT — Data / AI
      angle: 0,                                   // right
      primaryColor: Color(0xFF4BA8C1),             // mountain500
      secondaryColor: Color(0xFFCBEAF0),           // mountain200
      painter: _OrbType.data,
    ),
    _OrbDef(                                      // BOTTOM — Harvest / Grain
      angle: math.pi / 2,                         // down
      primaryColor: Color(0xFF176F9C),             // mountain700
      secondaryColor: Color(0xFF8DD9DB),           // primary300
      painter: _OrbType.harvest,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cx = size.width  * 0.5;
    final cy = size.height * 0.5;

    // Orb radius: 15% of shortest side
    final orbR = size.shortestSide * 0.15;

    // Orbit radius: how far orbs travel from center
    final orbitR = size.shortestSide * 0.36;

    // Orbs converge as orbsIn approaches 1
    // orbsOut drives outward spread: 0 = center → 1 = orbit
    // orbsIn drives convergence: 0 = orbit → 1 = center
    final effectiveOrbit = orbitR * (orbsOut - orbsIn).clamp(0.0, 1.0);

    // Orbs visible when out>0 and before mark is fully visible
    final orbsVisible = orbsOut > 0.0 && markOpacity < 0.95;

    // Seed visible: only during the initial burst outward
    final seedVisible = seedOpacity > 0.01 && orbsOut < 0.1;

    return Stack(
      children: [
        // ── Deep ocean background ──────────────────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A2F50), // deep ocean top
                  Color(0xFF124C73), // mountain900 mid
                  Color(0xFF0D3D5E), // slightly darker bottom
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // ── Subtle wave shimmer (painted once, very cheap) ─────────────────
        Positioned.fill(
          child: CustomPaint(
            painter: _WaveBackgroundPainter(
              orbSpinAngle * 0.1, // very slow wave undulation
            ),
          ),
        ),

        // ── Seed dot ──────────────────────────────────────────────────────
        if (seedVisible)
          Positioned(
            left: cx - 8,
            top:  cy - 8,
            child: Opacity(
              opacity: seedOpacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: seedScale,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

        // ── 4 Orbs ────────────────────────────────────────────────────────
        if (orbsVisible)
          for (final orb in _orbs) ...[
            _buildOrb(
              cx: cx,
              cy: cy,
              orb: orb,
              orbitR: effectiveOrbit,
              orbR: orbR,
              spinAngle: orbSpinAngle,
              reducedMotion: reducedMotion,
            ),
          ],

        // ── Logo mark + wordmark (centered, slightly above center) ─────────
        if (markOpacity > 0.0)
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo mark + wordmark row
                  Opacity(
                    opacity: markOpacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: markScale,
                      child: _buildLogoRow(
                        wordOpacity: wordOpacity,
                        wordSlide: wordSlide,
                        orbR: orbR,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Tagline
                  Opacity(
                    opacity: taglineOpacity.clamp(0.0, 1.0),
                    child: Text(
                      tagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        letterSpacing: 0.4,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrb({
    required double cx,
    required double cy,
    required _OrbDef orb,
    required double orbitR,
    required double orbR,
    required double spinAngle,
    required bool reducedMotion,
  }) {
    final x = cx + orbitR * math.cos(orb.angle);
    final y = cy + orbitR * math.sin(orb.angle) * 0.85; // slight elliptic orbit

    return Positioned(
      left: x - orbR,
      top:  y - orbR,
      child: SizedBox(
        width:  orbR * 2,
        height: orbR * 2,
        child: CustomPaint(
          painter: _OrbPainter(
            orb: orb,
            spinAngle: reducedMotion ? 0.0 : spinAngle,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoRow({
    required double wordOpacity,
    required double wordSlide,
    required double orbR,
  }) {
    // Logo mark: two overlapping circles (water droplet / aqua orb)
    // Left circle = solid aqua, right = translucent
    const markSize = 48.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo mark
        SizedBox(
          width: markSize,
          height: markSize,
          child: CustomPaint(
            painter: _LogoMarkPainter(),
          ),
        ),

        const SizedBox(width: 10),

        // Wordmark: clips from right and slides in
        ClipRect(
          child: Opacity(
            opacity: wordOpacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(wordSlide * 60, 0),
              child: const Text(
                'AquaVerse',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ORB DEFINITION
// =============================================================================

enum _OrbType { water, fish, data, harvest }

class _OrbDef {
  final double angle;
  final Color primaryColor;
  final Color secondaryColor;
  final _OrbType painter;

  const _OrbDef({
    required this.angle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.painter,
  });
}

// =============================================================================
// ORB PAINTER — Each orb is a circle with a distinct aquaculture illustration
// Painted purely with Canvas primitives (no images, no Lottie, lightweight)
// =============================================================================

class _OrbPainter extends CustomPainter {
  final _OrbDef orb;
  final double spinAngle;

  const _OrbPainter({required this.orb, required this.spinAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    // Clip to circle
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));

    // Background fill (radial gradient for depth)
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [
          orb.primaryColor,
          Color.lerp(orb.primaryColor, const Color(0xFF0A2F50), 0.55)!,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, bgPaint);

    // Inner content illustration (type-specific)
    switch (orb.painter) {
      case _OrbType.water:
        _paintWaterOrb(canvas, center, r, orb.secondaryColor, spinAngle);
      case _OrbType.fish:
        _paintFishOrb(canvas, center, r, orb.secondaryColor, spinAngle);
      case _OrbType.data:
        _paintDataOrb(canvas, center, r, orb.secondaryColor, spinAngle);
      case _OrbType.harvest:
        _paintHarvestOrb(canvas, center, r, orb.secondaryColor, spinAngle);
    }

    canvas.restore();

    // Subtle rim light
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, r - 0.75, rimPaint);
  }

  // ── Water orb: animated wave with floating bubbles ─────────────────────
  void _paintWaterOrb(
      Canvas canvas, Offset center, double r, Color accent, double angle) {
    // Wave band across lower portion
    final waveY = center.dy + r * 0.15 + math.sin(angle) * r * 0.06;
    final wavePaint = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final wavePath = Path();
    wavePath.moveTo(center.dx - r, waveY);
    for (double x = -r; x <= r; x += 4) {
      wavePath.lineTo(
        center.dx + x,
        waveY + math.sin(angle + x * 0.12) * r * 0.05,
      );
    }
    wavePath.lineTo(center.dx + r, center.dy + r);
    wavePath.lineTo(center.dx - r, center.dy + r);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    // 3 bubbles floating upward (animated by angle)
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30);
    final positions = [
      Offset(center.dx - r * 0.3, center.dy + r * 0.3 - (angle % (math.pi * 2)) / (math.pi * 2) * r * 0.6),
      Offset(center.dx + r * 0.2, center.dy + r * 0.5 - ((angle + 0.7) % (math.pi * 2)) / (math.pi * 2) * r * 0.7),
      Offset(center.dx - r * 0.1, center.dy + r * 0.4 - ((angle + 1.4) % (math.pi * 2)) / (math.pi * 2) * r * 0.5),
    ];
    for (final p in positions) {
      canvas.drawCircle(p, r * 0.05, bubblePaint);
    }

    // Water surface shimmer line
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final shimmerPath = Path();
    shimmerPath.moveTo(center.dx - r * 0.4, waveY - r * 0.04);
    shimmerPath.quadraticBezierTo(
      center.dx,
      waveY + math.sin(angle + 1.0) * r * 0.04,
      center.dx + r * 0.4,
      waveY - r * 0.04,
    );
    canvas.drawPath(shimmerPath, shimmerPaint);
  }

  // ── Fish orb: stylized fish silhouette, tail fin animated ─────────────
  void _paintFishOrb(
      Canvas canvas, Offset center, double r, Color accent, double angle) {
    // Fish body (ellipse)
    final bodyPaint = Paint()
      ..color = accent.withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;
    final bodyRect = Rect.fromCenter(
      center: center.translate(-r * 0.05, 0),
      width: r * 1.0,
      height: r * 0.55,
    );
    canvas.drawOval(bodyRect, bodyPaint);

    // Tail fin (triangle, rotates slightly)
    final tailAngle = math.sin(angle * 1.5) * 0.25;
    final tailPaint = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    final fishRight = center.dx + r * 0.40;
    final tailPath = Path();
    tailPath.moveTo(fishRight, center.dy);
    tailPath.lineTo(
      fishRight + r * 0.30 * math.cos(tailAngle),
      center.dy - r * 0.25 * math.sin(tailAngle + 0.6),
    );
    tailPath.lineTo(
      fishRight + r * 0.30 * math.cos(-tailAngle),
      center.dy + r * 0.25 * math.sin(tailAngle + 0.6),
    );
    tailPath.close();
    canvas.drawPath(tailPath, tailPaint);

    // Eye
    final eyePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.80);
    canvas.drawCircle(center.translate(-r * 0.18, -r * 0.04), r * 0.06, eyePaint);
    final pupilPaint = Paint()..color = const Color(0xFF0A2F50);
    canvas.drawCircle(center.translate(-r * 0.17, -r * 0.04), r * 0.03, pupilPaint);

    // Fin on top
    final finPaint = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final finPath = Path();
    finPath.moveTo(center.dx - r * 0.15, center.dy - r * 0.28);
    finPath.lineTo(center.dx + r * 0.10, center.dy - r * 0.50);
    finPath.lineTo(center.dx + r * 0.15, center.dy - r * 0.28);
    finPath.close();
    canvas.drawPath(finPath, finPaint);
  }

  // ── Data orb: grid lines + animated data pulse bars ────────────────────
  void _paintDataOrb(
      Canvas canvas, Offset center, double r, Color accent, double angle) {
    // Light grid
    final gridPaint = Paint()
      ..color = accent.withValues(alpha: 0.20)
      ..strokeWidth = 0.8;
    for (double i = -r; i <= r; i += r * 0.28) {
      canvas.drawLine(
        Offset(center.dx + i, center.dy - r),
        Offset(center.dx + i, center.dy + r),
        gridPaint,
      );
      canvas.drawLine(
        Offset(center.dx - r, center.dy + i),
        Offset(center.dx + r, center.dy + i),
        gridPaint,
      );
    }

    // Bar chart: 3 animated bars
    final barPaint = Paint()..style = PaintingStyle.fill;
    final barData = [
      (offset: -r * 0.28, h: 0.35 + 0.12 * math.sin(angle)),
      (offset:  0.0,       h: 0.55 + 0.10 * math.sin(angle + 1.0)),
      (offset:  r * 0.28,  h: 0.45 + 0.15 * math.sin(angle + 2.0)),
    ];
    final bw = r * 0.18;
    for (final b in barData) {
      final barH = r * b.h;
      final barRect = Rect.fromLTWH(
        center.dx + b.offset - bw / 2,
        center.dy + r * 0.25 - barH,
        bw,
        barH,
      );
      barPaint.color = accent.withValues(alpha: 0.75);
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, Radius.circular(bw * 0.4)),
        barPaint,
      );
    }

    // Pulse ring
    final pulseR = r * (0.25 + 0.08 * math.sin(angle * 2));
    final pulsePaint = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center.translate(0, -r * 0.18), pulseR, pulsePaint);
  }

  // ── Harvest orb: stylized grain/paddy icon with leaf ──────────────────
  void _paintHarvestOrb(
      Canvas canvas, Offset center, double r, Color accent, double angle) {
    // Stem
    final stemPaint = Paint()
      ..color = accent.withValues(alpha: 0.70)
      ..strokeWidth = r * 0.06
      ..strokeCap = StrokeCap.round;
    final sway = math.sin(angle) * r * 0.06;
    canvas.drawLine(
      Offset(center.dx + sway, center.dy + r * 0.40),
      Offset(center.dx + sway, center.dy - r * 0.30),
      stemPaint,
    );

    // Grain head (cluster of ovals)
    final grainPaint = Paint()
      ..color = accent.withValues(alpha: 0.80)
      ..style = PaintingStyle.fill;
    final grainPositions = [
      Offset(center.dx + sway,            center.dy - r * 0.28),
      Offset(center.dx + sway - r * 0.14, center.dy - r * 0.18),
      Offset(center.dx + sway + r * 0.14, center.dy - r * 0.18),
      Offset(center.dx + sway - r * 0.10, center.dy - r * 0.08),
      Offset(center.dx + sway + r * 0.10, center.dy - r * 0.08),
    ];
    for (final gp in grainPositions) {
      canvas.drawOval(
        Rect.fromCenter(center: gp, width: r * 0.16, height: r * 0.22),
        grainPaint,
      );
    }

    // Leaf (bezier arc to the left of stem)
    final leafPaint = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    final leafPath = Path();
    leafPath.moveTo(center.dx + sway, center.dy + r * 0.05);
    leafPath.quadraticBezierTo(
      center.dx + sway - r * 0.35,
      center.dy - r * 0.12,
      center.dx + sway - r * 0.20,
      center.dy - r * 0.22,
    );
    leafPath.quadraticBezierTo(
      center.dx + sway - r * 0.05,
      center.dy - r * 0.10,
      center.dx + sway,
      center.dy + r * 0.05,
    );
    leafPath.close();
    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.spinAngle != spinAngle;
}

// =============================================================================
// LOGO MARK PAINTER
// AquaVerse logo mark: two overlapping circles — left solid aqua, right ghost.
// Adapted from the app_icon.png style.
// =============================================================================

class _LogoMarkPainter extends CustomPainter {
  const _LogoMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;

    // Left circle: solid gradient aqua
    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E8B77), Color(0xFF27AFC0)],
      ).createShader(Rect.fromCircle(center: Offset(r * 0.65, r), radius: r * 0.55));
    canvas.drawCircle(Offset(r * 0.65, r), r * 0.55, leftPaint);

    // Right circle: translucent white (water shine)
    final rightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(r * 1.25, r), r * 0.45, rightPaint);

    // Intersection highlight: bright aqua
    final intersectPaint = Paint()
      ..color = const Color(0xFF8DD9DB).withValues(alpha: 0.60)
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(Offset(r * 0.95, r), r * 0.22, intersectPaint);

    // Rim
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(r * 0.65, r), r * 0.55, rimPaint);
  }

  @override
  bool shouldRepaint(_LogoMarkPainter _) => false;
}

// =============================================================================
// WAVE BACKGROUND PAINTER — Very cheap subtle underwater animation
// =============================================================================

class _WaveBackgroundPainter extends CustomPainter {
  final double phase;

  const _WaveBackgroundPainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1495AE).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final wavePhase = phase + i * (math.pi * 2 / 3);
      final waveY = size.height * (0.25 + i * 0.28);
      final path = Path();
      path.moveTo(0, waveY);
      for (double x = 0; x <= size.width; x += 8) {
        path.lineTo(
          x,
          waveY + math.sin(wavePhase + x / size.width * math.pi * 4) * 8,
        );
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveBackgroundPainter old) => old.phase != phase;
}
