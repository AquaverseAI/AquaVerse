import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/speaker_button.dart';
import 'controllers/onboarding_controller.dart';

/// PhoneEntryScreen — second step of the two-step authentication flow.
///
/// Route: `/onboarding/mobile`
///
/// The user enters their 10-digit Indian mobile number here.
/// Role selection has ALREADY happened on [RoleSelectionScreen].
/// This screen shows the selected role as a compact read-only summary
/// and offers a "Change role" back link.
///
/// On successful OTP request → navigates to `/onboarding/otp`.
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
      if (mounted) {
        setState(() => _isFocused = _phoneFocusNode.hasFocus);
      }
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

  void _onChangeRole() {
    // Pop back to RoleSelectionScreen.
    // If the stack doesn't have it, push the route directly.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/onboarding/role');
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
          // Background image
          const _PhoneEntryBackground(),

          // Content
          SafeArea(
            child: Column(
              children: [
                // ── Top navigation bar ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                        ),
                        tooltip: 'Back to role selection',
                        onPressed: _onChangeRole,
                      ),
                      const Spacer(),
                      const SpeakerButton(
                        textToSpeak:
                            'Enter your mobile number to receive a one-time password.',
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),

                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: AppSpacing.lg),

                              // ── Title ──────────────────────────────────────────
                              const Text(
                                'Enter your phone number',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D2B3E),
                                  letterSpacing: -0.4,
                                ),
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              const Text(
                                'We\'ll send a verification code to this number',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xl),

                              // ── Selected-role summary chip ────────────────────
                              _RoleSummaryChip(
                                role: state.selectedRole,
                                onChangeRole: _onChangeRole,
                              ),

                              const SizedBox(height: AppSpacing.xl),

                              // ── Mobile number input ───────────────────────────
                              const Align(
                                alignment: Alignment.center,
                                child: Text(
                                  'MOBILE NUMBER',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Elevated input container
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 64,
                                constraints: const BoxConstraints(maxWidth: 360),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppRadius.card),
                                  border: Border.all(
                                    color: currentBorderColor,
                                    width: _isFocused ||
                                            state.isMobileValid ||
                                            state.errorMessage != null
                                        ? 2.0
                                        : 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isFocused || state.isMobileValid
                                          ? focusBorderColor
                                              .withValues(alpha: 0.18)
                                          : Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // +91 badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
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

                                    // Phone number field
                                    Expanded(
                                      child: TextField(
                                        controller: _phoneController,
                                        focusNode: _phoneFocusNode,
                                        keyboardType: TextInputType.phone,
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
                                              .read(
                                                onboardingControllerProvider
                                                    .notifier,
                                              )
                                              .setMobileNumber(value);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Error message
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

                              const Spacer(flex: 3),

                              // ── Send OTP button ──────────────────────────────
                              _SendOtpButton(
                                isEnabled: state.isMobileValid && !state.isLoading,
                                isLoading: state.isLoading,
                                onTap: _onSendOtp,
                              ),

                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ],
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

// ── Selected-role summary chip ───────────────────────────────────────────────

class _RoleSummaryChip extends StatelessWidget {
  final String role;
  final VoidCallback onChangeRole;

  const _RoleSummaryChip({
    required this.role,
    required this.onChangeRole,
  });

  String get _roleLabel =>
      role == 'officer' ? 'Extension Officer' : 'Farmer';

  IconData get _roleIcon =>
      role == 'officer'
          ? Icons.assignment_ind_rounded
          : Icons.water_drop_rounded;

  @override
  Widget build(BuildContext context) {
    const chipColor = Color(0xFF0E9488);
    const chipBg = Color(0xFFE6F4F1);

    return Semantics(
      label: 'Selected role: $_roleLabel. Tap Change to go back.',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: chipColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_roleIcon, size: AppIconSize.sm, color: chipColor),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _roleLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: chipColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(width: 1, height: 16, color: chipColor.withValues(alpha: 0.3)),
            const SizedBox(width: AppSpacing.md),
            GestureDetector(
              onTap: onChangeRole,
              child: const Text(
                'Change',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: chipColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Send OTP Button ──────────────────────────────────────────────────────────

class _SendOtpButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _SendOtpButton({
    required this.isEnabled,
    required this.isLoading,
    required this.onTap,
  });

  static const _focusBorderColor = Color(0xFF0E9488);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: 'Send OTP to mobile number',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        height: 54,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? AppColors.langCtaGradient
              : LinearGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.5),
                    AppColors.primary600.withValues(alpha: 0.5),
                  ],
                ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: _focusBorderColor.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          child: isLoading
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
    );
  }
}

// ── Background ───────────────────────────────────────────────────────────────

class _PhoneEntryBackground extends StatelessWidget {
  const _PhoneEntryBackground();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.low,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.72),
                    Colors.white.withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
