import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/aurora_ai_orb.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/speaker_button.dart';

enum AskState { idle, listening, thinking, response }

final askStateProvider = StateProvider<AskState>((ref) => AskState.idle);
final recognizedTextProvider = StateProvider<String?>((ref) => null);
final answerTextProvider = StateProvider<String?>((ref) => null);

class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onMicTap() async {
    final currentState = ref.read(askStateProvider);
    final currentLang = ref.read(appLanguageProvider);

    if (currentState == AskState.idle || currentState == AskState.response) {
      ref.read(askStateProvider.notifier).state = AskState.listening;
      _waveController.repeat();
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final sampleQuestion = currentLang == 'ta'
          ? 'இன்று மீன்களுக்கு எவ்வளவு தீவனம் போட வேண்டும்?'
          : 'How much feed should I give today?';

      ref.read(recognizedTextProvider.notifier).state = sampleQuestion;
      ref.read(askStateProvider.notifier).state = AskState.thinking;
      _waveController.stop();
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      final sampleAnswer = currentLang == 'ta'
          ? 'குளம் TN-01-001 தகவல்களின்படி (நாள் 45, பங்கீசியஸ் மீன்):\n\n'
            '• இன்றைய மொத்த தீவன அளவு: 18 கிலோ (3 வேளைகளாகப் பிரிக்கவும்)\n'
            '• காலை 7 மணி: 6 கிலோ\n'
            '• மதியம் 1 மணி: 6 கிலோ\n'
            '• மாலை 7 மணி: 6 கிலோ\n\n'
            'குறிப்பு: இன்று இரவு ஆக்சிஜன் அளவு குறைய வாய்ப்புள்ளது. ஆக்சிஜன் 4.0 mg/L கீழே குறைந்தால் மாலை தீவனத்தை 20% குறைக்கவும். '
            'இது AI மதிப்பீடு — முக்கிய முடிவுகளுக்கு உங்கள் விரிவாக்க அலுவலரைத் தொடர்பு கொள்ளவும்.'
          : 'Based on today\'s data for pond TN-01-001 (Day 45, Pangasius):\n\n'
            '• Feed 18 kg, split into 3 equal portions\n'
            '• Morning 7 AM: 6 kg\n'
            '• Afternoon 1 PM: 6 kg\n'
            '• Evening 7 PM: 6 kg\n\n'
            'Note: DO is forecast to drop tonight. Reduce evening feed by 20% if DO falls below 4.0 mg/L. '
            'This is an AI estimate — confirm with your extension officer if in doubt.';

      ref.read(answerTextProvider.notifier).state = sampleAnswer;
      ref.read(askStateProvider.notifier).state = AskState.response;
    } else {
      ref.read(askStateProvider.notifier).state = AskState.idle;
      ref.read(recognizedTextProvider.notifier).state = null;
      ref.read(answerTextProvider.notifier).state = null;
      _waveController.stop();
    }
  }

  Future<void> _onTextSubmit([String? customText]) async {
    final text = (customText ?? _textController.text).trim();
    if (text.isEmpty) return;

    final currentLang = ref.read(appLanguageProvider);
    ref.read(recognizedTextProvider.notifier).state = text;
    ref.read(askStateProvider.notifier).state = AskState.thinking;
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final answer = currentLang == 'ta'
        ? 'உங்கள் கேள்வி: "$text"\n\n'
          'குளம் TN-01-001 நேரலைத் தரவுகள் பரிசீலிக்கப்பட்டது…\n'
          '• கரைந்த ஆக்சிஜன் (DO): 5.2 mg/L — பாதுகாப்பான அளவில் உள்ளது.\n'
          '• pH நிலை: 7.8 — உகந்த நிலை.\n'
          '• இன்றைய தீவனப் பரிந்துரை: 18 கிலோ/நாள்.\n\n'
          'குறிப்பு: இது AI பரிந்துரை — முக்கிய பண்ணை முடிவுகளுக்கு உங்கள் மாவட்ட விரிவாக்க அலுவலரைத் தொடர்பு கொள்ளவும்.'
        : 'Based on your question: "$text"\n\n'
          'Reviewing pond TN-01-001 data… '
          'Dissolved oxygen is currently 5.2 mg/L — within safe range. '
          'Feed recommendation: 18 kg/day. '
          'This is an AI estimate — please confirm with your extension officer for important decisions.';

    ref.read(answerTextProvider.notifier).state = answer;
    ref.read(askStateProvider.notifier).state = AskState.response;
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final askState = ref.watch(askStateProvider);
    final recognized = ref.watch(recognizedTextProvider);
    final answer = ref.watch(answerTextProvider);
    final currentLang = ref.watch(appLanguageProvider);

    final recentQuestionsList = currentLang == 'ta'
        ? [
            'இன்று மீன்களுக்கு எவ்வளவு தீவனம் போட வேண்டும்?',
            'ஆக்சிஜன் 4 mg/L கீழே குறைந்தால் என்ன செய்ய வேண்டும்?',
            'மழைக்காலத்தில் pH சமநிலை பராமரிப்பது எப்படி?',
            'அமோனியா அளவை எவ்வாறு கட்டுப்படுத்துவது?',
          ]
        : DemoDataService.recentQuestions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/today')),
        title: Text(
          AppTranslations.getText('askTitle', currentLang),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(
            message: AppTranslations.getText('offlineNotice', currentLang),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.pageMargin),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // ── Pixel-Perfect Aurora AI Voice Assistant Orb ─────────────
                  _buildAuroraMicSection(askState, currentLang),
                  const SizedBox(height: 24),

                  // ── Recognized speech from user ─────────────────────────────
                  if (recognized != null) ...[
                    AppCard(
                      type: CardType.info,
                      child: Row(
                        children: [
                          const Icon(Icons.record_voice_over_rounded, color: AppColors.primary700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(recognized, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Thinking state indicator ────────────────────────────────
                  if (askState == AskState.thinking) ...[
                    const _ThinkingIndicator(),
                    const SizedBox(height: 12),
                  ],

                  // ── AI Answer Response Card ─────────────────────────────────
                  if (answer != null) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.assistant_rounded, color: AppColors.primary700, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppTranslations.getText('aquaAnswer', currentLang),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SpeakerButton(textToSpeak: answer),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            answer,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.6),
                          ),
                          const SizedBox(height: 12),
                          _buildSymptomTriageCard(currentLang),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.critical,
                                side: const BorderSide(color: AppColors.criticalBorder),
                                backgroundColor: AppColors.criticalSurface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.phone_rounded, size: 16),
                              label: Text(
                                AppTranslations.getText('callOfficer', currentLang),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── User Question Text Input ───────────────────────────────
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: AppTranslations.getText('typeQuestion', currentLang),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _onTextSubmit(),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _onTextSubmit(),
                          icon: const Icon(Icons.send_rounded, color: AppColors.primary500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Recent Questions Header & Chips ───────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppTranslations.getText('recentQuestions', currentLang),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...recentQuestionsList.map((q) => _RecentQuestion(
                        text: q,
                        onTap: () => _onTextSubmit(q),
                      )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: FarmerBottomNavBar(
        currentIndex: 2,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/today');
              break;
            case 1:
              context.go('/log');
              break;
            case 2:
              break;
            case 3:
              context.go('/alerts');
              break;
            case 4:
              context.go('/crop');
              break;
          }
        },
      ),
    );
  }

  Widget _buildAuroraMicSection(AskState askState, String currentLang) {
    String stateText;
    switch (askState) {
      case AskState.listening:
        stateText = AppTranslations.getText('listeningText', currentLang);
        break;
      case AskState.thinking:
        stateText = AppTranslations.getText('thinkingText', currentLang);
        break;
      case AskState.response:
        stateText = AppTranslations.getText('responsePrompt', currentLang);
        break;
      default:
        stateText = AppTranslations.getText('tapToAsk', currentLang);
    }

    return Column(
      children: [
        Text(
          AppTranslations.getText('aquaAiAssistant', currentLang),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            color: AppColors.langAccentPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Pixel-Perfect Aurora AI Morphing Orb Centerpiece
        AuroraAiOrb(
          size: 160.0,
          isListening: askState == AskState.listening,
          isThinking: askState == AskState.thinking,
          onTap: _onMicTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.9),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowTier2,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              askState == AskState.listening
                  ? Icons.stop_rounded
                  : Icons.mic_rounded,
              color: askState == AskState.listening
                  ? AppColors.riskHigh
                  : AppColors.langAccentPrimary,
              size: 28,
            ),
          ),
        ),

        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            stateText,
            key: ValueKey(stateText),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Dynamic Waveform indicator when listening
        if (askState == AskState.listening) ...[
          const SizedBox(height: 14),
          _WaveformWidget(controller: _waveController),
        ],
      ],
    );
  }

  Widget _buildSymptomTriageCard(String currentLang) {
    final triageText = currentLang == 'ta'
        ? 'வெள்ளைப்புள்ளி நோய் அறிகுறி கண்டறியப்பட்டது — குளத்தைப் பிரிக்கவும், நீர் மாற்றத்தை உடனடியாக நிறுத்தவும்.'
        : 'Consistent with white spot — isolate pond, stop water exchange, confirm with officer.';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              triageText,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator();
  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final t = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.3 + 0.7 * math.sin(t * math.pi)),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

class _WaveformWidget extends StatelessWidget {
  final AnimationController controller;
  const _WaveformWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (i) {
          final phase = controller.value + i * 0.12;
          final h = 4.0 + 16.0 * ((math.sin(phase * math.pi * 2) + 1) / 2);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: h,
            decoration: BoxDecoration(
              color: AppColors.langAccentPrimary.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

class _RecentQuestion extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _RecentQuestion({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              ),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
