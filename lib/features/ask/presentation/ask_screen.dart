import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/speaker_button.dart';

enum AskState { idle, listening, thinking, response }

final askStateProvider = StateProvider<AskState>((ref) => AskState.idle);
final recognizedTextProvider = StateProvider<String?>((ref) => null);
final answerTextProvider = StateProvider<String?>((ref) => null);
final textInputProvider = StateProvider<String>((ref) => '');

class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onMicTap() async {
    final currentState = ref.read(askStateProvider);
    if (currentState == AskState.idle) {
      ref.read(askStateProvider.notifier).state = AskState.listening;
      _waveController.repeat();
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      ref.read(recognizedTextProvider.notifier).state =
          'இன்று மீன்களுக்கு எவ்வளவு தீவனம் போட வேண்டும்?';
      ref.read(askStateProvider.notifier).state = AskState.thinking;
      _waveController.stop();
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      ref.read(answerTextProvider.notifier).state =
          'Based on today\'s data for pond TN-01-001 (Day 45, Pangasius):\n\n'
          '• Feed 18 kg, split into 3 equal portions\n'
          '• Morning 7 AM: 6 kg\n'
          '• Afternoon 1 PM: 6 kg\n'
          '• Evening 7 PM: 6 kg\n\n'
          'Note: DO is forecast to drop tonight. Reduce evening feed by 20% if DO falls below 4.0 mg/L. '
          'This is an estimate — confirm with your extension officer if in doubt.';
      ref.read(askStateProvider.notifier).state = AskState.response;
    } else {
      ref.read(askStateProvider.notifier).state = AskState.idle;
      ref.read(recognizedTextProvider.notifier).state = null;
      ref.read(answerTextProvider.notifier).state = null;
      _waveController.stop();
    }
  }

  Future<void> _onTextSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    ref.read(recognizedTextProvider.notifier).state = text;
    ref.read(askStateProvider.notifier).state = AskState.thinking;
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    ref.read(answerTextProvider.notifier).state =
        'Based on your question: "$text"\n\n'
        'Reviewing pond TN-01-001 data… '
        'Dissolved oxygen is currently 5.2 mg/L — within safe range. '
        'Feed recommendation: 18 kg/day. '
        'This is an AI estimate — please confirm with your extension officer for important decisions.';
    ref.read(askStateProvider.notifier).state = AskState.response;
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final askState  = ref.watch(askStateProvider);
    final recognized = ref.watch(recognizedTextProvider);
    final answer     = ref.watch(answerTextProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/today')),
        title: const Text('Ask Aqua', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(
            message: 'Ask Aqua needs internet. Connect to get answers.',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.pageMargin),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // ── Mic button ──────────────────────────────────────────────
                  _buildMicSection(askState),
                  const SizedBox(height: 20),

                  // ── Recognized speech ────────────────────────────────────────
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

                  // ── Thinking indicator ───────────────────────────────────────
                  if (askState == AskState.thinking) ...[
                    const _ThinkingIndicator(),
                    const SizedBox(height: 12),
                  ],

                  // ── Answer card ──────────────────────────────────────────────
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
                              const Text('Aqua\'s Answer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              const Spacer(),
                              SpeakerButton(textToSpeak: answer),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            answer,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.6),
                          ),
                          const SizedBox(height: 12),
                          // Photo symptom triage
                          _buildSymptomTriageCard(),
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
                              label: const Text('Call Officer', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Type instead ──────────────────────────────────────────────
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Type your question…',
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
                          onPressed: _onTextSubmit,
                          icon: const Icon(Icons.send_rounded, color: AppColors.primary500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Recent questions ─────────────────────────────────────────
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Recent Questions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  const SizedBox(height: 10),
                  ...DemoDataService.recentQuestions.map((q) => _RecentQuestion(text: q)),
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
            case 0: context.go('/today'); break;
            case 1: context.go('/log'); break;
            case 2: break;
            case 3: context.go('/alerts'); break;
            case 4: context.go('/crop'); break;
          }
        },
      ),
    );
  }

  Widget _buildMicSection(AskState askState) {
    String stateText;
    switch (askState) {
      case AskState.listening:
        stateText = 'Listening…';
        break;
      case AskState.thinking:
        stateText = 'Thinking…';
        break;
      case AskState.response:
        stateText = 'Tap mic for new question';
        break;
      default:
        stateText = 'Tap the mic and ask your question';
    }

    return Column(
      children: [
        const Text(
          'Ask Aqua',
          style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Mic button
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = askState == AskState.listening
                ? 1.0 + (_pulseController.value * 0.1)
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: _onMicTap,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (askState == AskState.listening)
                      ...List.generate(3, (i) {
                        final phase = (_pulseController.value + i * 0.33) % 1.0;
                        return Container(
                          width: 70 + i * 22 + phase * 10,
                          height: 70 + i * 22 + phase * 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary500.withValues(alpha: (1 - phase) * 0.12),
                          ),
                        );
                      }),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: askState == AskState.listening
                            ? AppColors.critical
                            : AppColors.primary500,
                        boxShadow: [
                          BoxShadow(
                            color: (askState == AskState.listening ? AppColors.critical : AppColors.primary500)
                                .withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        askState == AskState.listening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            stateText,
            key: ValueKey(stateText),
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),

        // Waveform animation when listening
        if (askState == AskState.listening) ...[
          const SizedBox(height: 12),
          _WaveformWidget(controller: _waveController),
        ],
      ],
    );
  }

  Widget _buildSymptomTriageCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Consistent with white spot — isolate pond, stop water exchange, confirm with officer.',
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
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
              color: AppColors.primary500.withValues(alpha: 0.7),
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
  const _RecentQuestion({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
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
