import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';

import '../models/call_session.dart';

final telephonyDataSourceProvider = Provider<TelephonyDataSource>((ref) {
  final dataSource = TelephonyDataSource();
  ref.onDispose(dataSource.dispose);
  return dataSource;
});

/// Data source responsible for monitoring phone call transitions on Android.
class TelephonyDataSource {
  TelephonyDataSource() {
    _initStream();
  }

  final _callStateController = StreamController<CallStatus>.broadcast();
  StreamSubscription<PhoneState>? _subscription;

  Stream<CallStatus> get callStateStream => _callStateController.stream;

  /// Check whether the READ_PHONE_STATE permission is granted.
  Future<bool> hasPermission() async {
    final status = await Permission.phone.status;
    return status.isGranted;
  }

  /// Request the phone state permission from the user.
  Future<bool> requestPermission() async {
    final status = await Permission.phone.request();
    if (status.isGranted) {
      _initStream();
    }
    return status.isGranted;
  }

  void _initStream() {
    _subscription?.cancel();
    try {
      _subscription = PhoneState.stream.listen(
        (phoneState) {
          final mapped = _mapStatus(phoneState.status);
          if (kDebugMode) {
            debugPrint('[TelephonyDataSource] Raw event: ${phoneState.status} -> $mapped');
          }
          _callStateController.add(mapped);
        },
        onError: (Object error) {
          if (kDebugMode) {
            debugPrint('[TelephonyDataSource] Stream error: $error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TelephonyDataSource] Could not listen to PhoneState.stream: $e');
      }
    }
  }

  CallStatus _mapStatus(PhoneStateStatus raw) {
    switch (raw) {
      case PhoneStateStatus.CALL_INCOMING:
        return CallStatus.incoming;
      case PhoneStateStatus.CALL_STARTED:
      case PhoneStateStatus.CALL_OUTGOING:
        return CallStatus.active;
      case PhoneStateStatus.CALL_ENDED:
        return CallStatus.ended;
      case PhoneStateStatus.NOTHING:
        return CallStatus.idle;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _callStateController.close();
  }
}
