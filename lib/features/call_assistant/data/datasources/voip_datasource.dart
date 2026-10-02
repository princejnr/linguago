import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/voip_session.dart';

final voipDataSourceProvider = Provider<VoipDataSource>((ref) {
  final dataSource = VoipDataSource();
  ref.onDispose(dataSource.dispose);
  return dataSource;
});

/// Data source responsible for listening to Android VoIP audio mode transitions
/// (AudioManager.MODE_IN_COMMUNICATION) via native Kotlin platform channels.
class VoipDataSource {
  VoipDataSource({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ??
            const MethodChannel('com.princejnr.linguago/voip_detector_methods'),
        _eventChannel = eventChannel ??
            const EventChannel('com.princejnr.linguago/voip_detector_events') {
    _initStream();
  }

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  final _voipStateController = StreamController<VoipCallEvent>.broadcast();
  StreamSubscription<dynamic>? _subscription;

  Stream<VoipCallEvent> get voipStream => _voipStateController.stream;

  void _initStream() {
    _subscription?.cancel();
    try {
      _subscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic raw) {
          if (raw is Map) {
            final event = VoipCallEvent.fromMap(raw);
            if (kDebugMode) {
              debugPrint('[VoipDataSource] Mode changed: isVoip=${event.isVoip} (mode=${event.mode})');
            }
            _voipStateController.add(event);
          }
        },
        onError: (Object error) {
          if (kDebugMode) {
            debugPrint('[VoipDataSource] EventChannel error: $error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VoipDataSource] Could not register EventChannel stream: $e');
      }
    }
  }

  /// Query the current VoIP audio state directly via MethodChannel.
  Future<bool> isVoipActive() async {
    try {
      final active = await _methodChannel.invokeMethod<bool>('isVoipActive');
      return active ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VoipDataSource] isVoipActive error: $e');
      }
      return false;
    }
  }

  /// Query the raw AudioManager mode directly.
  Future<int> getAudioMode() async {
    try {
      final mode = await _methodChannel.invokeMethod<int>('getAudioMode');
      return mode ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VoipDataSource] getAudioMode error: $e');
      }
      return 0;
    }
  }

  /// Manually inject an event into the stream (for unit testing or in-app simulations).
  void emitSimulatedEvent(VoipCallEvent event) {
    _voipStateController.add(event);
  }

  void dispose() {
    _subscription?.cancel();
    _voipStateController.close();
  }
}
