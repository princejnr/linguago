import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../translation/data/datasources/audio_datasource.dart';
import '../../translation/data/datasources/gemma_datasource.dart';
import '../../translation/data/datasources/tts_datasource.dart';
import '../../translation/data/models/language.dart';
import '../../translation/data/translation_output_parser.dart';
import 'call_assistant_repository.dart';
import 'datasources/overlay_datasource.dart';
import 'datasources/telephony_datasource.dart';
import 'models/call_session.dart';

final callAssistantRepositoryProvider = Provider<CallAssistantRepository>((ref) {
  final telephony = ref.watch(telephonyDataSourceProvider);
  final overlay = ref.watch(overlayDataSourceProvider);
  final audio = ref.watch(audioDataSourceProvider);
  final gemma = ref.watch(gemmaDataSourceProvider);
  final tts = ref.watch(ttsDataSourceProvider);
  return CallAssistantRepositoryImpl(
    telephony,
    overlay,
    audio,
    gemma,
    tts,
  );
});

class CallAssistantRepositoryImpl implements CallAssistantRepository {
  CallAssistantRepositoryImpl(
    this._telephony,
    this._overlay,
    this._audio,
    this._gemma,
    this._tts,
  ) {
    _overlayEventsSubscription = _overlay.overlayEvents.listen((event) {
      if (event is Map && event['type'] == 'quick_reply') {
        final phrase = event['phrase'] as String?;
        if (phrase != null && phrase.isNotEmpty) {
          _overlayRepliesController.add(phrase);
        }
      }
    });
  }

  final TelephonyDataSource _telephony;
  final OverlayDataSource _overlay;
  final AudioDataSource _audio;
  final GemmaDataSource _gemma;
  final TtsDataSource _tts;

  final _overlayRepliesController = StreamController<String>.broadcast();
  StreamSubscription<dynamic>? _overlayEventsSubscription;
  bool _isSpeakingTts = false;

  @override
  Stream<CallStatus> get callStateStream => _telephony.callStateStream;

  @override
  Stream<String> get overlayReplyStream => _overlayRepliesController.stream;

  @override
  Future<bool> hasPhonePermission() => _telephony.hasPermission();

  @override
  Future<bool> hasOverlayPermission() => _overlay.hasPermission();

  @override
  Future<bool> hasMicPermission() => _audio.hasPermission();

  @override
  Future<bool> checkPermissions() async {
    final phone = await hasPhonePermission();
    final overlay = await hasOverlayPermission();
    final mic = await hasMicPermission();
    return phone && overlay && mic;
  }

  @override
  Future<bool> requestPhonePermission() => _telephony.requestPermission();

  @override
  Future<bool> requestOverlayPermission() => _overlay.requestPermission();

  @override
  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Future<void> showOverlay() => _overlay.showOverlay();

  @override
  Future<void> closeOverlay() => _overlay.closeOverlay();

  @override
  Future<void> updateOverlaySubtitles({
    required String transcription,
    required String translation,
  }) {
    return _overlay.sendToOverlay({
      'type': 'subtitle',
      'transcription': transcription,
      'translation': translation,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> speakFrenchReply(String phrase) async {
    _isSpeakingTts = true;
    try {
      await _tts.speak(phrase, SupportedLanguages.french);
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _isSpeakingTts = false;
    }
  }

  @override
  Future<({String transcription, String translation})?> processSpeechSnippet({
    Duration duration = const Duration(seconds: 4),
  }) async {
    if (_isSpeakingTts) return null;
    if (!_gemma.isLoaded) return null;

    try {
      await _audio.startRecording();
      await Future<void>.delayed(duration);
      if (_isSpeakingTts) {
        await _audio.cancelRecording();
        return null;
      }

      final audioBytes = await _audio.stopRecording();
      if (audioBytes.lengthInBytes < 1000) return null;

      final raw = await _gemma.translateAudio(
        audioBytes: audioBytes,
        source: SupportedLanguages.french,
        target: SupportedLanguages.english,
      );

      final parsed = TranslationOutputParser.parse(
        raw,
        sourceName: SupportedLanguages.french.displayName,
        targetName: SupportedLanguages.english.displayName,
      );

      var translation = parsed.translation;
      if (translation == null || translation.isEmpty) {
        final retry = await _gemma.translateText(
          text: parsed.transcription,
          source: SupportedLanguages.french,
          target: SupportedLanguages.english,
        );
        translation = TranslationOutputParser.parseTranslationOnly(
          retry,
          targetName: SupportedLanguages.english.displayName,
        );
      }

      return (
        transcription: parsed.transcription,
        translation: translation,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CallAssistantRepositoryImpl] processSpeechSnippet: $e');
      }
      return null;
    }
  }

  void dispose() {
    _overlayEventsSubscription?.cancel();
    _overlayRepliesController.close();
  }
}
