package io.flutter.plugins.googlemaps;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.gms.maps.MapView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.nativeview.NativeView;
import io.flutter.plugins.nativeview.NativeViewFlutterActivity;

/** Activity that hosts a Google Map below a transparent Flutter view. */
public class GoogleMapActivity extends NativeViewFlutterActivity {

  public static final String VIEW_KEY_MAP = "map";

  @Nullable private GoogleMapInitializer googleMapInitializer;

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);

    // Set up the MapsInitializerApi handler so Dart can call initializeWithRenderer() and warmup()
    googleMapInitializer =
        new GoogleMapInitializer(this, flutterEngine.getDartExecutor().getBinaryMessenger());
  }

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
