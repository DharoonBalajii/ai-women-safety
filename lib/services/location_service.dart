import 'package:geolocator/geolocator.dart';

import '../models/location_point.dart';

class LocationService {
  Future<bool> ensurePermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Cheap status check for display purposes — checks the OS service and
  /// existing permission grant without prompting, unlike [ensurePermission].
  Future<bool> isActive() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  Future<LocationPoint?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final hasPermission = await ensurePermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Never throws: permission/service errors are swallowed so a denied or
  /// unsupported location API (e.g. a sandboxed browser) can't crash an
  /// active emergency session — it just means no live trail is recorded.
  Stream<LocationPoint> watchLocation() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );
    return Geolocator.getPositionStream(locationSettings: settings)
        .map(
          (position) => LocationPoint(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            timestamp: DateTime.now(),
          ),
        )
        .handleError((_) {});
  }
}
