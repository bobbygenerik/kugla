import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'app/app_shell.dart';

/// Splash video starts immediately; Firebase is initialized when the shell loads.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android: initialize the Maps renderer once before any [GoogleMap] is built.
  // useAndroidViewSurface: ClipRRect and other clips around PlatformViews often
  // produce half-map / beige vertical bands on some devices when true; hybrid
  // composition tends to behave better here (see google_maps_flutter_android README).
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final maps = GoogleMapsFlutterPlatform.instance;
    if (maps is GoogleMapsFlutterAndroid) {
      maps.useAndroidViewSurface = false;
      try {
        await maps.initializeWithRenderer(AndroidMapRenderer.latest);
      } catch (_) {
        // Hot restart / second init may throw; safe to ignore.
      }
    }
  }

  runApp(const KuglaApp());
}
