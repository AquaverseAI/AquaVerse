import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/onboarding_flag_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/onboarding_scaffold.dart';
import '../../../shared/widgets/speaker_button.dart';
import 'controllers/onboarding_controller.dart';

/// OTP Verification Choreography Status Machine
enum OtpAnimState { filling, verifying, success, error }

/// Rebuilt OTP Verification Screen with complete Motion Choreography:
/// - Auto-trigger on final digit.
/// - Verifying Phase 1: Staggered 80ms cascade bounce with rotation.
/// - Verifying Phase 2: Animated left-to-right connector stroke trace.
/// - Verifying Phase 3: Morph collapse into stacked badge.
/// - Success Phase: Resolved checkmark badge + continuous looping radial pulse + header text crossfade.
/// - Error Phase: Horizontal shake + red outline + error message.
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  OtpAnimState _animState = OtpAnimState.filling;

  // Animation Controllers
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  late AnimationController _cascadeController;
  late AnimationController _traceController;
  late AnimationController _collapseController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    // 1. Error Shake
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    // 2. Cascade Bounce
    _cascadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // 3. Connector Trace
    _traceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 4. Morph Collapse
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // 5. Continuous Looping Radial Glow Pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    _cascadeController.dispose();
    _traceController.dispose();
    _collapseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String get _fullOtpCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (_animState == OtpAnimState.verifying || _animState == OtpAnimState.success) return;

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length > 1) {
      // Handle pasting multi-digit OTP code
      for (int i = 0; i < 6; i++) {
        if (i < digitsOnly.length) {
          _controllers[i].text = digitsOnly[i];
        } else {
          _controllers[i].clear();
        }
      }
      final nextIndex = digitsOnly.length >= 6 ? 5 : digitsOnly.length;
      if (digitsOnly.length >= 6) {
        _focusNodes[nextIndex].unfocus();
      } else {
        _focusNodes[nextIndex].requestFocus();
      }
    } else {
      // Single digit entry / backspace
      if (value.isNotEmpty) {
        if (index < 5) {
          _focusNodes[index + 1].requestFocus();
        } else {
          _focusNodes[index].unfocus();
        }
      } else {
        if (index > 0) {
          _focusNodes[index - 1].requestFocus();
        }
      }
    }

    final code = _fullOtpCode;
    ref.read(onboardingControllerProvider.notifier).setOtpCode(code);

    if (code.length == 6) {
      _startVerificationChoreography();
    }
  }

  void _triggerErrorFlow() async {
    if (!mounted) return;
    setState(() {
      _animState = OtpAnimState.error;
    });
    _shakeController.forward(from: 0.0);

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _animState = OtpAnimState.filling;
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      });
    }
  }

  void _startVerificationChoreography() async {
    if (_animState == OtpAnimState.verifying || _animState == OtpAnimState.success) return;

    setState(() {
      _animState = OtpAnimState.verifying;
    });

    try {
      // Run Choreography Sequence
      // Step A: Cascade Bounce
      _cascadeController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 250));

      // Step B: Connector Trace
      _traceController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 450));

      // Step C: Trigger Backend Verification
      final controller = ref.read(onboardingControllerProvider.notifier);
      final success = await controller.verifyOtp();

      if (success) {
        // Step D: Morph Collapse
        await _collapseController.forward(from: 0.0);

        if (mounted) {
          setState(() {
            _animState = OtpAnimState.success;
          });
        }

        // Start continuous looping radial glow
        _glowController.repeat(reverse: true);

        // Check onboarding status and persist selected role
        final flagStore = await OnboardingFlagStore.create();
        final state = ref.read(onboardingControllerProvider);
        await flagStore.setSelectedRole(state.selectedRole);
        await flagStore.setSelectedLanguage(state.selectedLanguage);
        await flagStore.setMobileNumber(state.mobileNumber);

        final hasOnboardedAlready = flagStore.hasOnboarded;

        final String nextRoute;
        if (state.selectedRole == 'officer') {
          // Extension Officer role -> Always route directly to Officer Dashboard
          await flagStore.setHasOnboarded(true);
          nextRoute = '/officer/dashboard';
        } else if (hasOnboardedAlready) {
          // Returning farmer user -> Go directly to Today dashboard
          nextRoute = '/today';
        } else {
          // First-time onboarding farmer -> Proceed to Role Selection
          nextRoute = '/onboarding/role';
        }

        // Brief delay to wow user with success state before route transition
        await Future.delayed(const Duration(milliseconds: 1600));
        if (mounted) {
          context.go(nextRoute);
        }
      } else {
        _triggerErrorFlow();
      }
    } catch (e) {
      _triggerErrorFlow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final formattedMobile = state.mobileNumber.length == 10
        ? '${state.mobileNumber.substring(0, 5)} ${state.mobileNumber.substring(5)}'
        : state.mobileNumber;

    const restBorderColor = Color(0xFFD8E8E4);
    const focusBorderColor = Color(0xFF0E9488);

    return OnboardingScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  SpeakerButton(
                    textToSpeak: _animState == OtpAnimState.success
                        ? 'Verified successfully. Your account is secure.'
                        : 'Verify OTP. Enter OTP sent to plus 91 $formattedMobile.',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),

                    // Animated Header Text Crossfade (Section 3.5 spec)
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 400),
                      crossFadeState: _animState == OtpAnimState.success
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Column(
                        children: [
                          const Text(
                            'Verify OTP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D2B3E), // deep navy — max contrast
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Enter OTP sent to +91 $formattedMobile',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary, // lifted from textSecondary
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: focusBorderColor,
                                ),
                                onPressed: () => context.pop(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      secondChild: Column(
                        children: const [
                          Text(
                            'Verified successfully',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D2B3E), // deep navy — max contrast
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your account is secure',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary, // lifted from textSecondary
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Central Choreography Motion Area
                    if (_animState != OtpAnimState.success)
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _shakeController,
                          _cascadeController,
                          _traceController,
                          _collapseController,
                        ]),
                        builder: (context, child) {
                          final collapseVal = _collapseController.value;

                          return Transform.scale(
                            scale: 1.0 - (collapseVal * 0.4),
                            child: Opacity(
                              opacity: (1.0 - collapseVal).clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(_shakeAnimation.value, 0),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Layer 1: Trace Connector Lines CustomPainter (Section 3.3 spec)
                                    if (_animState == OtpAnimState.verifying)
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: _ConnectorTracePainter(
                                            progress: _traceController.value,
                                            boxCount: 6,
                                          ),
                                        ),
                                      ),

                                    // Layer 2: 6 Digit Boxes with Staggered Cascade Bounce
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(6, (index) {
                                        final isError = _animState == OtpAnimState.error;
                                        final isFocused = _focusNodes[index].hasFocus;

                                        // Staggered bounce math (Section 3.2 spec)
                                        double translateY = 0.0;
                                        double rotateRad = 0.0;
                                        if (_animState == OtpAnimState.verifying) {
                                          final startTime = index * 0.12;
                                          final endTime = startTime + 0.40;
                                          final t = ((_cascadeController.value - startTime) /
                                                  (endTime - startTime))
                                              .clamp(0.0, 1.0);
                                          final bounceCurve = math.sin(t * math.pi);
                                          translateY = -12.0 * bounceCurve;
                                          rotateRad = (index % 2 == 0 ? 0.06 : -0.06) * bounceCurve;
                                        }

                                        return Transform.translate(
                                          offset: Offset(0, translateY),
                                          child: Transform.rotate(
                                            angle: rotateRad,
                                            child: Container(
                                              width: 48,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isError
                                                      ? AppColors.critical
                                                      : (isFocused || _animState == OtpAnimState.verifying
                                                          ? focusBorderColor
                                                          : restBorderColor),
                                                  width: isError || isFocused || _animState == OtpAnimState.verifying
                                                      ? 2.0
                                                      : 1.2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isFocused || _animState == OtpAnimState.verifying
                                                        ? focusBorderColor.withValues(alpha: 0.20)
                                                        : Colors.black.withValues(alpha: 0.03),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  )
                                                ],
                                              ),
                                              child: TextField(
                                                controller: _controllers[index],
                                                focusNode: _focusNodes[index],
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                readOnly: _animState == OtpAnimState.verifying,
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                  LengthLimitingTextInputFormatter(6),
                                                ],
                                                decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                  enabledBorder: InputBorder.none,
                                                  focusedBorder: InputBorder.none,
                                                  errorBorder: InputBorder.none,
                                                  focusedErrorBorder: InputBorder.none,
                                                  contentPadding: EdgeInsets.zero,
                                                ),
                                                onChanged: (value) => _onDigitChanged(index, value),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    else
                      // Resolved Success State: Badge + Continuous Looping Glow (Section 3.5 spec)
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          final scale = 1.0 + 0.12 * math.sin(_glowController.value * math.pi);
                          final glowOpacity = 0.35 - 0.20 * math.sin(_glowController.value * math.pi);

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Looping Radial Glow Pulse
                                  Transform.scale(
                                    scale: scale * 1.3,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF22C55E).withValues(alpha: glowOpacity),
                                      ),
                                    ),
                                  ),

                                  // Resolved Badge Shape
                                  Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(22),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF0E9488), // Teal accent
                                            Color(0xFF22C55E), // Success green
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                                            blurRadius: 18,
                                            offset: const Offset(0, 6),
                                          )
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        size: 44,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Verified and secure',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0E9488),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                    if (_animState == OtpAnimState.error || state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage ?? 'Incorrect code, try again',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.critical,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Resend Link (Visible during filling state)
                    if (_animState == OtpAnimState.filling)
                      Center(
                        child: state.resendCountdown > 0
                            ? Text(
                                'Resend OTP in 00:${state.resendCountdown.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              )
                            : TextButton(
                                onPressed: () {
                                  ref
                                      .read(onboardingControllerProvider.notifier)
                                      .sendOtp();
                                },
                                child: const Text(
                                  'Resend OTP',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: focusBorderColor,
                                  ),
                                ),
                              ),
                      ),

                    const Spacer(flex: 3),

                    // Primary Pill Gradient CTA Button
                    if (_animState != OtpAnimState.success)
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 360),
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: (state.isOtpValid && _animState != OtpAnimState.verifying)
                              ? AppColors.langCtaGradient
                              : LinearGradient(
                                  colors: [
                                    AppColors.primary500.withValues(alpha: 0.5),
                                    AppColors.primary600.withValues(alpha: 0.5),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(27),
                          boxShadow: (state.isOtpValid && _animState != OtpAnimState.verifying)
                              ? [
                                  BoxShadow(
                                    color: focusBorderColor.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: ElevatedButton(
                          onPressed: (state.isOtpValid && _animState == OtpAnimState.filling)
                              ? _startVerificationChoreography
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          child: _animState == OtpAnimState.verifying
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Verify & Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),

                    const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter that progressively draws an animated connecting line trace (Section 3.3 spec)
class _ConnectorTracePainter extends CustomPainter {
  final double progress;
  final int boxCount;

  _ConnectorTracePainter({required this.progress, required this.boxCount});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = const Color(0xFF0E9488)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final boxWidth = 48.0;
    final totalWidth = size.width;
    final step = (totalWidth - (boxWidth * boxCount)) / (boxCount - 1) + boxWidth;

    path.moveTo(boxWidth / 2, size.height / 2);
    for (int i = 1; i < boxCount; i++) {
      final x = (boxWidth / 2) + (i * step);
      final y = (size.height / 2) + (i % 2 == 0 ? 4 : -4);
      path.lineTo(x, y);
    }

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorTracePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
