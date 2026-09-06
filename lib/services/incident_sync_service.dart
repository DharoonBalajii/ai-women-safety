import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Pushes this device's own incident to the backend so a linked guardian's
/// dashboard has something real to show — entirely best-effort. The local
/// [IncidentStore] remains the source of truth for the reporting person's
/// own experience; if the backend is unreachable, their SOS flow keeps
/// working exactly as before, just without a guardian able to see it yet.
class IncidentSyncService {
  Future<String?> reportIncident({
    required String threatType,
    String? aiSummary,
    double? latitude,
    double? longitude,
    int? batteryPercent,
  }) async {
    try {
      final result = await ApiClient.post('/incidents', {
        'threatType': threatType,
        if (aiSummary != null && aiSummary.isNotEmpty) 'aiSummary': aiSummary,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'batteryPercent': ?batteryPercent,
      });
      return result['incidentId'] as String?;
    } catch (e) {
      debugPrint('IncidentSyncService.reportIncident failed (non-fatal): $e');
      return null;
    }
  }

  Future<void> updateLocation(
    String incidentId, {
    required double latitude,
    required double longitude,
    int? batteryPercent,
  }) async {
    try {
      await ApiClient.patch('/incidents/$incidentId', {
        'latitude': latitude,
        'longitude': longitude,
        'batteryPercent': ?batteryPercent,
      });
    } catch (e) {
      debugPrint('IncidentSyncService.updateLocation failed (non-fatal): $e');
    }
  }

  Future<void> updateSummary(
    String incidentId, {
    required String threatType,
    required String aiSummary,
  }) async {
    try {
      await ApiClient.patch('/incidents/$incidentId', {
        'threatType': threatType,
        if (aiSummary.isNotEmpty) 'aiSummary': aiSummary,
      });
    } catch (e) {
      debugPrint('IncidentSyncService.updateSummary failed (non-fatal): $e');
    }
  }

  Future<void> updateStatus(String incidentId, {required bool resolved}) async {
    try {
      await ApiClient.patch('/incidents/$incidentId/status', {
        'status': resolved ? 'RESOLVED' : 'CANCELLED',
      });
    } catch (e) {
      debugPrint('IncidentSyncService.updateStatus failed (non-fatal): $e');
    }
  }
}

final incidentSyncService = IncidentSyncService();
