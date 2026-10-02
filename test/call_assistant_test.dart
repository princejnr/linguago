import 'package:flutter_test/flutter_test.dart';
import 'package:linguago/core/storage/app_preferences.dart';
import 'package:linguago/features/call_assistant/data/models/call_session.dart';
import 'package:linguago/features/call_assistant/data/models/voip_session.dart';
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

  group('VoipSession and VoipCallEvent Model', () {
    test('VoipApp extension returns appropriate display labels and tags', () {
      expect(VoipApp.whatsapp.displayName, 'WhatsApp Call');
      expect(VoipApp.whatsapp.shortTag, '🟢 WHATSAPP');
      expect(VoipApp.teams.displayName, 'Microsoft Teams');
      expect(VoipApp.teams.shortTag, '🟣 TEAMS');
      expect(VoipApp.cellular.displayName, 'Cellular Call');
      expect(VoipApp.cellular.shortTag, '📞 CELLULAR');
    });

    test('VoipCallEvent parses from native platform map correctly', () {
      final map = {
        'isVoip': true,
        'mode': 3, // AudioManager.MODE_IN_COMMUNICATION
        'timestamp': 1690000000000,
      };
      final event = VoipCallEvent.fromMap(map, detectedApp: VoipApp.whatsapp);
      expect(event.isVoip, isTrue);
      expect(event.mode, 3);
      expect(event.timestamp, 1690000000000);
      expect(event.app, VoipApp.whatsapp);
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

    test('isInAnyCall returns true for cellular active or voip active', () {
      const idleState = CallAssistantState();
      expect(idleState.isInAnyCall, isFalse);

      const cellularState = CallAssistantState(callStatus: CallStatus.active);
      expect(cellularState.isInAnyCall, isTrue);

      const voipState = CallAssistantState(isVoipActive: true, activeApp: VoipApp.whatsapp);
      expect(voipState.isInAnyCall, isTrue);
      expect(voipState.activeApp, VoipApp.whatsapp);
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

  group('AppPreferences - Call Assistant & VoIP', () {
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

    test('persists and retrieves WhatsApp and Teams call assistant toggles', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appPrefs = AppPreferences(prefs);

      // Defaults to true
      expect(appPrefs.isWhatsAppEnabled, isTrue);
      expect(appPrefs.isTeamsEnabled, isTrue);

      await appPrefs.setWhatsAppEnabled(false);
      expect(appPrefs.isWhatsAppEnabled, isFalse);

      await appPrefs.setTeamsEnabled(false);
      expect(appPrefs.isTeamsEnabled, isFalse);

      await appPrefs.setWhatsAppEnabled(true);
      expect(appPrefs.isWhatsAppEnabled, isTrue);
    });
  });
}
