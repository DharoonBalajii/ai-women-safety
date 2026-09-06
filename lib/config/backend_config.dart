import 'package:flutter/foundation.dart';

/// Base URL for the Raksha Thunai backend (auth + AI proxy). The backend
/// holds every real secret (Sarvam, Clerk, MSG91) — the app itself never
/// stores or sends an API key.
///
/// `10.0.2.2` is the Android emulator's alias for the host machine's
/// `localhost`; a real device or release build needs an actual deployed
/// backend URL here instead.
String get backendBaseUrl {
  if (kReleaseMode) {
    // TODO: point this at the deployed backend before shipping a release
    // build — 10.0.2.2 only resolves inside the Android emulator.
    return 'http://10.0.2.2:4000';
  }
  return 'http://10.0.2.2:4000';
}
