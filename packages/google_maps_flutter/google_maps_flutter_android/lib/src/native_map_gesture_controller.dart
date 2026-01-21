// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

/// Controller for managing native map gesture behavior when using
/// [GoogleMapsFlutterAndroid.useNativeMapOverlay] mode.
///
/// In native overlay mode, the map is rendered as a native Android view behind
/// a transparent Flutter view. This controller allows you to enable or disable
/// touch event dispatching to the native map, which is useful when Flutter UI
/// overlays need to capture gestures exclusively.
///
/// Example:
/// ```dart
/// // Disable map gestures while a bottom sheet is open
/// await NativeMapGestureController.setMapGesturesEnabled(false);
/// showBottomSheet(...);
///
/// // Re-enable when closed
/// await NativeMapGestureController.setMapGesturesEnabled(true);
/// ```
class NativeMapGestureController {
  NativeMapGestureController._();

  static const MethodChannel _channel =
      MethodChannel('plugins.flutter.dev/google_maps_flutter_android/gestures');

  /// Enables or disables touch event dispatching to the native map.
  ///
  /// When [enabled] is true (default), touch events are dispatched to the
  /// native MapView, allowing map gestures like pan, zoom, rotate, and tilt.
  ///
  /// When [enabled] is false, the MapView does not receive touch events,
  /// allowing Flutter widgets to handle all gestures exclusively. This is
  /// useful when you have Flutter UI overlays that need to capture gestures
  /// without the map responding.
  ///
  /// This only applies when using [GoogleMapsFlutterAndroid.useNativeMapOverlay]
  /// mode on Android.
  static Future<void> setMapGesturesEnabled(bool enabled) {
    return _channel.invokeMethod<void>(
      'setMapGesturesEnabled',
      <String, dynamic>{'enabled': enabled},
    );
  }

  /// Returns whether map gestures are currently enabled.
  ///
  /// This only applies when using [GoogleMapsFlutterAndroid.useNativeMapOverlay]
  /// mode on Android.
  static Future<bool> isMapGesturesEnabled() async {
    final bool? result =
        await _channel.invokeMethod<bool>('isMapGesturesEnabled');
    return result ?? true;
  }

  /// Claims a pointer for exclusive Flutter handling.
  ///
  /// When a pointer is claimed, subsequent touch events for that pointer
  /// will not be forwarded to the native MapView, allowing Flutter widgets
  /// to handle the gesture exclusively.
  ///
  /// This is called automatically by [NativeMapGestureForwarder] when a
  /// Flutter widget wins the gesture arena. You typically don't need to
  /// call this directly.
  ///
  /// The pointer is automatically released when the touch sequence ends
  /// (ACTION_UP or ACTION_CANCEL).
  static Future<void> claimPointer(int pointerId) {
    return _channel.invokeMethod<void>(
      'claimPointer',
      <String, dynamic>{'pointerId': pointerId},
    );
  }

  /// Releases a previously claimed pointer.
  ///
  /// After releasing, touch events for this pointer will be forwarded
  /// to the native MapView again.
  ///
  /// Note: Pointers are automatically released when the touch sequence ends,
  /// so calling this is only necessary if you want to release a pointer
  /// mid-gesture.
  static Future<void> releasePointer(int pointerId) {
    return _channel.invokeMethod<void>(
      'releasePointer',
      <String, dynamic>{'pointerId': pointerId},
    );
  }
}
