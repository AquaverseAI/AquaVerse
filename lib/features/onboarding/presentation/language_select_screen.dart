import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/onboarding_flag_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/onboarding_scaffold.dart';
import '../../../shared/widgets/speaker_button.dart';
import 'controllers/onboarding_controller.dart';

/// Language selection screen supporting English & Tamil in a clean side-by-side card layout.
class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  static const List<Map<String, String>> _languages = [
    {
      'code': 'en',
      'nativeName': 'English',
      'englishName': 'English',
      'flagCode': 'EN',
    },
    {
      'code': 'ta',
      'nativeName': 'தமிழ்',
      'englishName': 'Tamil',
      'flagCode': 'TA',
    },
  ];

  void _onContinue(BuildContext context) async {
    final store = await OnboardingFlagStore.create();
    await store.setHasOnboarded(true);
    if (context.mounted) {
      context.push('/onboarding/mobile');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final selectedLangCode = state.selectedLanguage;

    return OnboardingScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageMargin),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Top Icon Badge (Clean vector translate icon in sea-green circle)
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.langCtaGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.langAccentPrimary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Title & Subtitle + Speaker Accessibility Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: const [
                        Text(
                          'Select Language',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.langTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Choose your preferred language to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.langTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SpeakerButton(
                    textToSpeak: 'Select Language. Choose your preferred language to continue.',
                  ),
                ],
              ),

              const Spacer(),

              // ── Side-by-Side Language Cards (English & Tamil)
              Row(
                children: _languages.map((lang) {
                  final code = lang['code']!;
                  final isSelected = selectedLangCode == code;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: InkWell(
                        onTap: () => controller.selectLanguage(code),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.langBgSelected : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.langBorderSelected : AppColors.border,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.langBorderSelected.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Flag / Code Badge
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.langAccentPrimary.withValues(alpha: 0.15)
                                      : AppColors.langSearchBg,
                                ),
                                child: Center(
                                  child: Text(
                                    lang['flagCode']!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? AppColors.langAccentPrimary
                                          : AppColors.langFlagCodeText,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Native Language Name
                              Text(
                                lang['nativeName']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.langAccentPrimary
                                      : AppColors.langTextPrimary,
                                ),
                              ),

                              const SizedBox(height: 4),

                              // English Name
                              Text(
                                lang['englishName']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.langAccentPrimary.withValues(alpha: 0.8)
                                      : AppColors.langTextSecondary,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Selection Indicator (Radio / Checkmark disc)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppColors.langCheckIcon : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? AppColors.langCheckIcon : AppColors.borderStrong,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              // ── Sticky Bottom CTA Button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.langCtaGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.langAccentPrimary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _onContinue(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.langTextOnAccent,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppColors.langTextOnAccent,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
