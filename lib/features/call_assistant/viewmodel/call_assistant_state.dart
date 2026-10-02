import '../data/models/call_session.dart';

class CallAssistantState {
  const CallAssistantState({
    this.isEnabled = false,
    this.hasPhonePermission = false,
    this.hasOverlayPermission = false,
    this.callStatus = CallStatus.idle,
    this.isOverlayVisible = false,
    this.currentTranscription,
    this.currentTranslation,
  });

  final bool isEnabled;
  final bool hasPhonePermission;
  final bool hasOverlayPermission;
  final CallStatus callStatus;
  final bool isOverlayVisible;
  final String? currentTranscription;
  final String? currentTranslation;

  bool get areAllPermissionsGranted => hasPhonePermission && hasOverlayPermission;

  CallAssistantState copyWith({
    bool? isEnabled,
    bool? hasPhonePermission,
    bool? hasOverlayPermission,
    CallStatus? callStatus,
    bool? isOverlayVisible,
    String? currentTranscription,
    String? currentTranslation,
  }) {
    return CallAssistantState(
      isEnabled: isEnabled ?? this.isEnabled,
      hasPhonePermission: hasPhonePermission ?? this.hasPhonePermission,
      hasOverlayPermission: hasOverlayPermission ?? this.hasOverlayPermission,
      callStatus: callStatus ?? this.callStatus,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      currentTranscription: currentTranscription ?? this.currentTranscription,
      currentTranslation: currentTranslation ?? this.currentTranslation,
    );
  }
}
