// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'native_map_gesture_controller.dart';

/// Global tracker for pointers that landed on the map.
///
/// This is used by [NativeMapOverlayApp] and [NativeMapOverlayBody] to
/// coordinate gesture handling across the widget tree.
class _NativeMapPointerTracker {
  _NativeMapPointerTracker._();

  static final _NativeMapPointerTracker instance = _NativeMapPointerTracker._();

  /// Set of pointers that landed on the map (not on overlay widgets).
  final Set<int> _pointersOnMap = <int>{};

  /// Called when a pointer lands on the map widget.
  void onMapPointerDown(PointerDownEvent event) {
    _pointersOnMap.add(event.pointer);
  }

  /// Called for all pointer down events at the app level.
  /// Claims pointers that didn't land on the map.
  void onAppPointerDown(PointerDownEvent event) {
    if (!_pointersOnMap.contains(event.pointer)) {
      // This pointer didn't land on the map, so claim it
      NativeMapGestureController.claimPointer(event.pointer);
    }
    // Clean up - remove from tracking set
    _pointersOnMap.remove(event.pointer);
  }
}

/// A widget that wraps your entire app to enable native map overlay gesture handling.
///
/// This widget should wrap your [MaterialApp] or [MaterialApp.router] at the
/// top level. It intercepts all pointer events and claims those that don't
/// land on a [NativeMapOverlayBody] widget.
///
/// Example with MaterialApp:
/// ```dart
/// NativeMapOverlayApp(
///   enabled: isNativeOverlayMode,
///   child: MaterialApp(
///     home: MyHomePage(),
///   ),
/// )
/// ```
///
/// Example with MaterialApp.router:
/// ```dart
/// NativeMapOverlayApp(
///   enabled: isNativeOverlayMode,
///   child: MaterialApp.router(
///     routerConfig: _router,
///   ),
/// )
/// ```
///
/// Then in your pages, wrap the map area with [NativeMapOverlayBody]:
/// ```dart
/// Scaffold(
///   backgroundColor: Colors.transparent,
///   body: NativeMapOverlayBody(
///     enabled: isNativeOverlayMode,
///     child: GoogleMap(...),
///   ),
/// )
/// ```
class NativeMapOverlayApp extends StatelessWidget {
  /// Creates a native map overlay app wrapper.
  const NativeMapOverlayApp({
    super.key,
    required this.enabled,
    required this.child,
  });

  /// Whether native map gesture handling is enabled.
  final bool enabled;

  /// The child widget, typically a [MaterialApp] or [MaterialApp.router].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Listener(
      onPointerDown: _NativeMapPointerTracker.instance.onAppPointerDown,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

/// A widget that marks an area as containing the native map.
///
/// Wrap your [GoogleMap] widget with this to indicate that pointers landing
/// on this area should be forwarded to the native map instead of being claimed
/// by Flutter.
///
/// This widget must be used in conjunction with [NativeMapOverlayApp] at the
/// app level.
///
/// Example:
/// ```dart
/// Scaffold(
///   backgroundColor: Colors.transparent,
///   appBar: AppBar(title: Text('Map Page')),
///   body: Stack(
///     children: [
///       NativeMapOverlayBody(
///         enabled: isNativeOverlayMode,
///         child: GoogleMap(...),
///       ),
///       // Overlay widgets on top of the map
///       Positioned(
///         bottom: 16,
///         child: FloatingActionButton(...),
///       ),
///     ],
///   ),
/// )
/// ```
class NativeMapOverlayBody extends StatelessWidget {
  /// Creates a native map overlay body.
  const NativeMapOverlayBody({
    super.key,
    required this.enabled,
    required this.child,
  });

  /// Whether native map gesture handling is enabled.
  final bool enabled;

  /// The child widget, typically a [GoogleMap].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Listener(
      onPointerDown: _NativeMapPointerTracker.instance.onMapPointerDown,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
