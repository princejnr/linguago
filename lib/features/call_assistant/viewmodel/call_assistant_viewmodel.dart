import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_preferences.dart';
import '../data/call_assistant_repository.dart';
import '../data/call_assistant_repository_impl.dart';
import '../data/models/call_session.dart';
import '../data/models/voip_session.dart';
import 'call_assistant_state.dart';

final callAssistantViewModelProvider =
    NotifierProvider<CallAssistantViewModel, CallAssistantState>(
  CallAssistantViewModel.new,
);

class CallAssistantViewModel extends Notifier<CallAssistantState> {
  StreamSubscription<CallStatus>? _callStateSub;
  StreamSubscription<VoipCallEvent>? _voipSub;
  StreamSubscription<String>? _overlayReplySub;

  CallAssistantRepository get _repository => ref.read(callAssistantRepositoryProvider);
  AppPreferences get _prefs => ref.read(appPreferencesProvider);

  @override
  CallAssistantState build() {
    ref.onDispose(_cleanup);

    final initialEnabled = _prefs.isCallAssistantEnabled;
    final initialWhatsApp = _prefs.isWhatsAppEnabled;
    final initialTeams = _prefs.isTeamsEnabled;

    final initialState = CallAssistantState(
      isEnabled: initialEnabled,
      isWhatsAppEnabled: initialWhatsApp,
      isTeamsEnabled: initialTeams,
    );

    // Check permissions and initialize listeners after initial state
    Future.microtask(() async {
      await refreshPermissions();
      _listenToCallState();
      _listenToVoipState();
      _listenToOverlayReplies();
    });

    return initialState;
  }

  bool _isTranscriptionLoopRunning = false;

  void _cleanup() {
    _stopTranscriptionLoop();
    _callStateSub?.cancel();
    _voipSub?.cancel();
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
          state = state.copyWith(activeApp: VoipApp.cellular);
          if (!state.isOverlayVisible) {
            await showOverlay(app: VoipApp.cellular);
          }
          _startTranscriptionLoop();
        } else if (status == CallStatus.ended || status == CallStatus.idle) {
          if (!state.isVoipActive) {
            _stopTranscriptionLoop();
            if (state.isOverlayVisible) {
              // Give 3 seconds to read final subtitle before closing overlay
              await Future<void>.delayed(const Duration(seconds: 3));
              if (!state.isInAnyCall) {
                await closeOverlay();
              }
            }
          }
        }
      }
    });
  }

  void _listenToVoipState() {
    _voipSub?.cancel();
    _voipSub = _repository.voipStream.listen((event) async {
      if (kDebugMode) {
        debugPrint('[CallAssistantViewModel] VoIP mode changed: isVoip=${event.isVoip}, mode=${event.mode}');
      }

      if (event.isVoip) {
        // Resolve app context: default to WhatsApp if enabled, else Teams
        final targetApp = event.app != VoipApp.generic
            ? event.app
            : (state.isWhatsAppEnabled ? VoipApp.whatsapp : (state.isTeamsEnabled ? VoipApp.teams : VoipApp.generic));

        final isAppEnabled = (targetApp == VoipApp.whatsapp && state.isWhatsAppEnabled) ||
            (targetApp == VoipApp.teams && state.isTeamsEnabled) ||
            (targetApp != VoipApp.whatsapp && targetApp != VoipApp.teams);

        if (state.isEnabled && isAppEnabled && state.areAllPermissionsGranted) {
          state = state.copyWith(
            isVoipActive: true,
            activeApp: targetApp,
          );
          if (!state.isOverlayVisible) {
            await showOverlay(app: targetApp);
          }
          _startTranscriptionLoop();
        }
      } else {
        state = state.copyWith(isVoipActive: false);
        if (state.callStatus != CallStatus.active) {
          _stopTranscriptionLoop();
          if (state.isOverlayVisible) {
            await Future<void>.delayed(const Duration(seconds: 3));
            if (!state.isInAnyCall) {
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

    while (_isTranscriptionLoopRunning && state.isInAnyCall) {
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
          app: state.activeApp,
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

  Future<void> toggleWhatsAppEnabled(bool enabled) async {
    await _prefs.setWhatsAppEnabled(enabled);
    state = state.copyWith(isWhatsAppEnabled: enabled);
  }

  Future<void> toggleTeamsEnabled(bool enabled) async {
    await _prefs.setTeamsEnabled(enabled);
    state = state.copyWith(isTeamsEnabled: enabled);
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

  Future<void> showOverlay({VoipApp? app}) async {
    final chosenApp = app ?? state.activeApp;
    await _repository.showOverlay(app: chosenApp);
    state = state.copyWith(isOverlayVisible: true, activeApp: chosenApp);
  }

  Future<void> closeOverlay() async {
    await _repository.closeOverlay();
    state = state.copyWith(isOverlayVisible: false);
  }

  /// Simulate a phone call state for local testing / emulator verification.
  Future<void> simulateCallStatus(CallStatus status) async {
    state = state.copyWith(callStatus: status, activeApp: VoipApp.cellular);
    if (status == CallStatus.active) {
      await showOverlay(app: VoipApp.cellular);
      _startTranscriptionLoop();
    } else if (status == CallStatus.ended) {
      _stopTranscriptionLoop();
      await closeOverlay();
    }
  }

  /// Simulate a VoIP call state (WhatsApp, Teams, etc.) for testing.
  Future<void> simulateVoipCall({required VoipApp app, required bool active}) async {
    state = state.copyWith(
      isVoipActive: active,
      activeApp: active ? app : state.activeApp,
    );
    if (active) {
      await showOverlay(app: app);
      _startTranscriptionLoop();
    } else {
      if (state.callStatus != CallStatus.active) {
        _stopTranscriptionLoop();
        await closeOverlay();
      }
    }
  }

  /// Send sample subtitle to test the overlay rendering.
  Future<void> sendSampleSubtitle({
    required String transcription,
    required String translation,
    VoipApp? app,
  }) async {
    final chosenApp = app ?? state.activeApp;
    state = state.copyWith(
      currentTranscription: transcription,
      currentTranslation: translation,
      activeApp: chosenApp,
    );
    await _repository.updateOverlaySubtitles(
      transcription: transcription,
      translation: translation,
      app: chosenApp,
    );
  }
}
