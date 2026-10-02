import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final overlayDataSourceProvider = Provider<OverlayDataSource>((ref) {
  return OverlayDataSource();
});

/// Data source responsible for controlling the floating overlay window on Android.
class OverlayDataSource {
  /// Whether the "Display over other apps" (SYSTEM_ALERT_WINDOW) permission is granted.
  Future<bool> hasPermission() => FlutterOverlayWindow.isPermissionGranted();

  /// Requests the overlay permission from the user by opening system settings.
  Future<bool> requestPermission() async {
    final granted = await FlutterOverlayWindow.requestPermission();
    return granted ?? false;
  }

  /// Opens the floating overlay window.
  Future<void> showOverlay({
    int height = 780,
    int width = WindowSize.matchParent,
  }) async {
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      if (kDebugMode) {
        debugPrint('[OverlayDataSource] Cannot show overlay: permission denied');
      }
      return;
    }

    await FlutterOverlayWindow.showOverlay(
      height: height,
      width: width,
      alignment: OverlayAlignment.topCenter,
      flag: OverlayFlag.defaultFlag,
      enableDrag: true,
      overlayTitle: 'Linguago Call Assistant',
      overlayContent: 'Live call translation active',
      positionGravity: PositionGravity.auto,
    );
  }

  /// Resizes the overlay dynamically (e.g. collapsing or expanding).
  Future<void> resizeOverlay({
    required int width,
    required int height,
    bool enableDrag = true,
  }) => FlutterOverlayWindow.resizeOverlay(width, height, enableDrag);

  /// Closes the floating overlay window if open.
  Future<void> closeOverlay() => FlutterOverlayWindow.closeOverlay();

  /// Sends a structured JSON-compatible map to the overlay isolate.
  Future<void> sendToOverlay(Map<String, dynamic> data) async {
    await FlutterOverlayWindow.shareData(data);
  }

  /// Stream of messages received from the overlay window back to the main app.
  Stream<dynamic> get overlayEvents => FlutterOverlayWindow.overlayListener;
}
