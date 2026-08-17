import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/floating_icons_overlay.dart';
import 'splash_controller.dart';

// =============================================================================
// TIMING CONSTANTS — Derived from frame-by-frame analysis of reference video
// (see splash_frame_analysis.md for full breakdown)
//
// Reference: Planoo splash, 6fps extraction, frames 4–30 = t≈500ms→4833ms
//
// Phase 1 — Blob orbit loader:       t=0ms      → t=2000ms
// Phase 2 — Blobs merge + expand:    t=2000ms   → t=3833ms
// Phase 3 — Background fill settle:  t=3833ms   → t=4000ms
// Phase 4 — Logo mark fade-in:       t=4000ms   → t=4300ms
// Phase 5 — Text reveal top-down:    t=4300ms   → t=4833ms (each line +166ms)
// Phase 6 — Button resolves:         t=4300ms   → t=4600ms
// Total:                             ≈4833ms
// =============================================================================

/// Total controller duration covering all phases.
const int kTotalMs = 5200;

// Phase boundaries as fractions of [kTotalMs]
const double _kBlobOrbitEnd    = 2000 / kTotalMs; // 0.385
const double _kExpandStart     = 1800 / kTotalMs; // 0.346 — merge starts early
const double _kExpandEnd       = 3833 / kTotalMs; // 0.737 — fill complete
const double _kLogoStart       = 3900 / kTotalMs; // 0.750
const double _kLogoEnd         = 4200 / kTotalMs; // 0.808
const double _kLine1Start      = 4100 / kTotalMs; // 0.789
const double _kLine1End        = 4400 / kTotalMs; // 0.846
const double _kLine2Start      = 4250 / kTotalMs; // 0.817
const double _kLine2End        = 4600 / kTotalMs; // 0.885
const double _kLine3Start      = 4400 / kTotalMs; // 0.846
const double _kLine3End        = 4833 / kTotalMs; // 0.930
const double _kButtonStart     = 4100 / kTotalMs; // 0.789
const double _kButtonEnd       = 4600 / kTotalMs; // 0.885

/// Max sigma for blur-to-focus sweep (capped for Android Go 2GB raster budget).
const double kMaxBlurSigma = 12.0;

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

  // --- Phase 1: Blob orbit ---
  late final Animation<double> _orbitAngle; // 0→2π continuously during phase 1

  // --- Phase 2: Blob expand → background fill ---
  late final Animation<double> _expandProgress; // 0→1

  // --- Phase 3: Logo mark ---
  late final Animation<double> _logoOpacity;

  // --- Phase 4: Text lines (top-down reveal, one at a time) ---
  late final Animation<double> _line1Opacity;
  late final Animation<double> _line1Blur;
  late final Animation<double> _line2Opacity;
  late final Animation<double> _line2Blur;
  late final Animation<double> _line3Opacity;
  late final Animation<double> _line3Blur;

  // --- Phase 5: Button resolve ---
  late final Animation<double> _buttonProgress;

  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kTotalMs),
    );

    // ── Orbit angle: continuously rotates during blob phase ──────────────────
    // Maps 0→_kBlobOrbitEnd to 0→2π (one full revolution visible to user)
    _orbitAngle = Tween<double>(begin: 0, end: math.pi * 2).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(0.0, _kBlobOrbitEnd, curve: Curves.linear),
      ),
    );

    // ── Expand progress: 0=two blobs at rest, 1=full-screen fill ─────────────
    _expandProgress = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(_kExpandStart, _kExpandEnd, curve: Curves.easeInOut),
    );

    // ── Logo opacity ─────────────────────────────────────────────────────────
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kLogoStart, _kLogoEnd, curve: Curves.easeOut),
      ),
    );

    // ── Text line 1 ("Better") ───────────────────────────────────────────────
    _line1Blur = Tween<double>(begin: kMaxBlurSigma, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kLine1Start, _kLine1End, curve: Curves.easeOutQuart),
      ),
    );
    _line1Opacity = Tween<double>(begin: 0.0, end: 0.55).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kLine1Start, _kLine1End, curve: Curves.easeOut),
      ),
    );

    // ── Text lines 2–3 ("AquaVerse AI") ─────────────────────────────────────
    _line2Blur = Tween<double>(begin: kMaxBlurSigma, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kLine2Start, _kLine2End, curve: Curves.easeOutQuart),
      ),
    );
    _line2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kLine2Start, _kLine2End, curve: Curves.easeOut),
      ),
    );

    // ── Text line 4–5 (tagline — "Better decisions, better harvest.") ────────
    _line3Blur = Tween<double>(begin: kMaxBlurSigma, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kLine3Start, _kLine3End, curve: Curves.easeOutQuart),
      ),
    );
    _line3Opacity = Tween<double>(begin: 0.0, end: 0.70).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(_kLine3Start, _kLine3End, curve: Curves.easeOut),
      ),
    );

    // ── Button ghost→solid ───────────────────────────────────────────────────
    _buttonProgress = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(_kButtonStart, _kButtonEnd, curve: Curves.easeOut),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleGetStarted() async {
    if (_isLoadingRoute) return;
    setState(() => _isLoadingRoute = true);
    final splashController = ref.read(splashControllerProvider);
    final targetRoute = await splashController.determineNextRoute();
    if (mounted) context.go(targetRoute);
  }

  /// Blur-to-sharp text helper. Skips ImageFiltered when sigma ≤ 0.3
  /// to avoid unnecessary raster overhead on low-end devices.
  Widget _buildBlurText({
    required String text,
    required TextStyle style,
    required double sigma,
    required double opacity,
    TextAlign textAlign = TextAlign.left,
  }) {
    final clampedOpacity = opacity.clamp(0.0, 1.0);
    if (sigma <= 0.3) {
      return Opacity(
        opacity: clampedOpacity,
        child: Text(text, style: style, textAlign: textAlign),
      );
    }
    return Opacity(
      opacity: clampedOpacity,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Text(text, style: style, textAlign: textAlign),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final l10n = AppLocalizations.of(context);
    final taglineText =
        l10n?.betterDecisionsBetterHarvest ?? 'Better decisions, better harvest';

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final expand = _expandProgress.value;   // 0→1
          final orbit  = _orbitAngle.value;       // 0→2π

          // ── Blob geometry ─────────────────────────────────────────────────
          // At expand=0: two oval blobs orbiting at orbit radius.
          // At expand=1: single ellipse fills the screen completely.
          final blobRadius = size.shortestSide * 0.12; // 12% of screen width
          final orbitRadius = blobRadius * 1.6;

          // Blob positions: orbit contracts as expand increases
          final contractedOrbit = orbitRadius * (1.0 - expand);
          final cx = size.width  * 0.5;
          final cy = size.height * 0.47;

          final dot1x = cx + contractedOrbit * math.cos(orbit);
          final dot1y = cy + contractedOrbit * math.sin(orbit) * 0.7;
          final dot2x = cx + contractedOrbit * math.cos(orbit + math.pi);
          final dot2y = cy + contractedOrbit * math.sin(orbit + math.pi) * 0.7;

          // As expand→1, the blobs scale up to fill screen diagonally
          final fillDiagonal = math.sqrt(
            size.width * size.width + size.height * size.height,
          );
          // Blob width: small at 0, fills screen at 1
          final blob1W = blobRadius * 2 * (1 + expand * (fillDiagonal / (blobRadius * 2) - 1));
          final blob1H = blob1W * (0.75 + 0.25 * expand); // aspect ratio rounds to circle as it fills
          final blob2W = blob1W * (1.0 - expand * 0.5);   // dot2 shrinks/merges
          final blob2H = blob1H * (1.0 - expand * 0.5);

          // Background: white → teal gradient (driven by expand)
          final bgOpacity = expand.clamp(0.0, 1.0);

          return Stack(
            children: [
              // ── White base ────────────────────────────────────────────────
              Positioned.fill(child: Container(color: Colors.white)),

              // ── Background Image Fill (appears as expand increases) ────
              Positioned.fill(
                child: Opacity(
                  opacity: bgOpacity,
                  child: Stack(
                    children: [
                      // High-res Aquaculture Background Image with Contrast Enhancement
                      Positioned.fill(
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            0.85, 0,    0,    0, -15,
                            0,    0.88, 0,    0, -10,
                            0,    0,    0.88, 0, -10,
                            0,    0,    0,    1,   0,
                          ]),
                          child: Image.asset(
                            'assets/images/splash_background.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),

                      // High-contrast Dark Outline Floating Icons Overlay
                      const Positioned.fill(
                        child: FloatingIconsOverlay(
                          iconColor: Color(0xFF042738), // Dark Navy/Teal outline for 100% visibility
                        ),
                      ),
                      // Directional multi-stop gradient scrim per Section 2.2 specification
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.08), // Top: lightest
                                Colors.black.withValues(alpha: 0.28), // Mid: icons band
                                Colors.black.withValues(alpha: 0.40), // Mid-lower
                                Colors.black.withValues(alpha: 0.60), // Bottom: headline/subtext
                              ],
                              stops: const [0.0, 0.35, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Blob 1: solid seaGreen (fades out as background image reveals) ───
              if (expand < 0.95)
                Positioned(
                  left: dot1x - blob1W / 2,
                  top:  dot1y - blob1H / 2,
                  child: Opacity(
                    opacity: (1.0 - expand).clamp(0.0, 1.0),
                    child: Container(
                      width:  blob1W,
                      height: blob1H,
                      decoration: BoxDecoration(
                        color: AppColors.seaGreen,
                        borderRadius: BorderRadius.circular(blob1W),
                      ),
                    ),
                  ),
                ),

              // ── Blob 2: translucent brightMint (merges & fades away early) ──
              if (expand < 0.85)
                Positioned(
                  left: dot2x - blob2W / 2,
                  top:  dot2y - blob2H / 2,
                  child: Opacity(
                    opacity: (0.45 * (1.0 - expand / 0.85)).clamp(0.0, 1.0),
                    child: Container(
                      width:  blob2W,
                      height: blob2H,
                      decoration: BoxDecoration(
                        color: AppColors.brightMint,
                        borderRadius: BorderRadius.circular(blob2W),
                      ),
                    ),
                  ),
                ),

              // ── Text + Logo + Button (shown once background fills) ────────
              if (expand > 0.65)
                Positioned.fill(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // ── Logo mark (top-left) ────────────────────────
                          Opacity(
                            opacity: _logoOpacity.value,
                            child: Row(
                              children: [
                                // Two-circle toggle icon mark
                                SizedBox(
                                  width: 32,
                                  height: 20,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 2,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 12,
                                        top: 2,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.45),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'AquaVerse',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 2),

                          // ── Line 1: dim lead-in ("Get ready to") ─────────
                          _buildBlurText(
                            text: 'Get ready to',
                            sigma: _line1Blur.value,
                            opacity: _line1Opacity.value,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 2),

                          // ── Lines 2: hero bold ("AquaVerse AI") ──────────
                          _buildBlurText(
                            text: 'AquaVerse AI',
                            sigma: _line2Blur.value,
                            opacity: _line2Opacity.value,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.08,
                              letterSpacing: -0.5,
                            ),
                          ),

                          // ── Line 3: bold sub-headline ──────────────────
                          _buildBlurText(
                            text: 'your pond,\nyour harvest.',
                            sigma: _line2Blur.value,
                            opacity: _line2Opacity.value * 0.85,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.3,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Lines 4–5: tagline ─────────────────────────
                          _buildBlurText(
                            text: taglineText,
                            sigma: _line3Blur.value,
                            opacity: _line3Opacity.value,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Line 5: dim descriptor (smallest weight) ───
                          _buildBlurText(
                            text: 'AI-powered aquaculture for every farmer.',
                            sigma: _line3Blur.value,
                            opacity: _line3Opacity.value * 0.55,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              height: 1.4,
                              letterSpacing: 0.1,
                            ),
                          ),

                          const Spacer(flex: 3),

                          // ── Loading indicator while routing ───────────────
                          if (_isLoadingRoute)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Center(
                                child: _TwoDotsLoader(
                                  color1: AppColors.seaGreen,
                                  color2: AppColors.brightMint.withValues(alpha: 0.5),
                                ),
                              ),
                            ),

                          // ── Get Started button ─────────────────────────
                          _GetStartedButton(
                            progress: _buttonProgress.value,
                            isLoading: _isLoadingRoute,
                            onTap: _handleGetStarted,
                          ),

                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// GET STARTED BUTTON
// Matches reference: ghost (seaGreen tint) → solid white pill
// No arrow icon — reference has plain text only.
// =============================================================================

class _GetStartedButton extends StatelessWidget {
  final double progress; // 0→1
  final bool isLoading;
  final VoidCallback onTap;

  const _GetStartedButton({
    required this.progress,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = progress;

    // Ghost: seaGreen@20% border on transparent bg
    // Solid: white/cream fill (#FFFFFF), dark text
    final bgColor = Color.lerp(
      AppColors.seaGreen.withValues(alpha: 0.18),
      Colors.white,
      t,
    )!;
    final borderColor = Color.lerp(
      Colors.white.withValues(alpha: 0.30),
      Colors.white.withValues(alpha: 0.0),
      t,
    )!;
    final textColor = Color.lerp(
      Colors.white.withValues(alpha: 0.40),
      AppColors.deepNavy,
      t,
    )!;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: t > 0.6
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12 * t),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            'Get Started',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TWO DOTS LOADER
// Used only during route-determination delay after "Get Started" is tapped.
// Kept as a simple orbiting widget; different from the background blob animation.
// =============================================================================

class _TwoDotsLoader extends StatefulWidget {
  final Color color1;
  final Color color2;

  const _TwoDotsLoader({required this.color1, required this.color2});

  @override
  State<_TwoDotsLoader> createState() => _TwoDotsLoaderState();
}

class _TwoDotsLoaderState extends State<_TwoDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lc;

  @override
  void initState() {
    super.initState();
    _lc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _lc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _lc,
      builder: (context, _) {
        final angle = _lc.value * math.pi * 2;
        const r = 14.0;
        const d = 8.0;
        return SizedBox(
          width: (r + d) * 2 + 4,
          height: (r + d) * 2 + 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(
                  r * math.cos(angle),
                  r * math.sin(angle),
                ),
                child: Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    color: widget.color1,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(
                  r * math.cos(angle + math.pi),
                  r * math.sin(angle + math.pi),
                ),
                child: Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    color: widget.color2,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
