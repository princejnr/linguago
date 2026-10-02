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

  void _cleanup() {
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
        if (status == CallStatus.active && !state.isOverlayVisible) {
          await showOverlay();
        } else if (status == CallStatus.ended && state.isOverlayVisible) {
          await closeOverlay();
        }
      }
    });
  }

  void _listenToOverlayReplies() {
    _overlayReplySub?.cancel();
    _overlayReplySub = _repository.overlayReplyStream.listen((phrase) {
      if (kDebugMode) {
        debugPrint('[CallAssistantViewModel] Overlay tapped phrase: $phrase');
      }
      // Audio playback (TTS) hook for milestone 4
    });
  }

  Future<void> refreshPermissions() async {
    final hasPerm = await _repository.checkPermissions();
    // Also re-query individual permissions for granular UI badges
    final phone = await ref.read(callAssistantRepositoryProvider).checkPermissions();
    state = state.copyWith(
      hasPhonePermission: phone,
      hasOverlayPermission: hasPerm,
    );
  }

  Future<void> toggleEnabled(bool enabled) async {
    await _prefs.setCallAssistantEnabled(enabled);
    state = state.copyWith(isEnabled: enabled);

    // If disabled while overlay is active, close it
    if (!enabled && state.isOverlayVisible) {
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
    } else if (status == CallStatus.ended) {
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
