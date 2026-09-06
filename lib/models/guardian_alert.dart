import '../models/threat_type.dart';

enum AlertResponseStatus { active, acknowledged, responding }

extension AlertResponseStatusX on AlertResponseStatus {
  String get label {
    switch (this) {
      case AlertResponseStatus.active:
        return 'NEW';
      case AlertResponseStatus.acknowledged:
        return 'ACKNOWLEDGED';
      case AlertResponseStatus.responding:
        return 'RESPONDING';
    }
  }

  static AlertResponseStatus fromApi(String status) {
    switch (status) {
      case 'ACKNOWLEDGED':
        return AlertResponseStatus.acknowledged;
      case 'RESPONDING':
        return AlertResponseStatus.responding;
      default:
        return AlertResponseStatus.active;
    }
  }
}

/// A live SOS alert as seen from a Guardian's dashboard — parsed straight
/// from `GET /guardian/alerts`. [threatType] is nullable (via
/// [ThreatTypeX.fromNameOrNull]) because the backend stores whatever
/// classification string the reporting device sent, which may not (yet)
/// match a value this build of the app recognizes.
class GuardianAlert {
  final String incidentId;
  final AlertResponseStatus status;
  final ThreatType? threatType;
  final String? aiSummary;
  final double? latitude;
  final double? longitude;
  final DateTime? locationAt;
  final int? batteryPercent;
  final String protectedPhoneNumber;
  final String? protectedDisplayName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GuardianAlert({
    required this.incidentId,
    required this.status,
    required this.threatType,
    required this.aiSummary,
    required this.latitude,
    required this.longitude,
    required this.locationAt,
    required this.batteryPercent,
    required this.protectedPhoneNumber,
    required this.protectedDisplayName,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory GuardianAlert.fromJson(Map<String, dynamic> json) => GuardianAlert(
        incidentId: json['incidentId'] as String,
        status: AlertResponseStatusX.fromApi(json['status'] as String),
        threatType: ThreatTypeX.fromNameOrNull(json['threatType'] as String?),
        aiSummary: json['aiSummary'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        locationAt: json['locationAt'] != null ? DateTime.parse(json['locationAt'] as String) : null,
        batteryPercent: json['batteryPercent'] as int?,
        protectedPhoneNumber: json['protectedPhoneNumber'] as String,
        protectedDisplayName: json['protectedDisplayName'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
