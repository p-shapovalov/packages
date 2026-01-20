// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.googlemaps;

import android.os.Bundle;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.gms.maps.MapView;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.TransparencyMode;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * An Activity that hosts a fullscreen Google Map with a transparent Flutter view overlay.
 *
 * <p>This approach avoids PlatformViews by placing the native MapView directly in the Activity's
 * view hierarchy behind a transparent FlutterView.
 *
 */
public class GoogleMapActivity extends FlutterActivity
    implements MethodChannel.MethodCallHandler {

  private static final String MAP_GESTURES_CHANNEL =
      "plugins.flutter.dev/google_maps_flutter_android/gestures";

  private GoogleMapController mapController;
  private FlutterEngine cachedFlutterEngine;
  private FrameLayout mapWrapper;

  /**
   * When true, touch events are dispatched to the MapView for gesture handling. When false, the
   * MapView does not receive touch events, allowing Flutter to handle all gestures exclusively.
   */
  private boolean mapGesturesEnabled = true;

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    // After super.onCreate(), the FlutterView has been added to the Activity.
    // We need to:
    // 1. Get the content view (which is FlutterView)
    // 2. Create a FrameLayout wrapper
    // 3. The MapView will be added when the controller is initialized

    View contentView = findViewById(android.R.id.content);
    if (contentView instanceof ViewGroup contentParent) {
        if (contentParent.getChildCount() > 0) {
        View flutterView = contentParent.getChildAt(0);

        // Remove FlutterView temporarily
        contentParent.removeView(flutterView);

        // Create wrapper FrameLayout to hold both MapView and FlutterView
        mapWrapper = new FrameLayout(this);
        mapWrapper.setLayoutParams(
            new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        // Add FlutterView on top (MapView will be added at index 0 when controller is created)
        mapWrapper.addView(flutterView);

        // Add wrapper to content parent
        contentParent.addView(mapWrapper);

        // If Flutter engine is already configured, initialize the controller now.
        // Otherwise it will be initialized in configureFlutterEngine.
        if (cachedFlutterEngine != null && mapController == null) {
          initializeMapController(cachedFlutterEngine);
        }
      }
    }
  }

  private void initializeMapController(
      @NonNull FlutterEngine engine) {
    if (mapWrapper == null) {
      return;
    }

    // Use GoogleMapBuilder to create and initialize the controller
    GoogleMapBuilder builder = new GoogleMapBuilder();

    // Build the controller - this creates the MapView and calls init()
    mapController =
        builder.build(
            0, // Map ID - using 0 for single map per activity
            this,
            engine.getDartExecutor().getBinaryMessenger(),
                this::getLifecycle);

    // Get the MapView from the controller and add it to our wrapper
    View mapView = mapController.getView();
    if (mapView != null) {
      mapView.setLayoutParams(
          new FrameLayout.LayoutParams(
              FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

      // Add MapView at index 0 (behind the FlutterView)
      mapWrapper.addView(mapView, 0);
    }
  }

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    cachedFlutterEngine = flutterEngine;

    // Set up the method channel for gesture control
    MethodChannel gesturesChannel =
        new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(), MAP_GESTURES_CHANNEL);
    gesturesChannel.setMethodCallHandler(this);

    // Create the controller early so method channel handlers are ready before Flutter calls them.
    // The controller will wait for the map to be ready via its OnMapReadyCallback.
    if (mapController == null && mapWrapper != null) {
      initializeMapController(flutterEngine);
    }
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    switch (call.method) {
      case "setMapGesturesEnabled":
        Boolean enabled = call.argument("enabled");
        if (enabled != null) {
          mapGesturesEnabled = enabled;
        }
        result.success(null);
        break;
      case "isMapGesturesEnabled":
        result.success(mapGesturesEnabled);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public boolean dispatchTouchEvent(MotionEvent event) {
    // Forward touch events directly to the MapView for gesture handling.
    // This is more efficient than method channels for continuous touch events.
    // The MapView sits behind the transparent FlutterView, so we dispatch
    // touch events to it directly at the Activity level.
    View mapView = getMapView();
    if (mapGesturesEnabled && mapView != null) {
      mapView.dispatchTouchEvent(event);
    }
    return super.dispatchTouchEvent(event);
  }

  @NonNull
  @Override
  public TransparencyMode getTransparencyMode() {
    // Enable transparency so Flutter renders on top of the map
    return TransparencyMode.transparent;
  }

  @Override
  protected void onStart() {
    super.onStart();
    MapView mapView = getMapView();
    if (mapView != null) {
      mapView.onStart();
    }
  }

  @Override
  protected void onResume() {
    super.onResume();
    MapView mapView = getMapView();
    if (mapView != null) {
      mapView.onResume();
    }
  }

  @Override
  protected void onPause() {
    MapView mapView = getMapView();
    if (mapView != null) {
      mapView.onPause();
    }
    super.onPause();
  }

  @Override
  protected void onStop() {
    MapView mapView = getMapView();
    if (mapView != null) {
      mapView.onStop();
    }
    super.onStop();
  }

  @Override
  protected void onDestroy() {
    if (mapController != null) {
      mapController.dispose();
      mapController = null;
    }
    super.onDestroy();
  }

  @Override
  protected void onSaveInstanceState(@NonNull Bundle outState) {
    super.onSaveInstanceState(outState);
    MapView mapView = getMapView();
    if (mapView != null) {
      mapView.onSaveInstanceState(outState);
    }
  }

  @Override
  public void onLowMemory() {
    super.onLowMemory();
    MapView mapView = getMapView();
    if (mapView != null) {
      mapView.onLowMemory();
    }
  }


  /**
   * Gets the MapView instance from the controller.
   *
   * @return The MapView, or null if not yet initialized.
   */
  @Nullable
  public MapView getMapView() {
    if (mapController != null) {
      View view = mapController.getView();
      if (view instanceof MapView) {
        return (MapView) view;
      }
    }
    return null;
  }
}
