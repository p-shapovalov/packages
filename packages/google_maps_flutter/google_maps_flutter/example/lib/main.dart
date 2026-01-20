// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'animate_camera.dart';
import 'clustering.dart';
import 'ground_overlay.dart';
import 'heatmap.dart';
import 'lite_mode.dart';
import 'map_click.dart';
import 'map_coordinates.dart';
import 'map_map_id.dart';
import 'map_ui.dart';
import 'marker_icons.dart';
import 'move_camera.dart';
import 'padding.dart';
import 'page.dart';
import 'place_circle.dart';
import 'place_marker.dart';
import 'place_polygon.dart';
import 'place_polyline.dart';
import 'scrolling_map.dart';
import 'snapshot.dart';
import 'tile_overlay.dart';

final List<GoogleMapExampleAppPage> _allPages = <GoogleMapExampleAppPage>[
  const MapUiPage(),
  const MapCoordinatesPage(),
  const MapClickPage(),
  const AnimateCameraPage(),
  const MoveCameraPage(),
  const PlaceMarkerPage(),
  const MarkerIconsPage(),
  const ScrollingMapPage(),
  const PlacePolylinePage(),
  const PlacePolygonPage(),
  const PlaceCirclePage(),
  const PaddingPage(),
  const SnapshotPage(),
  const LiteModePage(),
  const TileOverlayPage(),
  const GroundOverlayPage(),
  const ClusteringPage(),
  const MapIdPage(),
  const HeatmapPage(),
];

/// MapsDemo is the Main Application.
class MapsDemo extends StatelessWidget {
  /// Default Constructor
  const MapsDemo({super.key});

  void _pushPage(BuildContext context, GoogleMapExampleAppPage page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) =>
                Scaffold(appBar: AppBar(title: Text(page.title)), body: page),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GoogleMaps examples')),
      body: ListView.builder(
        itemCount: _allPages.length,
        itemBuilder:
            (_, int index) => ListTile(
              leading: _allPages[index].leading,
              title: Text(_allPages[index].title),
              onTap: () => _pushPage(context, _allPages[index]),
            ),
      ),
    );
  }
}

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

  runApp(const MaterialApp(home: NativeMapOverlayDemo()));
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

/// Demo showing GoogleMap widget working with native map overlay mode.
///
/// This demonstrates that the standard GoogleMap widget and GoogleMapController
/// work seamlessly whether using PlatformViews or native map overlay mode.
class NativeMapOverlayDemo extends StatefulWidget {
  const NativeMapOverlayDemo({super.key});

  @override
  State<NativeMapOverlayDemo> createState() => _NativeMapOverlayDemoState();
}

class _NativeMapOverlayDemoState extends State<NativeMapOverlayDemo> {
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
    final bool isNativeOverlay = Platform.isAndroid &&
        (GoogleMapsFlutterPlatform.instance as GoogleMapsFlutterAndroid)
            .useNativeMapOverlay;

    return Scaffold(
      // Use transparent background when in native overlay mode
      backgroundColor: isNativeOverlay ? Colors.transparent : null,
      appBar: AppBar(
        title: const Text('Native Map Overlay Demo'),
        backgroundColor: isNativeOverlay
            ? Colors.blue.withOpacity(0.9)
            : null,
      ),
      body: Stack(
        children: <Widget>[
          // The GoogleMap widget - in native overlay mode, this returns
          // a transparent container and the native map shows through
          Positioned.fill(child: GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false, // We'll use custom controls
            onTap: (LatLng position) {
              _showSnackBar('Map tapped at $position');
            },
          )),

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
                    isNativeOverlay
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
