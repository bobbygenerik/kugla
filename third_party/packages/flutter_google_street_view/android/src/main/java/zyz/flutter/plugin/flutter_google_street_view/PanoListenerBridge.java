package zyz.flutter.plugin.flutter_google_street_view;

import androidx.annotation.Nullable;
import com.google.android.gms.maps.StreetViewPanorama;
import com.google.android.gms.maps.model.StreetViewPanoramaLocation;

/**
 * GMS can invoke {@link StreetViewPanorama.OnStreetViewPanoramaChangeListener} with a null
 * location when no panorama exists (see Google android-maps-compose#265). Kotlin overrides of
 * the SAM interface use a non-null parameter and crash before the callback body. Bridge through
 * Java so null is forwarded safely to Kotlin.
 */
public final class PanoListenerBridge {

    public interface Host {
        void onStreetViewPanoramaChange(@Nullable StreetViewPanoramaLocation location);
    }

    public static StreetViewPanorama.OnStreetViewPanoramaChangeListener create(final Host host) {
        return host::onStreetViewPanoramaChange;
    }

    private PanoListenerBridge() {}
}
