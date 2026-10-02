import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_preferences.dart';
import '../data/call_assistant_repository.dart';
import '../data/call_assistant_repository_impl.dart';
import '../data/models/call_session.dart';
import 'call_assistant_state.dart';

final callAssistantViewModelProvider =
    NotifierProvider<CallAssistantViewModel, CallAssistantState>(
  CallAssistantViewModel.new,
);

class CallAssistantViewModel extends Notifier<CallAssistantState> {
  StreamSubscription<CallStatus>? _callStateSub;
  StreamSubscription<String>? _overlayReplySub;

  CallAssistantRepository get _repository => ref.read(callAssistantRepositoryProvider);
  AppPreferences get _prefs => ref.read(appPreferencesProvider);

  @override
  CallAssistantState build() {
    ref.onDispose(_cleanup);

    final initialEnabled = _prefs.isCallAssistantEnabled;
    final initialState = CallAssistantState(isEnabled: initialEnabled);

    // Check permissions and initialize listeners after initial state
    Future.microtask(() async {
      await refreshPermissions();
      _listenToCallState();
      _listenToOverlayReplies();
    });

    return initialState;
  }

  bool _isTranscriptionLoopRunning = false;

  void _cleanup() {
    _stopTranscriptionLoop();
    _callStateSub?.cancel();
    _overlayReplySub?.cancel();
  }

  void _listenToCallState() {
    _callStateSub?.cancel();
    _callStateSub = _repository.callStateStream.listen((status) async {
      state = state.copyWith(callStatus: status);

      if (kDebugMode) {
        debugPrint('[CallAssistantViewModel] Call status changed: $status');
      }

      if (state.isEnabled && state.areAllPermissionsGranted) {
        if (status == CallStatus.active) {
          if (!state.isOverlayVisible) {
            await showOverlay();
          }
          _startTranscriptionLoop();
        } else if (status == CallStatus.ended || status == CallStatus.idle) {
          _stopTranscriptionLoop();
          if (state.isOverlayVisible) {
            // Give 3 seconds to read final subtitle before closing overlay
            await Future<void>.delayed(const Duration(seconds: 3));
            if (state.callStatus == CallStatus.ended || state.callStatus == CallStatus.idle) {
              await closeOverlay();
            }
          }
        }
      }
    });
  }

  void _listenToOverlayReplies() {
    _overlayReplySub?.cancel();
    _overlayReplySub = _repository.overlayReplyStream.listen((phrase) async {
      if (kDebugMode) {
        debugPrint('[CallAssistantViewModel] Overlay tapped phrase: $phrase');
      }
      state = state.copyWith(isSpeakingTts: true);
      try {
        await _repository.speakFrenchReply(phrase);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[CallAssistantViewModel] Error speaking TTS: $e');
        }
      } finally {
        state = state.copyWith(isSpeakingTts: false);
      }
    });
  }

  Future<void> _startTranscriptionLoop() async {
    if (_isTranscriptionLoopRunning) return;
    _isTranscriptionLoopRunning = true;
    state = state.copyWith(isListening: true);

    while (_isTranscriptionLoopRunning && state.callStatus == CallStatus.active) {
      final snippet = await _repository.processSpeechSnippet();
      if (!_isTranscriptionLoopRunning) break;
      if (snippet != null && snippet.transcription.trim().isNotEmpty) {
        state = state.copyWith(
          currentTranscription: snippet.transcription,
          currentTranslation: snippet.translation,
        );
        await _repository.updateOverlaySubtitles(
          transcription: snippet.transcription,
          translation: snippet.translation,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    _isTranscriptionLoopRunning = false;
    state = state.copyWith(isListening: false);
  }

  void _stopTranscriptionLoop() {
    _isTranscriptionLoopRunning = false;
    state = state.copyWith(isListening: false);
  }

  Future<void> refreshPermissions() async {
    final phone = await _repository.hasPhonePermission();
    final overlay = await _repository.hasOverlayPermission();
    final mic = await _repository.hasMicPermission();
    state = state.copyWith(
      hasPhonePermission: phone,
      hasOverlayPermission: overlay,
      hasMicPermission: mic,
    );
  }

  Future<void> toggleEnabled(bool enabled) async {
    await _prefs.setCallAssistantEnabled(enabled);
    state = state.copyWith(isEnabled: enabled);

    // If disabled while overlay is active, close it
    if (!enabled && state.isOverlayVisible) {
      _stopTranscriptionLoop();
      await closeOverlay();
    }
  }

  Future<void> requestPhonePermission() async {
    final granted = await _repository.requestPhonePermission();
    state = state.copyWith(hasPhonePermission: granted);
  }

  Future<void> requestOverlayPermission() async {
    final granted = await _repository.requestOverlayPermission();
    state = state.copyWith(hasOverlayPermission: granted);
  }

  Future<void> requestMicPermission() async {
    final granted = await _repository.requestMicPermission();
    state = state.copyWith(hasMicPermission: granted);
  }

  Future<void> showOverlay() async {
    await _repository.showOverlay();
    state = state.copyWith(isOverlayVisible: true);
  }

  Future<void> closeOverlay() async {
    await _repository.closeOverlay();
    state = state.copyWith(isOverlayVisible: false);
  }

  /// Simulate a phone call state for local testing / emulator verification.
  Future<void> simulateCallStatus(CallStatus status) async {
    state = state.copyWith(callStatus: status);
    if (status == CallStatus.active) {
      await showOverlay();
      _startTranscriptionLoop();
    } else if (status == CallStatus.ended) {
      _stopTranscriptionLoop();
      await closeOverlay();
    }
  }

  /// Send sample subtitle to test the overlay rendering.
  Future<void> sendSampleSubtitle({
    required String transcription,
    required String translation,
  }) async {
    state = state.copyWith(
      currentTranscription: transcription,
      currentTranslation: translation,
    );
    await _repository.updateOverlaySubtitles(
      transcription: transcription,
      translation: translation,
    );
  }
}
