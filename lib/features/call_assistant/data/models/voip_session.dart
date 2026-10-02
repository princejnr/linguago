/// Domain model and enumerations for VoIP (WhatsApp, Teams, etc.) call tracking.
enum VoipApp {
  cellular,
  whatsapp,
  teams,
  generic,
}

extension VoipAppExtension on VoipApp {
  String get displayName {
    switch (this) {
      case VoipApp.cellular:
        return 'Cellular Call';
      case VoipApp.whatsapp:
        return 'WhatsApp Call';
      case VoipApp.teams:
        return 'Microsoft Teams';
      case VoipApp.generic:
        return 'VoIP Call';
    }
  }

  String get shortTag {
    switch (this) {
      case VoipApp.cellular:
        return '📞 CELLULAR';
      case VoipApp.whatsapp:
        return '🟢 WHATSAPP';
      case VoipApp.teams:
        return '🟣 TEAMS';
      case VoipApp.generic:
        return '🌐 VOIP';
    }
  }
}

class VoipCallEvent {
  const VoipCallEvent({
    required this.isVoip,
    required this.mode,
    required this.timestamp,
    this.app = VoipApp.generic,
  });

  final bool isVoip;
  final int mode;
  final int timestamp;
  final VoipApp app;

  factory VoipCallEvent.fromMap(Map<dynamic, dynamic> map, {VoipApp? detectedApp}) {
    return VoipCallEvent(
      isVoip: map['isVoip'] as bool? ?? false,
      mode: (map['mode'] as num?)?.toInt() ?? 0,
      timestamp: (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      app: detectedApp ?? VoipApp.generic,
    );
  }

  VoipCallEvent copyWith({
    bool? isVoip,
    int? mode,
    int? timestamp,
    VoipApp? app,
  }) {
    return VoipCallEvent(
      isVoip: isVoip ?? this.isVoip,
      mode: mode ?? this.mode,
      timestamp: timestamp ?? this.timestamp,
      app: app ?? this.app,
    );
  }
}
