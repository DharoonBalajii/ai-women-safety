import 'incident_update.dart';
import 'location_point.dart';
import 'threat_type.dart';

enum IncidentStatus { active, resolved, cancelled }

class EmergencyIncident {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  IncidentStatus status;
  ThreatType threatType;
  String aiSummary;
  final List<IncidentUpdate> updates;
  final List<LocationPoint> locationTrail;

  /// Whether trusted contacts have actually been reached for this incident
  /// — via the manual "notify all contacts" action or an unanswered
  /// check-in — never a stand-in for real dispatch, since this app has no
  /// backend connection to emergency services.
  bool contactsNotified;
  DateTime? contactsNotifiedAt;

  EmergencyIncident({
    required this.id,
    required this.startTime,
    this.endTime,
    this.status = IncidentStatus.active,
    this.threatType = ThreatType.unknown,
    this.aiSummary = '',
    List<IncidentUpdate>? updates,
    List<LocationPoint>? locationTrail,
    this.contactsNotified = false,
    this.contactsNotifiedAt,
  })  : updates = updates ?? [],
        locationTrail = locationTrail ?? [];

  LocationPoint? get latestLocation =>
      locationTrail.isNotEmpty ? locationTrail.last : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'status': status.name,
        'threatType': threatType.name,
        'aiSummary': aiSummary,
        'updates': updates.map((u) => u.toJson()).toList(),
        'locationTrail': locationTrail.map((l) => l.toJson()).toList(),
        'contactsNotified': contactsNotified,
        'contactsNotifiedAt': contactsNotifiedAt?.toIso8601String(),
      };

  factory EmergencyIncident.fromJson(Map<String, dynamic> json) => EmergencyIncident(
        id: json['id'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
        status: IncidentStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => IncidentStatus.resolved,
        ),
        threatType: ThreatTypeX.fromName(json['threatType'] as String?),
        aiSummary: json['aiSummary'] as String? ?? '',
        updates: (json['updates'] as List<dynamic>? ?? [])
            .map((u) => IncidentUpdate.fromJson(u as Map<String, dynamic>))
            .toList(),
        locationTrail: (json['locationTrail'] as List<dynamic>? ?? [])
            .map((l) => LocationPoint.fromJson(l as Map<String, dynamic>))
            .toList(),
        contactsNotified: json['contactsNotified'] as bool? ?? false,
        contactsNotifiedAt: json['contactsNotifiedAt'] != null
            ? DateTime.parse(json['contactsNotifiedAt'] as String)
            : null,
      );
}
