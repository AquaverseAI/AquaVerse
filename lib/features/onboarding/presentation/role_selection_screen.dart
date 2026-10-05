import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/onboarding_scaffold.dart';
import 'controllers/onboarding_controller.dart';

/// RoleSelectionScreen — first step of the two-screen authentication flow.
///
/// Route: `/onboarding/role`
///
/// The user picks their role (Farmer or Extension Officer) BEFORE entering
/// a phone number. The selection is stored as `selectedRole` (user intent only).
/// The verified role from the backend JWT is the final authorization authority.
///
/// Continue is disabled until a role card has been tapped.
class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return OnboardingScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  // Back arrow visible only when returning via back navigation
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                    tooltip: 'Back',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/onboarding/language');
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────────
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
                          const SizedBox(height: AppSpacing.md),

                          // ── Brand logo / icon ────────────────────────────────
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.langCtaGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.langAccentPrimary
                                        .withValues(alpha: 0.25),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.waves_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // ── Title ────────────────────────────────────────────
                          const Text(
                            'Who are you?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D2B3E),
                              letterSpacing: -0.4,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          // ── Subtitle ─────────────────────────────────────────
                          const Text(
                            'Select your role to get started',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          // ── Role cards ───────────────────────────────────────
                          _RoleCard(
                            roleKey: 'farmer',
                            label: 'Farmer',
                            sublabel: 'Manage your pond and get daily recommendations',
                            icon: Icons.water_drop_rounded,
                            isSelected: state.selectedRole == 'farmer' &&
                                state.isRoleExplicitlySet,
                            onTap: () => controller.selectRole('farmer'),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          _RoleCard(
                            roleKey: 'officer',
                            label: 'Extension Officer',
                            sublabel: 'Oversee multiple ponds and log field visits',
                            icon: Icons.assignment_ind_rounded,
                            isSelected: state.selectedRole == 'officer' &&
                                state.isRoleExplicitlySet,
                            onTap: () => controller.selectRole('officer'),
                          ),

                          // ── Validation message ───────────────────────────────
                          if (!state.isRoleExplicitlySet) ...[
                            const SizedBox(height: AppSpacing.lg),
                            const Text(
                              'Please select a role to continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],

                          const Spacer(flex: 3),

                          // ── Continue button ──────────────────────────────────
                          _ContinueButton(
                            enabled: state.canContinueFromRoleSelection,
                            onTap: () => context.push('/onboarding/mobile'),
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
    );
  }
}

// ── Role Card ────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String roleKey;
  final String label;
  final String sublabel;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.roleKey,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  static const _selectedBorder = Color(0xFF0E9488);
  static const _restBorder = Color(0xFFD8E8E4);
  static const _selectedBg = Color(0xFFE6F4F1);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label role ${isSelected ? ', selected' : ''}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? _selectedBg : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? _selectedBorder : _restBorder,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _selectedBorder.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  // Icon container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? _selectedBorder.withValues(alpha: 0.12)
                          : AppColors.background,
                      border: Border.all(
                        color: isSelected
                            ? _selectedBorder.withValues(alpha: 0.4)
                            : _restBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: AppIconSize.xl,
                      color: isSelected
                          ? _selectedBorder
                          : AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(width: AppSpacing.lg),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? _selectedBorder
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          sublabel,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Selected check / unselected ring
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? _selectedBorder : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? _selectedBorder : _restBorder,
                        width: 2.0,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Continue Button ──────────────────────────────────────────────────────────

class _ContinueButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ContinueButton({required this.enabled, required this.onTap});

  static const _activeGradient = LinearGradient(
    colors: [Color(0xFF0E9488), Color(0xFF1495AE)],
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Continue to phone number entry',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        height: AppTouchTarget.buttonHeight + 6, // 54dp
        decoration: BoxDecoration(
          gradient: enabled
              ? _activeGradient
              : LinearGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.45),
                    AppColors.primary600.withValues(alpha: 0.45),
                  ],
                ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary500.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          child: const Text(
            'Continue',
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

