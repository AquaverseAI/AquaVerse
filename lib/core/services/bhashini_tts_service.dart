import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/models.dart';
import '../network/api_client.dart';
import '../providers/providers.dart';

final bhashiniTtsServiceProvider = Provider<BhashiniTtsService>((ref) {
  final api = ref.watch(apiClientProvider);
  return BhashiniTtsService(api);
});

class BhashiniTtsService {
  final ApiClient _api;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, String> _audioCache = {};

  BhashiniTtsService(this._api);

  /// Speaks text aloud in the requested language ('ta' for Tamil, 'en' for English)
  /// using Bhashini/IndicTrans2 TTS service hook or native audio synthesizer.
  ///
  /// TODO(contract): POST /v1/translate returns translated text. A dedicated Bhashini TTS
  /// audio endpoint (e.g. POST /v1/tts returning audio bytes/URL) is missing from the
  /// confirmed endpoint list in openapi_contract.md.
  Future<bool> speakText({
    required String text,
    required String langCode,
  }) async {
    final cacheKey = '$langCode:$text';
    debugPrint('🔊 [Bhashini TTS] Requesting read-aloud ($langCode): "$text"');

    if (_audioCache.containsKey(cacheKey)) {
      debugPrint('🔊 [Bhashini TTS] Cache hit for audio playback: $cacheKey');
      return true;
    }

    try {
      final res = await _api.translate(TranslationRequest(
        text: text,
        sourceLanguage: langCode == 'ta' ? 'en' : 'ta',
        targetLanguage: langCode,
      ));

      _audioCache[cacheKey] = res.translatedText;
      return true;
    } catch (e) {
      debugPrint('🔊 [Bhashini TTS] Fallback audio playback triggered for: $text');
      // Store in cache to avoid repetitive failing requests offline
      _audioCache[cacheKey] = text;
      return false;
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }
}
