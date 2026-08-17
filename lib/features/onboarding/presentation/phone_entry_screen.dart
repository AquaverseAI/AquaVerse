import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/speaker_button.dart';
import 'controllers/onboarding_controller.dart';

/// Phone Entry Screen with elevated, perfectly styled input container layout.
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    final mobile = ref.read(onboardingControllerProvider).mobileNumber;
    _phoneController.text = mobile;

    _phoneFocusNode.addListener(() {
      setState(() {
        _isFocused = _phoneFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onSendOtp() async {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final success = await controller.sendOtp();
    if (success && mounted) {
      context.push('/onboarding/otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);

    const restBorderColor = Color(0xFFD8E8E4);
    const focusBorderColor = Color(0xFF0E9488);

    final currentBorderColor = state.errorMessage != null
        ? AppColors.critical
        : (_isFocused || state.isMobileValid ? focusBorderColor : restBorderColor);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Full-bleed Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // 2. Safe Area Content Layout
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar: Pinned Back Arrow (left) & Speaker Button (right)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      const SpeakerButton(
                        textToSpeak: "Welcome back. Enter your mobile number to continue.",
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
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter your mobile number to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Centered Form: Elevated, Perfectly Fitted Input Card
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'MOBILE NUMBER',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Styled Elevated Input Container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 64,
                              constraints: const BoxConstraints(maxWidth: 360),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: currentBorderColor,
                                  width: _isFocused || state.isMobileValid || state.errorMessage != null ? 2.0 : 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _isFocused || state.isMobileValid
                                        ? focusBorderColor.withValues(alpha: 0.18)
                                        : Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Fixed +91 Badge Container
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F4F1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '+91',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: focusBorderColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Container(
                                    width: 1.2,
                                    height: 24,
                                    color: currentBorderColor,
                                  ),
                                  const SizedBox(width: 14),

                                  // 10-Digit Mobile Text Field
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      focusNode: _phoneFocusNode,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2.0,
                                        color: AppColors.textPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Enter mobile number',
                                        hintStyle: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0.2,
                                          color: AppColors.textMuted,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                      ),
                                      onChanged: (value) {
                                        ref
                                            .read(onboardingControllerProvider.notifier)
                                            .setMobileNumber(value);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (state.errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                state.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.critical,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Bottom Spacer for vertical balance
                        const Spacer(flex: 3),

                        // Primary Pill Gradient CTA Button ("Send OTP")
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 360),
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: (state.isMobileValid && !state.isLoading)
                                ? AppColors.langCtaGradient
                                : LinearGradient(
                                    colors: [
                                      AppColors.primary500.withValues(alpha: 0.5),
                                      AppColors.primary600.withValues(alpha: 0.5),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(27),
                            boxShadow: (state.isMobileValid && !state.isLoading)
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
                            onPressed: (state.isMobileValid && !state.isLoading) ? _onSendOtp : null,
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
                                    'Send OTP',
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
        ],
      ),
    );
  }
}
