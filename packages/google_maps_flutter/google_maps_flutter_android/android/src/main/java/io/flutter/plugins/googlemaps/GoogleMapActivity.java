package io.flutter.plugins.googlemaps;

import androidx.annotation.Nullable;
import com.google.android.gms.maps.MapView;
import io.flutter.plugins.nativeview.NativeView;
import io.flutter.plugins.nativeview.NativeViewFlutterActivity;

/** Activity that hosts a Google Map below a transparent Flutter view. */
public class GoogleMapActivity extends NativeViewFlutterActivity {

  public static final String VIEW_KEY_MAP = "map";

  @Override
  protected void onRegisterNativeViews() {
    registerNativeViewFactory(VIEW_KEY_MAP, GoogleMapNativeView::new);
  }

  @Nullable
  public GoogleMapNativeView getGoogleMapNativeView() {
    NativeView view = getNativeView(VIEW_KEY_MAP);
    if (view instanceof GoogleMapNativeView) {
      return (GoogleMapNativeView) view;
    }
    return null;
  }

  @Nullable
  public MapView getMapView() {
    GoogleMapNativeView nativeView = getGoogleMapNativeView();
    if (nativeView != null) {
      return nativeView.getMapView();
    }
    return null;
  }
}
