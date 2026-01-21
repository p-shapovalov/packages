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

/**
 * An Activity that hosts a fullscreen Google Map with a transparent Flutter view overlay.
 *
 * <p>This approach avoids PlatformViews by placing the native MapView directly in the Activity's
 * view hierarchy behind a transparent FlutterView.
 *
 */
public class GoogleMapActivity extends FlutterActivity {

  private GoogleMapController mapController;
  private FlutterEngine cachedFlutterEngine;
  private FrameLayout mapWrapper;
  private NativeMapGestureHandler gestureHandler;

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

      // Set the MapView on the gesture handler so it can forward touch events
      if (gestureHandler != null) {
        gestureHandler.setMapView(mapView);
      }
    }
  }

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    cachedFlutterEngine = flutterEngine;

    // Set up the gesture handler for touch event forwarding
    gestureHandler =
        new NativeMapGestureHandler(flutterEngine.getDartExecutor().getBinaryMessenger());

    // Create the controller early so method channel handlers are ready before Flutter calls them.
    // The controller will wait for the map to be ready via its OnMapReadyCallback.
    if (mapController == null && mapWrapper != null) {
      initializeMapController(flutterEngine);
    }
  }

  @Override
  public boolean dispatchTouchEvent(MotionEvent event) {
    // Delegate touch event handling to the gesture handler
    if (gestureHandler != null) {
      gestureHandler.dispatchTouchEvent(event);
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
    if (gestureHandler != null) {
      gestureHandler.dispose();
      gestureHandler = null;
    }
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
