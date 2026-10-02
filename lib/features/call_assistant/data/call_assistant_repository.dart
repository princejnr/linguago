import 'models/call_session.dart';

abstract interface class CallAssistantRepository {
  /// Stream emitting real-time telephony call status changes.
  Stream<CallStatus> get callStateStream;

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

  /// Display the floating call assistant overlay.
  Future<void> showOverlay();

  /// Close the floating overlay.
  Future<void> closeOverlay();

  /// Send live transcription and translation subtitles to the overlay.
  Future<void> updateOverlaySubtitles({
    required String transcription,
    required String translation,
  });

  /// Speak a French reply aloud using offline TTS through the speakerphone.
  Future<void> speakFrenchReply(String phrase);

  /// Capture a short snippet of caller audio via speakerphone and translate using Gemma 4 E2B.
  Future<({String transcription, String translation})?> processSpeechSnippet({
    Duration duration = const Duration(seconds: 4),
  });
}
