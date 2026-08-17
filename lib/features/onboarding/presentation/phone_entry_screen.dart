import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/speaker_button.dart';
import 'controllers/onboarding_controller.dart';

/// Rebuilt Login / Phone Entry Screen strictly following Section 0-6 Prompt Specifications.
/// Features:
/// - Full-bleed `assets/images/login_bg.png` background (teal glass-wave artwork top & bottom).
/// - Curved header spacing with left-aligned title & subtitle + SpeakerButton.
/// - Underline-style mobile number input with rest (#D8E8E4) and focus (#0E9488) states.
/// - Fixed +91 country prefix.
/// - Bottom pill-shaped CTA stack: Primary "Send OTP" gradient button + Secondary "Use email instead" outlined button.
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

    // Color tokens per specification
    const restBorderColor = Color(0xFFD8E8E4);
    const focusBorderColor = Color(0xFF0E9488); // --color-field-focus-border

    final currentBorderColor = state.errorMessage != null
        ? AppColors.critical
        : (_isFocused || state.isMobileValid ? focusBorderColor : restBorderColor);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Full-bleed Background Image (Section 2 spec)
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // 2. Safe Area Screen Content Layout (Section 5 spec)
          SafeArea(
            child: Column(
              children: [
                // Top App Bar / Back Button
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
                        textToSpeak: "Login. Enter your mobile number to continue.",
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // 3.1 Header Text (Section 3.1 & Section 5 spec)
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter your mobile number to continue',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // 3.2 Form: Underline-style Mobile Input (Section 3.2 & Section 4 spec)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Field Label Above
                            const Text(
                              'MOBILE NUMBER',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Underline Input Container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: currentBorderColor,
                                    width: _isFocused || state.isMobileValid || state.errorMessage != null ? 2.0 : 1.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Pinned Country Code Prefix
                                  const Text(
                                    '+91',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: currentBorderColor,
                                  ),
                                  const SizedBox(width: 12),

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
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
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
                              const SizedBox(height: 8),
                              Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.critical,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Flexible whitespace to let background breathe
                        const Spacer(),

                        // 3.3 Buttons Stack (Section 3.3 & Section 5 spec)
                        // Primary Pill Gradient CTA
                        Container(
                          width: double.infinity,
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

                        const SizedBox(height: 12),

                        // Secondary Outlined Pill Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Email login coming soon'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: const BorderSide(color: focusBorderColor, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            child: const Text(
                              'Use email instead',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: focusBorderColor,
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
