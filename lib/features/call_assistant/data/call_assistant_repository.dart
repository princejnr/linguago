import 'models/call_session.dart';
import 'models/voip_session.dart';

abstract interface class CallAssistantRepository {
  /// Stream emitting real-time telephony call status changes.
  Stream<CallStatus> get callStateStream;

  /// Stream emitting real-time VoIP audio mode status changes.
  Stream<VoipCallEvent> get voipStream;

  /// Stream of quick-reply phrases tapped by the user in the floating overlay.
  Stream<String> get overlayReplyStream;

  /// Check whether phone state permission is granted.
  Future<bool> hasPhonePermission();

  /// Check whether display-over-other-apps permission is granted.
  Future<bool> hasOverlayPermission();

  /// Check whether microphone recording permission is granted.
  Future<bool> hasMicPermission();

  /// Check whether all required permissions are granted.
  Future<bool> checkPermissions();

  /// Request phone state permission.
  Future<bool> requestPhonePermission();

  /// Request display-over-other-apps permission.
  Future<bool> requestOverlayPermission();

  /// Request microphone permission.
  Future<bool> requestMicPermission();

  /// Display the floating call assistant overlay for a specific call type.
  Future<void> showOverlay({VoipApp app = VoipApp.cellular});

  /// Close the floating overlay.
  Future<void> closeOverlay();

  /// Send live transcription and translation subtitles to the overlay.
  Future<void> updateOverlaySubtitles({
    required String transcription,
    required String translation,
    VoipApp app = VoipApp.cellular,
  });

  /// Check if VoIP audio mode is currently active.
  Future<bool> isVoipActive();

  /// Speak a French reply aloud using offline TTS through the speakerphone.
  Future<void> speakFrenchReply(String phrase);

  /// Capture a short snippet of caller audio via speakerphone and translate using Gemma 4 E2B.
  Future<({String transcription, String translation})?> processSpeechSnippet({
    Duration duration = const Duration(seconds: 4),
  });
}
