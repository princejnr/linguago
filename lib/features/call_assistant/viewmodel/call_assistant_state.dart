import '../data/models/call_session.dart';

class CallAssistantState {
  const CallAssistantState({
    this.isEnabled = false,
    this.hasPhonePermission = false,
    this.hasOverlayPermission = false,
    this.hasMicPermission = false,
    this.callStatus = CallStatus.idle,
    this.isOverlayVisible = false,
    this.isListening = false,
    this.isSpeakingTts = false,
    this.currentTranscription,
    this.currentTranslation,
  });

  final bool isEnabled;
  final bool hasPhonePermission;
  final bool hasOverlayPermission;
  final bool hasMicPermission;
  final CallStatus callStatus;
  final bool isOverlayVisible;
  final bool isListening;
  final bool isSpeakingTts;
  final String? currentTranscription;
  final String? currentTranslation;

  bool get areAllPermissionsGranted =>
      hasPhonePermission && hasOverlayPermission && hasMicPermission;

  CallAssistantState copyWith({
    bool? isEnabled,
    bool? hasPhonePermission,
    bool? hasOverlayPermission,
    bool? hasMicPermission,
    CallStatus? callStatus,
    bool? isOverlayVisible,
    bool? isListening,
    bool? isSpeakingTts,
    String? currentTranscription,
    String? currentTranslation,
  }) {
    return CallAssistantState(
      isEnabled: isEnabled ?? this.isEnabled,
      hasPhonePermission: hasPhonePermission ?? this.hasPhonePermission,
      hasOverlayPermission: hasOverlayPermission ?? this.hasOverlayPermission,
      hasMicPermission: hasMicPermission ?? this.hasMicPermission,
      callStatus: callStatus ?? this.callStatus,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      isListening: isListening ?? this.isListening,
      isSpeakingTts: isSpeakingTts ?? this.isSpeakingTts,
      currentTranscription: currentTranscription ?? this.currentTranscription,
      currentTranslation: currentTranslation ?? this.currentTranslation,
    );
  }
}

