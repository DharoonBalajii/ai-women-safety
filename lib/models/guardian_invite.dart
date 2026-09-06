/// A pending [GuardianRelationship] as seen from the invited guardian's
/// side — from `GET /guardian/invites`.
class GuardianInvite {
  final String relationshipId;
  final String? label;
  final String protectedPhoneNumber;
  final DateTime createdAt;

  const GuardianInvite({
    required this.relationshipId,
    required this.label,
    required this.protectedPhoneNumber,
    required this.createdAt,
  });

  factory GuardianInvite.fromJson(Map<String, dynamic> json) => GuardianInvite(
        relationshipId: json['relationshipId'] as String,
        label: json['label'] as String?,
        protectedPhoneNumber: json['protectedPhoneNumber'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// A relationship as seen from the protected user's own side — from
/// `GET /guardian/relationships`. Distinct from [GuardianInvite] (which is
/// always PENDING and always the guardian's view) since this can be any
/// status and is read-only history for the person who sent the invite.
class GuardianRelationshipSummary {
  final String relationshipId;
  final String status;
  final String? label;
  final String guardianPhoneNumber;
  final DateTime createdAt;

  const GuardianRelationshipSummary({
    required this.relationshipId,
    required this.status,
    required this.label,
    required this.guardianPhoneNumber,
    required this.createdAt,
  });

  factory GuardianRelationshipSummary.fromJson(Map<String, dynamic> json) => GuardianRelationshipSummary(
        relationshipId: json['relationshipId'] as String,
        status: json['status'] as String,
        label: json['label'] as String?,
        guardianPhoneNumber: json['guardianPhoneNumber'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
