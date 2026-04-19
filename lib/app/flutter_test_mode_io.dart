import 'dart:io' show Platform;

/// True when running under `flutter test` (VM / mobile/desktop test binary).
bool get runningInFlutterTest =>
    Platform.environment['FLUTTER_TEST'] == 'true';
