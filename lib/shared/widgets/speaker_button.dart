import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// SpeakerButton — text read-aloud component.
///
/// HONESTY CONTRACT (Phase A fix):
/// The Bhashini TTS audio binary endpoint is not yet confirmed in the
/// OpenAPI contract. POST /v1/translate returns translated text only —
/// NOT audio bytes.
///
/// Current behavior:
///   - Renders a muted/unavailable speaker icon.
///   - On tap, shows the source text in a SnackBar (text fallback).
///   - Does NOT show a playing animation or pretend audio is active.
///
/// When real TTS audio is confirmed (backend delivers audio bytes):
///   - Set [_ttsAudioAvailable] to true.
///   - Re-enable _ActiveSpeakerButton.
///
/// BACKEND GAP: POST /v1/tts → audio binary — MISSING from confirmed contract.

// Set to true only when POST /v1/tts returning audio bytes is confirmed.
const bool _ttsAudioAvailable = false;

class SpeakerButton extends ConsumerWidget {
  final String textToSpeak;
  final double size;
  final Color? color;

  const SpeakerButton({
    super.key,
    required this.textToSpeak,
    this.size = AppIconSize.lg,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_ttsAudioAvailable) {
      return _UnavailableSpeakerButton(
        size: size,
        color: color,
        textToSpeak: textToSpeak,
      );
    }
    // When TTS audio becomes available, replace with _ActiveSpeakerButton here.
    return _UnavailableSpeakerButton(
      size: size,
      color: color,
      textToSpeak: textToSpeak,
    );
  }
}

// ── Unavailable State ────────────────────────────────────────────────────────

class _UnavailableSpeakerButton extends StatelessWidget {
  final double size;
  final Color? color;
  final String textToSpeak;

  const _UnavailableSpeakerButton({
    required this.size,
    required this.textToSpeak,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.textDisabled;

    return Semantics(
      button: true,
      label: 'Text-to-speech unavailable',
      hint: 'Audio reading is not yet supported. Tap to view text.',
      child: Tooltip(
        message: 'Audio not available — tap to view text',
        preferBelow: false,
        child: InkWell(
          onTap: () => _showTextFallback(context),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.border.withValues(alpha: 0.3),
            ),
            child: Icon(
              Icons.volume_off_rounded,
              size: size,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  void _showTextFallback(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audio not available',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              textToSpeak,
              style: const TextStyle(fontSize: 13),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}
