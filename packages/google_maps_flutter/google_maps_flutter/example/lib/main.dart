// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_native_view_android/flutter_native_view_android.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

/// Whether native map overlay mode is enabled.
bool get isNativeOverlayMode =>
    Platform.isAndroid &&
    (GoogleMapsFlutterPlatform.instance as GoogleMapsFlutterAndroid)
        .useNativeMapOverlay;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;

  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    // Enable native map overlay mode on Android.
    // This uses GoogleMapActivity with a fullscreen native map behind
    // a transparent Flutter view, instead of PlatformViews.
    mapsImplementation.useNativeMapOverlay = true;

    // Initialize the map renderer
    initializeMapRenderer();
  }

  // Wrap the entire app with NativeViewOverlayApp for gesture handling
  runApp(
    NativeViewOverlayApp(
      enabled: isNativeOverlayMode,
      child: const MaterialApp(home: HomePage()),
    ),
  );
}

Completer<AndroidMapRenderer?>? _initializedRendererCompleter;

/// Initializes map renderer to the `latest` renderer type for Android platform.
///
/// The renderer must be requested before creating GoogleMap instances,
/// as the renderer can be initialized only once per application context.
Future<AndroidMapRenderer?> initializeMapRenderer() async {
  if (_initializedRendererCompleter != null) {
    return _initializedRendererCompleter!.future;
  }

  final Completer<AndroidMapRenderer?> completer =
      Completer<AndroidMapRenderer?>();
  _initializedRendererCompleter = completer;

  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    unawaited(
      mapsImplementation
          .initializeWithRenderer(AndroidMapRenderer.latest)
          .then(
            (AndroidMapRenderer initializedRenderer) =>
                completer.complete(initializedRenderer),
          ),
    );
  } else {
    completer.complete(null);
  }

  return completer.future;
}

/// Home page with navigation to the map demo.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isNativeOverlayMode ? Colors.transparent : null,
      appBar: AppBar(
        title: const Text('Native Map Overlay Demo'),
        backgroundColor: isNativeOverlayMode ? Colors.blue.withOpacity(0.9) : null,
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Map Demo'),
            subtitle: const Text('Interactive map with overlays'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MapDemoPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Information about native map overlay mode'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AboutPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Demo page showing GoogleMap widget working with native map overlay mode.
class MapDemoPage extends StatefulWidget {
  const MapDemoPage({super.key});

  @override
  State<MapDemoPage> createState() => _MapDemoPageState();
}

class _MapDemoPageState extends State<MapDemoPage> {
  GoogleMapController? _controller;
  CameraPosition? _currentPosition;
  final Set<Marker> _markers = <Marker>{};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    // Add a sample marker
    _markers.add(
      Marker(
        markerId: const MarkerId('sf_marker'),
        position: const LatLng(37.7749, -122.4194),
        infoWindow: const InfoWindow(
          title: 'San Francisco',
          snippet: 'Welcome to SF!',
        ),
        onTap: () {
          _showSnackBar('Marker tapped!');
        },
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _showSnackBar('Map created successfully!');
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentPosition = position;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _goToSydney() async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
        const LatLng(-33.8688, 151.2093),
        14,
      ),
    );
  }

  Future<void> _goToTokyo() async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
        const LatLng(35.6762, 139.6503),
        14,
      ),
    );
  }

  Future<void> _zoomIn() async {
    await _controller?.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    await _controller?.animateCamera(CameraUpdate.zoomOut());
  }

  void _addMarker() {
    if (_currentPosition == null) {
      return;
    }
    final String markerId = 'marker_${_markers.length}';
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: _currentPosition!.target,
          infoWindow: InfoWindow(
            title: 'Marker $markerId',
            snippet: 'Added at ${_currentPosition!.target}',
          ),
        ),
      );
    });
    _showSnackBar('Marker added at ${_currentPosition!.target}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isNativeOverlayMode ? Colors.transparent : null,
      appBar: AppBar(
        title: const Text('Map Demo'),
        backgroundColor: isNativeOverlayMode ? Colors.blue.withOpacity(0.9) : null,
      ),
      body: Stack(
        children: <Widget>[
          // The GoogleMap widget wrapped with NativeViewOverlayBody
          Positioned.fill(
            child: NativeViewOverlayBody(
              enabled: isNativeOverlayMode,
              child: GoogleMap(
                initialCameraPosition: _initialPosition,
                onMapCreated: _onMapCreated,
                onCameraMove: _onCameraMove,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                onTap: (LatLng position) {
                  _showSnackBar('Map tapped at $position');
                },
              ),
            ),
          ),

          // Info panel overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    isNativeOverlayMode
                        ? 'Mode: Native Map Overlay'
                        : 'Mode: PlatformView',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_currentPosition != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${_currentPosition!.target.latitude.toStringAsFixed(4)}, '
                      'Lng: ${_currentPosition!.target.longitude.toStringAsFixed(4)}',
                    ),
                    Text('Zoom: ${_currentPosition!.zoom.toStringAsFixed(2)}'),
                  ],
                ],
              ),
            ),
          ),

          // Zoom controls
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: <Widget>[
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _goToSydney,
                    child: const Text('Sydney'),
                  ),
                  ElevatedButton(
                    onPressed: _goToTokyo,
                    child: const Text('Tokyo'),
                  ),
                  ElevatedButton(
                    onPressed: _addMarker,
                    child: const Text('Add Marker'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// About page explaining native map overlay mode.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isNativeOverlayMode ? Colors.transparent : null,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: isNativeOverlayMode ? Colors.blue.withOpacity(0.9) : null,
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Native Map Overlay Mode',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'This demo showcases the native map overlay mode for Google Maps '
              'Flutter on Android. Instead of using PlatformViews, the map is '
              'rendered as a native MapView behind a transparent Flutter view.',
            ),
            SizedBox(height: 12),
            Text(
              'Benefits:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('• Better performance - no PlatformView overhead'),
            Text('• Smoother animations and gestures'),
            Text('• Full native map rendering quality'),
            SizedBox(height: 12),
            Text(
              'Usage:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('1. Wrap your app with NativeViewOverlayApp'),
            Text('2. Wrap the GoogleMap with NativeViewOverlayBody'),
            Text('3. Set transparent backgrounds on Scaffolds'),
          ],
        ),
      ),
    );
  }
}
