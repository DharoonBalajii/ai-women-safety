import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/emergency_incident.dart';

/// On-device persistence for the incident history list. A hackathon-scope
/// stand-in for the real "Emergency Backend" incident-records service.
class IncidentStore {
  static const _prefKey = 'incident_history';

  Future<List<EmergencyIncident>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => EmergencyIncident.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Future<void> upsert(EmergencyIncident incident) async {
    final incidents = await load();
    final index = incidents.indexWhere((i) => i.id == incident.id);
    if (index >= 0) {
      incidents[index] = incident;
    } else {
      incidents.add(incident);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(incidents.map((i) => i.toJson()).toList()),
    );
  }
}
