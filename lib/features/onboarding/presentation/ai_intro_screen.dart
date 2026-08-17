import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/speaker_button.dart';
import 'controllers/onboarding_controller.dart';

class AiIntroScreen extends ConsumerWidget {
  const AiIntroScreen({super.key});

  void _onContinue(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final targetRoute = await controller.completeOnboarding();
    if (context.mounted) {
      context.go(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                          'Meet Aqua, Your AI Assistant',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Always here to help you manage your pond and boost your harvest.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SpeakerButton(
                    textToSpeak: 'Meet Aqua, Your AI Assistant. Always here to help you manage your pond and boost your harvest.',
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary500.withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.assistant_rounded,
                    size: 72,
                    color: AppColors.primary700,
                  ),
                ),
              ),
              const Spacer(),
              // Features list
              _FeatureRow(icon: Icons.mic_rounded, text: 'Use your voice in local language'),
              const SizedBox(height: 16),
              _FeatureRow(icon: Icons.camera_alt_rounded, text: 'Take photos to diagnose diseases'),
              const SizedBox(height: 16),
              _FeatureRow(icon: Icons.timeline_rounded, text: 'Get daily predictions and alerts'),
              const SizedBox(height: 48),

              PrimaryButton(
                label: 'Get Started',
                onPressed: () => _onContinue(context, ref),
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primary700, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
