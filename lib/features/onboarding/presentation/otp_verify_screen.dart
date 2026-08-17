import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/onboarding_scaffold.dart';
import '../../../shared/widgets/speaker_button.dart';
import 'controllers/onboarding_controller.dart';

/// OTP Verification Screen with vertically centered layout and enlarged digit boxes.
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
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
    super.dispose();
  }

  String get _fullOtpCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
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

    final code = _fullOtpCode;
    ref.read(onboardingControllerProvider.notifier).setOtpCode(code);

    if (code.length == 6) {
      _onVerifyOtp();
    }
  }

  void _onVerifyOtp() async {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final success = await controller.verifyOtp();

    if (success && mounted) {
      context.push('/onboarding/role');
    } else if (mounted) {
      _shakeController.forward(from: 0.0);
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
            // Top Bar: Back Button (left) & Speaker Button (right)
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
                    textToSpeak: 'Verify OTP. Enter OTP sent to plus 91 $formattedMobile.',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Vertical centering top spacer
                    const Spacer(flex: 2),

                    // Centered Title & Subtitle
                    const Text(
                      'Verify OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
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
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
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

                    const SizedBox(height: 36),

                    // 6 Separate Digit Boxes with Shake Animation (Enlarged)
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final isError = state.isOtpInvalid;
                          final isFocused = _focusNodes[index].hasFocus;

                          return Container(
                            width: 48,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isError
                                    ? AppColors.critical
                                    : (isFocused ? focusBorderColor : restBorderColor),
                                width: isError || isFocused ? 2.0 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isFocused
                                      ? focusBorderColor.withValues(alpha: 0.15)
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
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
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
                          );
                        }),
                      ),
                    ),

                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.critical,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Resend Timer Countdown / Action Link
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

                    // Bottom Spacer for vertical balance
                    const Spacer(flex: 3),

                    // Primary Pill Gradient CTA Button ("Verify & Continue")
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: (state.isOtpValid && !state.isLoading)
                            ? AppColors.langCtaGradient
                            : LinearGradient(
                                colors: [
                                  AppColors.primary500.withValues(alpha: 0.5),
                                  AppColors.primary600.withValues(alpha: 0.5),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: (state.isOtpValid && !state.isLoading)
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
                        onPressed: (state.isOtpValid && !state.isLoading) ? _onVerifyOtp : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: state.isLoading
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
          ],
        ),
      ),
    );
  }
}
