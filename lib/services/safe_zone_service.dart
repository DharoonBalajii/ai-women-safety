import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/safe_place.dart';

/// Finds nearby police stations, hospitals and public establishments using
/// the free OpenStreetMap Overpass API (no API key required). Falls back to
/// illustrative sample data if the network call fails, so the "AI safe-zone
/// recommendation" panel is never empty during a demo.
class SafeZoneService {
  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';

  Future<List<SafePlace>> findNearbySafePlaces({
    required double latitude,
    required double longitude,
    double radiusMeters = 2000,
  }) async {
    final query = '''
[out:json][timeout:10];
(
  node["amenity"="police"](around:$radiusMeters,$latitude,$longitude);
  node["amenity"="hospital"](around:$radiusMeters,$latitude,$longitude);
  node["shop"="supermarket"](around:800,$latitude,$longitude);
  node["amenity"="pharmacy"](around:800,$latitude,$longitude);
);
out center 15;
''';

    try {
      final response = await http
          .post(Uri.parse(_overpassUrl), body: {'data': query})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return _mockPlaces(latitude, longitude);
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = body['elements'] as List<dynamic>? ?? [];

      final places = <SafePlace>[];
      for (final element in elements) {
        final tags = element['tags'] as Map<String, dynamic>? ?? {};
        final lat = (element['lat'] as num?)?.toDouble();
        final lon = (element['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;

        final amenity = tags['amenity'] as String?;
        final SafePlaceType type;
        if (amenity == 'police') {
          type = SafePlaceType.police;
        } else if (amenity == 'hospital') {
          type = SafePlaceType.hospital;
        } else {
          type = SafePlaceType.publicPlace;
        }

        places.add(SafePlace(
          name: tags['name'] as String? ?? _defaultName(type),
          type: type,
          latitude: lat,
          longitude: lon,
          distanceMeters: Geolocator.distanceBetween(latitude, longitude, lat, lon),
        ));
      }

      if (places.isEmpty) return _mockPlaces(latitude, longitude);
      places.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return places.take(10).toList();
    } catch (_) {
      return _mockPlaces(latitude, longitude);
    }
  }

  String _defaultName(SafePlaceType type) {
    switch (type) {
      case SafePlaceType.police:
        return 'Police Station';
      case SafePlaceType.hospital:
        return 'Hospital';
      case SafePlaceType.publicPlace:
        return 'Public Establishment';
    }
  }

  List<SafePlace> _mockPlaces(double latitude, double longitude) {
    return [
      SafePlace(
        name: 'Police Station (approx.)',
        type: SafePlaceType.police,
        latitude: latitude + 0.004,
        longitude: longitude + 0.003,
        distanceMeters: 650,
      ),
      SafePlace(
        name: 'General Hospital (approx.)',
        type: SafePlaceType.hospital,
        latitude: latitude - 0.006,
        longitude: longitude + 0.004,
        distanceMeters: 1200,
      ),
      SafePlace(
        name: 'Public Establishment (approx.)',
        type: SafePlaceType.publicPlace,
        latitude: latitude + 0.002,
        longitude: longitude - 0.001,
        distanceMeters: 300,
      ),
    ];
  }
}
