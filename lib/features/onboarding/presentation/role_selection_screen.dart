import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/onboarding_scaffold.dart';
import '../../../shared/widgets/speaker_button.dart';
import 'controllers/onboarding_controller.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  void _onContinue(BuildContext context, WidgetRef ref) async {
    final state = ref.read(onboardingControllerProvider);
    if (state.selectedRole == 'farmer') {
      context.go('/onboarding/intro');
    } else {
      final controller = ref.read(onboardingControllerProvider.notifier);
      final targetRoute = await controller.completeOnboarding();
      if (context.mounted) {
        context.go(targetRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    final roles = [
      {
        'id': 'farmer',
        'title': 'Farmer',
        'subtitle': 'Pond management, daily logs, AI advisory & alerts',
        'icon': Icons.water_drop_rounded,
      },
      {
        'id': 'officer',
        'title': 'Extension Officer',
        'subtitle': 'Multi-pond oversight, farmer visit logs & report verification',
        'icon': Icons.assignment_ind_rounded,
      },
    ];

    return OnboardingScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageMargin, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Subtitle Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Your Role',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose how you want to use AquaVerse AI',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SpeakerButton(
                    textToSpeak: 'Select Your Role. Choose how you want to use AquaVerse AI.',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Dual Selectable Role Cards
              ...roles.map((role) {
                final isSelected = state.selectedRole == role['id'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    onTap: () => controller.selectRole(role['id'] as String),
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(20),
                      opacity: isSelected ? 0.55 : 0.40,
                      fillColor: isSelected ? AppColors.surfaceAqua : Colors.white,
                      borderRadius: AppTheme.cardRadius,
                      border: Border.all(
                        color: isSelected ? AppColors.primary500 : Colors.white.withValues(alpha: 0.60),
                        width: isSelected ? 2.0 : 1.2,
                      ),
                      child: Row(
                        children: [
                          // Role Icon Container
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primary100
                                  : AppColors.background,
                            ),
                            child: Icon(
                              role['icon'] as IconData,
                              size: 28,
                              color: isSelected ? AppColors.primary700 : AppColors.mountain700,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role['title'] as String,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppColors.primary700 : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected ? AppColors.primary500 : AppColors.textMuted,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Custom Selection Radio Indicator Disc
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.primary500 : AppColors.borderStrong,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary500,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const Spacer(),

              // "Continue" Primary Action Button
              ElevatedButton(
                onPressed: () => _onContinue(context, ref),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue'),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
