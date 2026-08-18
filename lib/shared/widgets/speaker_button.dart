import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_translations.dart';
import '../../core/services/bhashini_tts_service.dart';
import '../../core/theme/app_colors.dart';

/// SpeakerButton Component with Bhashini Read-Aloud Integration.
/// Every action/advisory text includes a SpeakerButton that reads text aloud
/// in the farmer's preferred language (Tamil default / English switchable).
class SpeakerButton extends ConsumerStatefulWidget {
  final String textToSpeak;
  final double size;
  final Color? color;
  final VoidCallback? onSpeakPressed;

  const SpeakerButton({
    super.key,
    required this.textToSpeak,
    this.size = 24.0,
    this.color,
    this.onSpeakPressed,
  });

  @override
  ConsumerState<SpeakerButton> createState() => _SpeakerButtonState();
}

class _SpeakerButtonState extends ConsumerState<SpeakerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  Timer? _autoStopTimer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onSpeakPressed != null) {
      widget.onSpeakPressed!();
    }

    _autoStopTimer?.cancel();

    final currentLang = ref.read(appLanguageProvider);
    final ttsService = ref.read(bhashiniTtsServiceProvider);

    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _waveController.repeat(reverse: true);

      // Trigger Bhashini Audio Read Aloud
      ttsService.speakText(text: widget.textToSpeak, langCode: currentLang);

      final toastMsg = currentLang == 'ta'
          ? '🔊 பாஷினி குரல் வழிகாட்டி: உரக்கப் படிக்கிறது…'
          : '🔊 Bhashini Voice Assistant: Reading aloud…';

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(toastMsg),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _autoStopTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
          _waveController.stop();
          _waveController.reset();
        }
      });
    } else {
      ttsService.stop();
      _waveController.stop();
      _waveController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? AppColors.seaGreen;

    return Semantics(
      label: 'Read text aloud: ${widget.textToSpeak}',
      button: true,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isPlaying
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPlaying ? 1.0 + (_waveController.value * 0.15) : 1.0,
                child: Icon(
                  _isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                  size: widget.size,
                  color: _isPlaying ? AppColors.brightMint : activeColor,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
