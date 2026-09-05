import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/safe_place.dart';

/// Finds nearby police stations, hospitals and public establishments using
/// the free OpenStreetMap Overpass API (no API key required). Returns an
/// empty list if the lookup fails or turns up nothing real nearby — this
/// feeds a live emergency screen, so it must never invent a "Police Station
/// (approx.)" at a fabricated distance. Callers show that honestly as
/// "couldn't find safe places," not as a result.
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
        return [];
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

      places.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return places.take(10).toList();
    } catch (_) {
      return [];
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
}
