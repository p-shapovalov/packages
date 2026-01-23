package io.flutter.plugins.googlemaps;

import android.os.Bundle;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.gms.maps.MapView;
import io.flutter.plugins.nativeview.NativeView;

/**
 * A NativeView implementation for Google Maps.
 *
 * <p>This view manages a Google MapView that renders below a transparent Flutter view. It handles
 * the MapView lifecycle and method channel communication through GoogleMapController.
 *
 * <p>Touch event forwarding is handled by the parent {@link NativeViewFlutterActivity} via its
 * {@link NativeViewGestureHandler}. When this view becomes active, the activity automatically sets
 * the MapView as the gesture handler's target.
 */
public class GoogleMapNativeView extends NativeView {

  private GoogleMapController mapController;

  @NonNull
  @Override
  protected View onCreateView() {
    GoogleMapBuilder builder = new GoogleMapBuilder();
    mapController =
        builder.build(
            0, // Map ID - single map per activity
            getContext(),
            getFlutterEngine().getDartExecutor().getBinaryMessenger(),
            this::getLifecycle);

    return mapController.getView();
  }

  @Override
  protected void onStart() {
    MapView mapView = getMapView();
    if (mapView != null) {
      mapView.onStart();
    }
  }

  @Override
  protected void onResume() {
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
  }

  @Override
  protected void onStop() {
    MapView mapView = getMapView();
    if (mapView != null) {
      mapView.onStop();
    }
  }

  @Override
  protected void onSaveInstanceState(@NonNull Bundle outState) {
    MapView mapView = getMapView();
    if (mapView != null) {
      mapView.onSaveInstanceState(outState);
    }
  }

  @Override
  protected void onLowMemory() {
    MapView mapView = getMapView();
    if (mapView != null) {
      mapView.onLowMemory();
    }
  }

  @Override
  protected void onDispose() {
    if (mapController != null) {
      mapController.dispose();
      mapController = null;
    }
  }

  /**
   * Gets the MapView instance.
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

  /**
   * Gets the GoogleMapController instance.
   *
   * @return The controller, or null if not yet initialized.
   */
  @Nullable
  public GoogleMapController getMapController() {
    return mapController;
  }
}
