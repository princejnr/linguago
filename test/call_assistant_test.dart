import 'package:flutter_test/flutter_test.dart';
import 'package:linguago/core/storage/app_preferences.dart';
import 'package:linguago/features/call_assistant/data/models/call_session.dart';
import 'package:linguago/features/call_assistant/viewmodel/call_assistant_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CallSession Model', () {
    test('initializes with default status and checks isInCall correctly', () {
      const session = CallSession(status: CallStatus.idle);
      expect(session.status, CallStatus.idle);
      expect(session.isInCall, isFalse);

      final activeSession = session.copyWith(
        status: CallStatus.active,
        lastTranscription: 'Allô patron',
        lastTranslation: 'Hello boss',
      );
      expect(activeSession.isInCall, isTrue);
      expect(activeSession.lastTranscription, 'Allô patron');
      expect(activeSession.lastTranslation, 'Hello boss');
    });
  });

  group('CallAssistantState', () {
    test('areAllPermissionsGranted returns true only when phone, overlay, and mic are granted', () {
      const state1 = CallAssistantState(
        hasPhonePermission: true,
        hasOverlayPermission: false,
        hasMicPermission: true,
      );
      expect(state1.areAllPermissionsGranted, isFalse);

      const state2 = CallAssistantState(
        hasPhonePermission: false,
        hasOverlayPermission: true,
        hasMicPermission: true,
      );
      expect(state2.areAllPermissionsGranted, isFalse);

      const state3 = CallAssistantState(
        hasPhonePermission: true,
        hasOverlayPermission: true,
        hasMicPermission: false,
      );
      expect(state3.areAllPermissionsGranted, isFalse);

      const state4 = CallAssistantState(
        hasPhonePermission: true,
        hasOverlayPermission: true,
        hasMicPermission: true,
      );
      expect(state4.areAllPermissionsGranted, isTrue);
    });

    test('state flags track listening and speaking tts correctly', () {
      const state = CallAssistantState(isListening: true, isSpeakingTts: false);
      expect(state.isListening, isTrue);
      expect(state.isSpeakingTts, isFalse);

      final speaking = state.copyWith(isListening: false, isSpeakingTts: true);
      expect(speaking.isListening, isFalse);
      expect(speaking.isSpeakingTts, isTrue);
    });
  });

  group('AppPreferences - Call Assistant', () {
    test('persists and retrieves call assistant enabled flag', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appPrefs = AppPreferences(prefs);

      expect(appPrefs.isCallAssistantEnabled, isFalse);

      await appPrefs.setCallAssistantEnabled(true);
      expect(appPrefs.isCallAssistantEnabled, isTrue);

      await appPrefs.setCallAssistantEnabled(false);
      expect(appPrefs.isCallAssistantEnabled, isFalse);
    });
  });
}
