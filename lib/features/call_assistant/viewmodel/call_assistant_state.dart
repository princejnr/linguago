import '../data/models/call_session.dart';
import '../data/models/voip_session.dart';

class CallAssistantState {
  const CallAssistantState({
    this.isEnabled = false,
    this.isWhatsAppEnabled = true,
    this.isTeamsEnabled = true,
    this.hasPhonePermission = false,
    this.hasOverlayPermission = false,
    this.hasMicPermission = false,
    this.callStatus = CallStatus.idle,
    this.isVoipActive = false,
    this.activeApp = VoipApp.cellular,
    this.isOverlayVisible = false,
    this.isListening = false,
    this.isSpeakingTts = false,
    this.currentTranscription,
    this.currentTranslation,
  });

  final bool isEnabled;
  final bool isWhatsAppEnabled;
  final bool isTeamsEnabled;
  final bool hasPhonePermission;
  final bool hasOverlayPermission;
  final bool hasMicPermission;
  final CallStatus callStatus;
  final bool isVoipActive;
  final VoipApp activeApp;
  final bool isOverlayVisible;
  final bool isListening;
  final bool isSpeakingTts;
  final String? currentTranscription;
  final String? currentTranslation;

  bool get areAllPermissionsGranted =>
      hasPhonePermission && hasOverlayPermission && hasMicPermission;

  bool get isInAnyCall => callStatus == CallStatus.active || isVoipActive;

  CallAssistantState copyWith({
    bool? isEnabled,
    bool? isWhatsAppEnabled,
    bool? isTeamsEnabled,
    bool? hasPhonePermission,
    bool? hasOverlayPermission,
    bool? hasMicPermission,
    CallStatus? callStatus,
    bool? isVoipActive,
    VoipApp? activeApp,
    bool? isOverlayVisible,
    bool? isListening,
    bool? isSpeakingTts,
    String? currentTranscription,
    String? currentTranslation,
  }) {
    return CallAssistantState(
      isEnabled: isEnabled ?? this.isEnabled,
      isWhatsAppEnabled: isWhatsAppEnabled ?? this.isWhatsAppEnabled,
      isTeamsEnabled: isTeamsEnabled ?? this.isTeamsEnabled,
      hasPhonePermission: hasPhonePermission ?? this.hasPhonePermission,
      hasOverlayPermission: hasOverlayPermission ?? this.hasOverlayPermission,
      hasMicPermission: hasMicPermission ?? this.hasMicPermission,
      callStatus: callStatus ?? this.callStatus,
      isVoipActive: isVoipActive ?? this.isVoipActive,
      activeApp: activeApp ?? this.activeApp,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      isListening: isListening ?? this.isListening,
      isSpeakingTts: isSpeakingTts ?? this.isSpeakingTts,
      currentTranscription: currentTranscription ?? this.currentTranscription,
      currentTranslation: currentTranslation ?? this.currentTranslation,
    );
  }
}

