import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emergency_incident.dart';
import '../models/threat_type.dart';
import '../models/trusted_contact.dart';

/// Notifies trusted contacts about an active emergency.
///
/// There is no backend/SMS gateway yet, so this prototype uses the
/// device's own SMS composer (via the `sms:` URI scheme) prefilled with
/// the emergency context, live location and timestamp — the contact still
/// receives a real text message once the user hits send. [shareSummary]
/// is a fallback for platforms without SMS (e.g. web/desktop demo).
class AlertService {
  String buildMessage(EmergencyIncident incident) {
    final location = incident.latestLocation;
    final buffer = StringBuffer()
      ..writeln('EMERGENCY ALERT — ${incident.threatType.label}')
      ..writeln(incident.aiSummary.isNotEmpty ? incident.aiSummary : 'Please check on me now.')
      ..writeln('Time: ${incident.startTime.toLocal()}');
    if (location != null) {
      buffer.writeln('Live location: ${location.mapsUrl}');
    }
    return buffer.toString();
  }

  Future<bool> notifyContact(TrustedContact contact, EmergencyIncident incident) async {
    final message = buildMessage(incident);
    final uri = Uri(
      scheme: 'sms',
      path: contact.phone,
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }

  Future<void> shareSummary(EmergencyIncident incident) async {
    await Share.share(buildMessage(incident));
  }

  Future<bool> callContact(TrustedContact contact) async {
    final uri = Uri(scheme: 'tel', path: contact.phone);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}
