import 'package:flutter/material.dart';

enum ThreatType {
  following,
  threatened,
  medical,
  accident,
  harassment,
  unknown,
}

extension ThreatTypeX on ThreatType {
  String get label {
    switch (this) {
      case ThreatType.following:
        return 'Being Followed';
      case ThreatType.threatened:
        return 'Threatened';
      case ThreatType.medical:
        return 'Medical Emergency';
      case ThreatType.accident:
        return 'Accident';
      case ThreatType.harassment:
        return 'Harassment';
      case ThreatType.unknown:
        return 'Emergency';
    }
  }

  IconData get icon {
    switch (this) {
      case ThreatType.following:
        return Icons.directions_walk;
      case ThreatType.threatened:
        return Icons.warning_amber_rounded;
      case ThreatType.medical:
        return Icons.medical_services;
      case ThreatType.accident:
        return Icons.car_crash;
      case ThreatType.harassment:
        return Icons.report;
      case ThreatType.unknown:
        return Icons.sos;
    }
  }

  static ThreatType fromName(String? name) {
    return ThreatType.values.firstWhere(
      (t) => t.name == name,
      orElse: () => ThreatType.unknown,
    );
  }
}
