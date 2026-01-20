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
}
