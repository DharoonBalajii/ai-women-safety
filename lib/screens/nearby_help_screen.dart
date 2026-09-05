import 'package:flutter/material.dart';

import '../models/safe_place.dart';
import '../services/location_service.dart';
import '../services/safe_zone_service.dart';
import '../theme/home_theme.dart';

/// Standalone "what's near me right now" lookup — no incident required.
/// Reuses the same safe-zone lookup the live emergency screen uses, so
/// someone can check this before anything goes wrong.
class NearbyHelpScreen extends StatefulWidget {
  const NearbyHelpScreen({super.key});

  @override
  State<NearbyHelpScreen> createState() => _NearbyHelpScreenState();
}

class _NearbyHelpScreenState extends State<NearbyHelpScreen> {
  final _locationService = LocationService();
  final _safeZoneService = SafeZoneService();

  bool _loading = true;
  bool _lookupFailed = false;
  List<SafePlace> _places = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final location = await _locationService.getCurrentLocation();
    if (location == null) {
      setState(() {
        _loading = false;
        _lookupFailed = true;
      });
      return;
    }
    final places = await _safeZoneService.findNearbySafePlaces(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    setState(() {
      _places = places;
      _loading = false;
      _lookupFailed = false;
    });
  }

  IconData _iconFor(SafePlaceType type) {
    switch (type) {
      case SafePlaceType.police:
        return Icons.local_police_outlined;
      case SafePlaceType.hospital:
        return Icons.local_hospital_outlined;
      case SafePlaceType.publicPlace:
        return Icons.storefront_outlined;
    }
  }

  Color _colorFor(SafePlaceType type) {
    switch (type) {
      case SafePlaceType.police:
        return HomeColors.brandIndigo;
      case SafePlaceType.hospital:
        return HomeColors.sosCrimson;
      case SafePlaceType.publicPlace:
        return HomeColors.brandTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.appBg,
      appBar: AppBar(
        backgroundColor: HomeColors.appBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: HomeColors.textPrimary),
        title: Text('Nearby Help', style: HomeText.title()),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: HomeColors.brandIndigo))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_lookupFailed)
                    _EmptyNotice(
                      icon: Icons.location_off_outlined,
                      message:
                          "Couldn't get a location fix. Enable location access and pull down to try again.",
                    )
                  else if (_places.isEmpty)
                    const _EmptyNotice(
                      icon: Icons.search_off_rounded,
                      message: 'No safe places found nearby yet.',
                    )
                  else
                    ..._places.map(
                      (place) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: HomeColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _colorFor(place.type).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_iconFor(place.type), color: _colorFor(place.type), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(place.name, style: HomeText.cardTitle()),
                            ),
                            Text(place.distanceLabel, style: HomeText.caption()),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyNotice({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 40, color: HomeColors.textSecondary),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: HomeText.body()),
        ],
      ),
    );
  }
}
