# Kugla

Kugla is a GeoGuessr-style Flutter MVP with a custom Stitch-inspired interface,
Google Maps, and Google Street View gameplay.

## Maps Setup

The app expects a Google Maps API key for both Android and iOS.

Android:
- Add `googleMapsApiKey=YOUR_KEY` to `android/local.properties`
- Or export `GOOGLE_MAPS_API_KEY` before building

iOS:
- Create `ios/Flutter/Secrets.xcconfig` with:

```xcconfig
GMS_API_KEY = YOUR_KEY
```

These files are ignored by git so the key stays out of tracked source.

## Verification

```bash
flutter analyze
flutter test
```
