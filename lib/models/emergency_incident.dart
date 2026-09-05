import 'incident_update.dart';
import 'location_point.dart';
import 'threat_type.dart';

enum IncidentStatus { active, resolved, cancelled }

/// Simulated responder-network pipeline stage, shown on the incident
/// timeline as a prototype of the control-room dispatch flow.
enum ResponderStage {
  detecting,
  patrolIdentified,
  controlRoomNotified,
  responderAccepted,
  dispatched,
  respondedArrived,
}

extension ResponderStageX on ResponderStage {
  String get label {
    switch (this) {
      case ResponderStage.detecting:
        return 'Analyzing threat & severity';
      case ResponderStage.patrolIdentified:
        return 'Nearest patrol identified';
      case ResponderStage.controlRoomNotified:
        return 'Control room notified';
      case ResponderStage.responderAccepted:
        return 'Responder accepted incident';
      case ResponderStage.dispatched:
        return 'Patrol unit dispatched';
      case ResponderStage.respondedArrived:
        return 'Responder arrived at location';
    }
  }
}

class EmergencyIncident {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  IncidentStatus status;
  ThreatType threatType;
  String aiSummary;
  final List<IncidentUpdate> updates;
  final List<LocationPoint> locationTrail;
  ResponderStage responderStage;

  EmergencyIncident({
    required this.id,
    required this.startTime,
    this.endTime,
    this.status = IncidentStatus.active,
    this.threatType = ThreatType.unknown,
    this.aiSummary = '',
    List<IncidentUpdate>? updates,
    List<LocationPoint>? locationTrail,
    this.responderStage = ResponderStage.detecting,
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
        'responderStage': responderStage.name,
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
        responderStage: ResponderStage.values.firstWhere(
          (s) => s.name == json['responderStage'],
          orElse: () => ResponderStage.detecting,
        ),
      );
}
