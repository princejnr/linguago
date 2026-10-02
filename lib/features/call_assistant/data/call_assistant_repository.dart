import 'models/call_session.dart';

abstract interface class CallAssistantRepository {
  /// Stream emitting real-time telephony call status changes.
  Stream<CallStatus> get callStateStream;

  /// Stream of quick-reply phrases tapped by the user in the floating overlay.
  Stream<String> get overlayReplyStream;

  /// Check whether both phone state and overlay permissions are granted.
  Future<bool> checkPermissions();

  /// Request phone state permission.
  Future<bool> requestPhonePermission();

  /// Request display-over-other-apps permission.
  Future<bool> requestOverlayPermission();

  /// Display the floating call assistant overlay.
  Future<void> showOverlay();

  /// Close the floating overlay.
  Future<void> closeOverlay();

  /// Send live transcription and translation subtitles to the overlay.
  Future<void> updateOverlaySubtitles({
    required String transcription,
    required String translation,
  });
}
