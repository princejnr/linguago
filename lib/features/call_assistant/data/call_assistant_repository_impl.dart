import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'call_assistant_repository.dart';
import 'datasources/overlay_datasource.dart';
import 'datasources/telephony_datasource.dart';
import 'models/call_session.dart';

final callAssistantRepositoryProvider = Provider<CallAssistantRepository>((ref) {
  final telephony = ref.watch(telephonyDataSourceProvider);
  final overlay = ref.watch(overlayDataSourceProvider);
  return CallAssistantRepositoryImpl(telephony, overlay);
});

class CallAssistantRepositoryImpl implements CallAssistantRepository {
  CallAssistantRepositoryImpl(this._telephony, this._overlay) {
    _overlayEventsSubscription = _overlay.overlayEvents.listen((event) {
      if (event is Map && event['type'] == 'quick_reply') {
        final phrase = event['phrase'] as String?;
        if (phrase != null && phrase.isNotEmpty) {
          _overlayRepliesController.add(phrase);
        }
      }
    });
  }

  final TelephonyDataSource _telephony;
  final OverlayDataSource _overlay;
  final _overlayRepliesController = StreamController<String>.broadcast();
  StreamSubscription<dynamic>? _overlayEventsSubscription;

  @override
  Stream<CallStatus> get callStateStream => _telephony.callStateStream;

  @override
  Stream<String> get overlayReplyStream => _overlayRepliesController.stream;

  @override
  Future<bool> checkPermissions() async {
    final phone = await _telephony.hasPermission();
    final overlay = await _overlay.hasPermission();
    return phone && overlay;
  }

  @override
  Future<bool> requestPhonePermission() => _telephony.requestPermission();

  @override
  Future<bool> requestOverlayPermission() => _overlay.requestPermission();

  @override
  Future<void> showOverlay() => _overlay.showOverlay();

  @override
  Future<void> closeOverlay() => _overlay.closeOverlay();

  @override
  Future<void> updateOverlaySubtitles({
    required String transcription,
    required String translation,
  }) {
    return _overlay.sendToOverlay({
      'type': 'subtitle',
      'transcription': transcription,
      'translation': translation,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void dispose() {
    _overlayEventsSubscription?.cancel();
    _overlayRepliesController.close();
  }
}
