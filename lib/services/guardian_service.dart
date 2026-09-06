import '../models/guardian_alert.dart';
import '../models/guardian_invite.dart';
import 'api_client.dart';

/// Thin client for this app's own backend `/guardian/*` and
/// `/incidents/alerts` routes — guardian linking and live-alert reads.
class GuardianService {
  Future<void> inviteGuardian({required String guardianPhoneNumber, String? label}) async {
    await ApiClient.post('/guardian/invite', {
      'guardianPhoneNumber': guardianPhoneNumber,
      if (label != null && label.isNotEmpty) 'label': label,
    });
  }

  Future<List<GuardianRelationshipSummary>> fetchMyRelationships() async {
    final result = await ApiClient.get('/guardian/relationships');
    return (result['relationships'] as List<dynamic>)
        .map((r) => GuardianRelationshipSummary.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<GuardianInvite>> fetchPendingInvites() async {
    final result = await ApiClient.get('/guardian/invites');
    return (result['invites'] as List<dynamic>)
        .map((i) => GuardianInvite.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<void> respondToInvite(String relationshipId, {required bool accept}) async {
    await ApiClient.post('/guardian/invites/$relationshipId/respond', {'accept': accept});
  }

  Future<List<GuardianAlert>> fetchAlerts() async {
    final result = await ApiClient.get('/incidents/alerts');
    return (result['alerts'] as List<dynamic>)
        .map((a) => GuardianAlert.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<void> acknowledgeAlert(String incidentId) async {
    await ApiClient.patch('/incidents/$incidentId/response', {'status': 'ACKNOWLEDGED'});
  }

  Future<void> markResponding(String incidentId) async {
    await ApiClient.patch('/incidents/$incidentId/response', {'status': 'RESPONDING'});
  }

  Future<void> resolveAlert(String incidentId) async {
    await ApiClient.patch('/incidents/$incidentId/response', {'status': 'RESOLVED'});
  }
}

final guardianService = GuardianService();
