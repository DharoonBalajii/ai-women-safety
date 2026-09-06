import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

/// Reads the device's own battery level for an active incident, so a
/// guardian sees an honest "not reported" rather than a fabricated number
/// when it can't be read (unsupported platform, permission issue, etc.).
class BatteryService {
  final Battery _battery = Battery();

  Future<int?> currentLevel() async {
    if (kIsWeb) return null;
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return null;
    }
  }
}

final batteryService = BatteryService();
