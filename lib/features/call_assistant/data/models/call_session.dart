/// Represents the current state of telephony audio / phone call.
enum CallStatus {
  idle,
  incoming,
  active,
  ended,
}

/// Metadata and state of an ongoing or recent phone call.
class CallSession {
  const CallSession({
    required this.status,
    this.startedAt,
    this.lastTranscription,
    this.lastTranslation,
  });

  final CallStatus status;
  final DateTime? startedAt;
  final String? lastTranscription;
  final String? lastTranslation;

  bool get isInCall => status == CallStatus.active;

  CallSession copyWith({
    CallStatus? status,
    DateTime? startedAt,
    String? lastTranscription,
    String? lastTranslation,
  }) {
    return CallSession(
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      lastTranscription: lastTranscription ?? this.lastTranscription,
      lastTranslation: lastTranslation ?? this.lastTranslation,
    );
  }
}
