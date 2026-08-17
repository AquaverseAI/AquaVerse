import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/onboarding_flag_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/onboarding_scaffold.dart';
import '../../../shared/widgets/rotating_globe_icon.dart';
import '../../../shared/widgets/speaker_button.dart';
import 'controllers/onboarding_controller.dart';

/// Rebuilt LanguageSelectScreen adhering to PRD-AV light theme design tokens.
/// Features:
/// - Sea-green/teal light palette (AppColors.lang* tokens).
/// - Top 64dp circular gradient icon badge.
/// - Title & Subtitle block + SpeakerButton audio prompt.
/// - Rounded Search Bar with live language filtering.
/// - Scrollable language tiles (~64dp height) with country code badges & checkmarks.
/// - Sticky bottom gradient CTA button ("Continue" / "Next").
class LanguageSelectScreen extends ConsumerStatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  ConsumerState<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends ConsumerState<LanguageSelectScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<Map<String, String>> _allLanguages = [
    {'code': 'ta', 'nativeName': 'தமிழ்', 'englishName': 'Tamil', 'flagCode': 'TA'},
    {'code': 'en', 'nativeName': 'English', 'englishName': 'English', 'flagCode': 'EN'},
    {'code': 'hi', 'nativeName': 'हिंदी', 'englishName': 'Hindi', 'flagCode': 'HI'},
    {'code': 'te', 'nativeName': 'తెలుగు', 'englishName': 'Telugu', 'flagCode': 'TE'},
    {'code': 'kn', 'nativeName': 'கன்னட', 'englishName': 'Kannada', 'flagCode': 'KN'},
    {'code': 'ml', 'nativeName': 'മലയാളം', 'englishName': 'Malayalam', 'flagCode': 'ML'},
    {'code': 'bn', 'nativeName': 'বাংলা', 'englishName': 'Bengali', 'flagCode': 'BN'},
    {'code': 'gu', 'nativeName': 'ગુજરાતી', 'englishName': 'Gujarati', 'flagCode': 'GU'},
    {'code': 'mr', 'nativeName': 'मराठी', 'englishName': 'Marathi', 'flagCode': 'MR'},
    {'code': 'or', 'nativeName': 'ଓଡ଼ିଆ', 'englishName': 'Odia', 'flagCode': 'OR'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredLanguages {
    if (_searchQuery.trim().isEmpty) {
      return _allLanguages;
    }
    final q = _searchQuery.trim().toLowerCase();
    return _allLanguages.where((lang) {
      final native = lang['nativeName']!.toLowerCase();
      final english = lang['englishName']!.toLowerCase();
      final code = lang['code']!.toLowerCase();
      return native.contains(q) || english.contains(q) || code.contains(q);
    }).toList();
  }

  void _onContinue() async {
    final store = await OnboardingFlagStore.create();
    await store.setHasOnboarded(true);
    if (mounted) {
      context.push('/onboarding/mobile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final selectedLangCode = state.selectedLanguage;
    final filteredList = _filteredLanguages;

    return OnboardingScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageMargin),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── 2.2 Icon Badge (Centered 64dp realistic 3D rotating globe icon)
              const Center(
                child: RotatingGlobeIcon(size: 64),
              ),

              const SizedBox(height: 16),

              // ── 2.3 Title + Subtitle Block + Speaker Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Select Language',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.langTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
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

              const SizedBox(height: 20),

              // ── 2.4 Search Field (40% Glassmorphism)
              GlassContainer(
                height: 48,
                borderRadius: 12,
                opacity: 0.40,
                fillColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.langSearchPlaceholder,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.langTextPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search Languages',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.langSearchPlaceholder,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.langSearchPlaceholder,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 2.5 Section Label
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ALL LANGUAGES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.langTextSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── 2.6 Language List (40% Glassmorphism Tiles)
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 40,
                              color: AppColors.langSearchPlaceholder,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No languages found',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.langTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final lang = filteredList[index];
                          final code = lang['code']!;
                          final isSelected = selectedLangCode == code;

                          return InkWell(
                            onTap: () => controller.selectLanguage(code),
                            borderRadius: BorderRadius.circular(12),
                            child: GlassContainer(
                              height: 64,
                              borderRadius: 12,
                              opacity: isSelected ? 0.55 : 0.40,
                              fillColor: isSelected ? AppColors.langBgSelected : Colors.white,
                              border: Border.all(
                                color: isSelected ? AppColors.langBorderSelected : Colors.white.withValues(alpha: 0.60),
                                width: isSelected ? 1.8 : 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  // Two-Letter Code Badge
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.langAccentPrimary.withValues(alpha: 0.12)
                                          : AppColors.langSearchBg,
                                    ),
                                    child: Center(
                                      child: Text(
                                        lang['flagCode']!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? AppColors.langAccentPrimary
                                              : AppColors.langFlagCodeText,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  // Language Names (Native + English)
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang['nativeName']!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            color: isSelected
                                                ? AppColors.langAccentPrimary
                                                : AppColors.langTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          lang['englishName']!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: isSelected
                                                ? AppColors.langAccentPrimary.withValues(alpha: 0.8)
                                                : AppColors.langTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Trailing Checkmark Icon when Selected
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.langCheckIcon,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // ── 2.7 Sticky CTA Button
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
                  onPressed: _onContinue,
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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
