# Kugla

Kugla is a GeoGuessr-style Flutter MVP with a custom Stitch-inspired interface,
Google Maps, and Google Street View gameplay.

## Maps Setup

The app expects a Google Maps API key for both Android and iOS.

Android:
- Add `googleMapsApiKey=YOUR_KEY` to `android/local.properties`
- Or export `GOOGLE_MAPS_API_KEY` before building

iOS:
- Copy `ios/Flutter/Secrets.xcconfig.example` to
  `ios/Flutter/Secrets.xcconfig`, then replace the placeholder with a valid
  Google Maps Platform key for iOS:

```xcconfig
GMS_API_KEY = YOUR_KEY
```

`ios/Flutter/Secrets.xcconfig` is ignored by git so the real key stays out of
tracked source.

Make sure the key has `Maps SDK for iOS` enabled in Google Cloud, then run the
iOS CocoaPods install step on the Mac build machine:

```bash
cd ios && pod install
```

Firebase platform config is also local-only:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Generate `lib/firebase_options.dart` locally with FlutterFire before building a Firebase-enabled app.

## Verification

```bash
flutter analyze
flutter test
```
