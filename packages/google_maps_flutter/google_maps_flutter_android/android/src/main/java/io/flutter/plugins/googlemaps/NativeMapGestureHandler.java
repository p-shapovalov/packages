// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.googlemaps;

import android.os.SystemClock;
import android.view.MotionEvent;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashSet;

/**
 * Handles gesture forwarding between Flutter and a native MapView.
 *
 * <p>This class manages which touch events should be forwarded to the native MapView and which
 * should be handled exclusively by Flutter. It uses a pointer claiming mechanism where Flutter can
 * claim specific pointers to prevent them from being forwarded to the map.
 *
 * <p>Usage:
 *
 * <pre>{@code
 * NativeMapGestureHandler gestureHandler = new NativeMapGestureHandler(mapView, binaryMessenger);
 *
 * // In Activity.dispatchTouchEvent():
 * gestureHandler.dispatchTouchEvent(event);
 * }</pre>
 */
public class NativeMapGestureHandler implements MethodChannel.MethodCallHandler {

  private static final String CHANNEL_NAME =
      "plugins.flutter.dev/google_maps_flutter_android/gestures";

  private final MethodChannel channel;

  /** The MapView to forward touch events to. */
  @Nullable private View mapView;

  /**
   * When true, touch events are dispatched to the MapView for gesture handling. When false, the
   * MapView does not receive touch events, allowing Flutter to handle all gestures exclusively.
   */
  private boolean mapGesturesEnabled = true;

  /**
   * Set of pointer IDs that have been claimed by Flutter widgets. Touch events for these pointers
   * will not be forwarded to the MapView.
   */
  private final HashSet<Integer> claimedPointers = new HashSet<>();

  /**
   * Creates a new gesture handler.
   *
   * @param binaryMessenger The Flutter binary messenger for method channel communication.
   */
  public NativeMapGestureHandler(@NonNull BinaryMessenger binaryMessenger) {
    channel = new MethodChannel(binaryMessenger, CHANNEL_NAME);
    channel.setMethodCallHandler(this);
  }

  /**
   * Sets the MapView to forward touch events to.
   *
   * @param mapView The MapView, or null to disable touch forwarding.
   */
  public void setMapView(@Nullable View mapView) {
    this.mapView = mapView;
  }

  /**
   * Gets whether map gestures are currently enabled.
   *
   * @return true if gestures are enabled, false otherwise.
   */
  public boolean isMapGesturesEnabled() {
    return mapGesturesEnabled;
  }

  /**
   * Sets whether map gestures are enabled.
   *
   * @param enabled true to enable gestures, false to disable.
   */
  public void setMapGesturesEnabled(boolean enabled) {
    this.mapGesturesEnabled = enabled;
  }

  /**
   * Dispatches a touch event to the MapView if appropriate.
   *
   * <p>Events are forwarded to the MapView only if:
   *
   * <ul>
   *   <li>Map gestures are enabled
   *   <li>A MapView is set
   *   <li>No pointer in the event has been claimed by Flutter
   * </ul>
   *
   * @param event The touch event to dispatch.
   */
  public void dispatchTouchEvent(@NonNull MotionEvent event) {
    int action = event.getActionMasked();
    int pointerIndex = event.getActionIndex();
    int pointerId = event.getPointerId(pointerIndex);

    // Clean up claimed pointers when the touch sequence ends
    if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_CANCEL) {
      claimedPointers.clear();
    } else if (action == MotionEvent.ACTION_POINTER_UP) {
      claimedPointers.remove(pointerId);
    }

    // Check if any pointer in this event is claimed by Flutter
    boolean hasClaimedPointer = false;
    for (int i = 0; i < event.getPointerCount(); i++) {
      if (claimedPointers.contains(event.getPointerId(i))) {
        hasClaimedPointer = true;
        break;
      }
    }

    if (mapGesturesEnabled && mapView != null && !hasClaimedPointer) {
      mapView.dispatchTouchEvent(event);
    }
  }

  /**
   * Claims a pointer for exclusive Flutter handling.
   *
   * <p>Once a pointer is claimed, touch events for that pointer will not be forwarded to the
   * MapView. This also sends a cancel event to the MapView to cancel any ongoing gesture.
   *
   * @param pointerId The pointer ID to claim.
   */
  public void claimPointer(int pointerId) {
    claimedPointers.add(pointerId);
    cancelPointerOnMapView();
  }

  /**
   * Releases a previously claimed pointer.
   *
   * @param pointerId The pointer ID to release.
   */
  public void releasePointer(int pointerId) {
    claimedPointers.remove(pointerId);
  }

  /** Sends a cancel event to the MapView to cancel any ongoing gesture. */
  private void cancelPointerOnMapView() {
    if (mapView != null) {
      long now = SystemClock.uptimeMillis();
      MotionEvent cancelEvent = MotionEvent.obtain(now, now, MotionEvent.ACTION_CANCEL, 0, 0, 0);
      mapView.dispatchTouchEvent(cancelEvent);
      cancelEvent.recycle();
    }
  }

  /** Releases resources and unregisters the method channel handler. */
  public void dispose() {
    channel.setMethodCallHandler(null);
    claimedPointers.clear();
    mapView = null;
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
      case "claimPointer":
        Integer pointerId = call.argument("pointerId");
        if (pointerId != null) {
          claimPointer(pointerId);
        }
        result.success(null);
        break;
      case "releasePointer":
        Integer releasePointerId = call.argument("pointerId");
        if (releasePointerId != null) {
          releasePointer(releasePointerId);
        }
        result.success(null);
        break;
      default:
        result.notImplemented();
        break;
    }
  }
}
