import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'splash_controller.dart';

// =============================================================================
// TIMING CONSTANTS (Matched from Sphere Animation.mp4 & Splash screen reference.mp4)
// =============================================================================

/// Total duration of the initial entrance spin & scale-in animation.
/// Matched from Sphere Animation.mp4: sphere rotates in with scaling over ~2.4s.
const Duration kEntranceDuration = Duration(milliseconds: 2400);

/// Delay before the header title ("AquaVerse AI") begins to fade & slide in.
/// Matched from Splash screen reference.mp4: title reveals near the end of logo entrance.
const Duration kHeaderDelay = Duration(milliseconds: 1800);

/// Delay before the subtitle ("Better decisions, better harvest") reveals.
/// Matched from reference: 300ms staggered offset after title.
const Duration kSubtitleDelay = Duration(milliseconds: 2100);

/// Delay before the primary "Get Started" button reveals.
/// Matched from reference: button appears as motion settles at 2.4s.
const Duration kButtonDelay = Duration(milliseconds: 2400);

/// Cycle duration of the continuous 360° Y-axis idle rotation after entrance.
/// Matched from Sphere Animation.mp4: slow continuous ambient turn.
const Duration kIdleRotationDuration = Duration(seconds: 12);

// =============================================================================
// SPLASH SCREEN REBUILD
// =============================================================================

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _idleController;
  late final AnimationController _staggerController;

  late final Animation<double> _entranceRotation;
  late final Animation<double> _entranceScale;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Controller (2.4s duration, Curves.easeOutCubic)
    _entranceController = AnimationController(
      vsync: this,
      duration: kEntranceDuration,
    );

    _entranceRotation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _entranceScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Idle Looping Controller (12s per full Y-axis rotation)
    _idleController = AnimationController(
      vsync: this,
      duration: kIdleRotationDuration,
    );

    _entranceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _idleController.repeat();
      }
    });

    // 3. Staggered Elements Controller
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    final double totalMs = 3000.0;
    _headerFade = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(
        kHeaderDelay.inMilliseconds / totalMs,
        (kHeaderDelay.inMilliseconds + 500) / totalMs,
        curve: Curves.easeOut,
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(_headerFade);

    _subtitleFade = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(
        kSubtitleDelay.inMilliseconds / totalMs,
        (kSubtitleDelay.inMilliseconds + 500) / totalMs,
        curve: Curves.easeOut,
      ),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(_subtitleFade);

    _buttonFade = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(
        kButtonDelay.inMilliseconds / totalMs,
        (kButtonDelay.inMilliseconds + 500) / totalMs,
        curve: Curves.easeOut,
      ),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(_buttonFade);

    // Start entrance animations
    _entranceController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _idleController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _handleGetStarted() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    final splashController = ref.read(splashControllerProvider);
    final targetRoute = await splashController.determineNextRoute();

    if (mounted) {
      context.go(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtitleText =
        l10n?.betterDecisionsBetterHarvest ?? 'Better decisions, better harvest';

    return Scaffold(
      backgroundColor: AppColors.mountain900,
      body: Stack(
        children: [
          // 1. Full-Bleed Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.mountain900,
                      Color(0xFF0F2E48),
                      AppColors.mountain900,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Main Centered Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // 3D Rotating Sphere / Logo Object
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _entranceController,
                      _idleController,
                    ]),
                    builder: (context, child) {
                      // Total Y-angle = initial 360° entrance spin + ongoing idle rotation
                      final entranceY = _entranceRotation.value * math.pi * 2;
                      final idleY = _idleController.value * math.pi * 2;
                      final totalY = entranceY + idleY;

                      // Subtle 15° X-axis tumble angle
                      final xAngle = 0.26 * math.sin(totalY * 0.5);

                      // Perspective matrix transform (perspective = 0.0015)
                      final transform = Matrix4.identity()
                        ..setEntry(3, 2, 0.0015)
                        ..rotateY(totalY)
                        ..rotateX(xAngle);

                      // Animated Specular Gradient Sweep position
                      final sweepProgress = (totalY / (math.pi * 2)) % 1.0;

                      return Transform.scale(
                        scale: _entranceScale.value,
                        child: Transform(
                          transform: transform,
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Radial Ambient Glow
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary700.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: AppColors.seaGreen.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 60,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              ),

                              // AquaVerse Glass-Fish Mark with Specular ShaderMask Sweep
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    begin: Alignment(
                                      -1.0 + (sweepProgress * 2.0),
                                      -1.0,
                                    ),
                                    end: Alignment(
                                      1.0 + (sweepProgress * 2.0),
                                      1.0,
                                    ),
                                    colors: const [
                                      AppColors.primary700, // #1B4F7A Deep Navy
                                      AppColors.seaGreen,   // #4FAE9E Sea Green
                                      Colors.white,         // Specular highlight
                                      AppColors.brightMint, // #3FCCA6 Bright Mint
                                      AppColors.primary700,
                                    ],
                                    stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.srcATop,
                                child: Image.asset(
                                  'assets/images/splash_logo.png',
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.water_drop_rounded,
                                    size: 100,
                                    color: AppColors.brightMint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // Staggered Title: "AquaVerse AI"
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: const Text(
                      'AquaVerse AI',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.8,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Staggered Subtitle: "Better decisions, better harvest"
                FadeTransition(
                  opacity: _subtitleFade,
                  child: SlideTransition(
                    position: _subtitleSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        subtitleText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Staggered Button: "Get Started"
                FadeTransition(
                  opacity: _buttonFade,
                  child: SlideTransition(
                    position: _buttonSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 24.0,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary700,
                                AppColors.seaGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(27),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.seaGreen.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isNavigating ? null : _handleGetStarted,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
